#!/usr/bin/env python3
"""Prueft, ob jedes Image im Cluster arm64 kann.

Liest Image-Referenzen von stdin (eine je Zeile) und fragt fuer jede die
Registry nach ihrer Manifest-Liste. Aufgerufen wird das aus
.github/scripts/validate.sh, das die Images aus den gerenderten Manifesten UND
den gerenderten Helm-Charts zieht.

WARUM ES DAS GIBT: raspi5 ist arm64, die beiden anderen Nodes sind amd64, und
alle drei tragen das worker-Label. Ein Image ohne arm64 scheitert deshalb NICHT
zuverlaessig, sondern nur dann, wenn der Scheduler den Pod zufaellig auf raspi5
legt. Mal gruen, mal rot, und im Fehlerbild ("exec format error" oder ein
CrashLoop ohne Ausgabe) steht die Ursache nicht drin. Ein Renovate-Bump, der
das ausloest, wuerde ausserdem automatisch gemergt.

Dieser Test macht daraus einen roten PR, bevor es das Cluster erreicht.

Die Allowlist ist leer, alle Images im Cluster koennen arm64. Sie ist trotzdem
da, weil der Ausweg fuer den Ernstfall dokumentiert sein muss: ein
amd64-only-Image ist erlaubt, wenn der zugehoerige Workload einen
nodeSelector auf kubernetes.io/arch: amd64 traegt. So haelt es
manifests/kube-prometheus-stack/values.yaml mit Prometheus, dort allerdings aus
einem anderen Grund (Speicherhunger, nicht fehlendes Image).
"""
import json
import os
import pathlib
import sys
import urllib.error
import urllib.request

ALLOWLIST = pathlib.Path(__file__).parent / "image-arch-allowlist.txt"

ACCEPT = ",".join([
    "application/vnd.oci.image.index.v1+json",
    "application/vnd.docker.distribution.manifest.list.v2+json",
    "application/vnd.oci.image.manifest.v1+json",
    "application/vnd.docker.distribution.manifest.v2+json",
])


def split_ref(image):
    """Image-Referenz in (registry, repo, tag-oder-digest) zerlegen."""
    ref, tag = image, "latest"
    if "@" in ref:
        ref, tag = ref.split("@", 1)
    elif ":" in ref.rsplit("/", 1)[-1]:
        ref, tag = ref.rsplit(":", 1)
    head = ref.split("/")[0]
    # Ein Punkt oder Doppelpunkt im ersten Segment heisst Registry-Host,
    # sonst ist es Docker Hub. "localhost" ist der dokumentierte Sonderfall.
    if "." in head or ":" in head or head == "localhost":
        registry, repo = head, ref.split("/", 1)[1]
    else:
        registry, repo = "docker.io", ref
    if registry == "docker.io" and "/" not in repo:
        repo = "library/" + repo          # nginx -> library/nginx
    return registry, repo, tag


def get_token(registry, repo):
    """Anonymes Pull-Token holen. Ohne das antworten die meisten Registries 401."""
    if registry == "docker.io":
        url = ("https://auth.docker.io/token?service=registry.docker.io"
               f"&scope=repository:{repo}:pull")
    elif registry == "ghcr.io":
        url = f"https://ghcr.io/token?scope=repository:{repo}:pull&service=ghcr.io"
    elif registry.endswith("quay.io"):
        return None                        # quay laesst anonym direkt durch
    else:
        url = f"https://{registry}/token?scope=repository:{repo}:pull&service={registry}"
    try:
        with urllib.request.urlopen(url, timeout=20) as resp:
            body = json.load(resp)
        return body.get("token") or body.get("access_token")
    except Exception:
        return None


def architectures(image):
    """Menge der Plattformen, oder None wenn die Registry nicht antwortet."""
    registry, repo, tag = split_ref(image)
    host = "registry-1.docker.io" if registry == "docker.io" else registry
    req = urllib.request.Request(f"https://{host}/v2/{repo}/manifests/{tag}")
    req.add_header("Accept", ACCEPT)
    token = get_token(registry, repo)
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, timeout=25) as resp:
            doc = json.load(resp)
    except Exception as exc:
        return None, f"{type(exc).__name__}"

    if "manifests" not in doc:
        # Einzelmanifest ohne Liste. Die Architektur steht dann nicht drin,
        # ohne den Config-Blob nachzuladen. Als unbekannt behandeln statt
        # zu raten.
        return set(), None

    found = set()
    for entry in doc["manifests"]:
        platform = entry.get("platform") or {}
        arch = platform.get("architecture")
        # attestation-Manifeste (buildkit) tragen architecture: unknown und
        # wuerden die Auswertung sonst verwaessern.
        if not arch or arch == "unknown":
            continue
        found.add(f"{platform.get('os', '?')}/{arch}")
    return found, None


def load_allowlist():
    if not ALLOWLIST.exists():
        return set()
    entries = set()
    for line in ALLOWLIST.read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            entries.add(line)
    return entries


def main():
    allowed = load_allowlist()
    images = sorted({line.strip() for line in sys.stdin if line.strip()})
    if not images:
        print("keine Images gefunden", file=sys.stderr)
        return 2

    red, green, yellow, reset = "\033[31m", "\033[32m", "\033[33m", "\033[0m"
    missing, unknown, waived, ok = [], [], [], 0

    for image in images:
        arches, err = architectures(image)
        name = image.split("@")[0]
        if err:
            unknown.append((image, err))
            print(f"{yellow}?{reset} {name}  (Registry nicht erreichbar: {err})")
        elif any(a.endswith("/arm64") for a in arches):
            ok += 1
            print(f"{green}✓{reset} {name}")
        elif name in allowed or image in allowed:
            waived.append(image)
            print(f"{yellow}~{reset} {name}  (amd64-only, bewusst per Allowlist)")
        else:
            missing.append((image, sorted(arches)))
            print(f"{red}✗{reset} {name}  KEIN arm64: {sorted(arches) or 'unbekannt'}")

    print()
    if unknown:
        # Nicht hart failen: eine Registry, die gerade zickt, soll keinen
        # Renovate-PR blockieren. Sichtbar bleibt es trotzdem.
        print(f"{yellow}{len(unknown)} Image(s) nicht abfragbar, uebersprungen{reset}")
    if missing:
        print(f"{red}{len(missing)} Image(s) ohne arm64{reset}")
        print()
        print("raspi5 ist arm64 und traegt wie alle Nodes das worker-Label. Ein")
        print("solches Image scheitert nur dann, wenn der Scheduler den Pod dort")
        print("hinlegt, also unvorhersehbar. Zwei Auswege:")
        print()
        print("  1. Multi-Arch-Alternative oder aeltere Version verwenden.")
        print("  2. Den Workload mit nodeSelector kubernetes.io/arch: amd64")
        print("     festnageln UND das Image in")
        print(f"     {ALLOWLIST.relative_to(pathlib.Path.cwd())} eintragen,")
        print("     mit Begruendung.")
        return 1

    summary = f"{ok} von {len(images)} Images koennen arm64"
    if waived:
        summary += f", {len(waived)} per Allowlist ausgenommen"
    if unknown:
        summary += f", {len(unknown)} nicht geprueft"
    print(f"{green}{summary}{reset}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
