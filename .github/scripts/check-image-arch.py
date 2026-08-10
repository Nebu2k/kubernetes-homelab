#!/usr/bin/env python3
"""Prueft, ob jedes Image im Cluster arm64 kann oder auf eine Arch festgenagelt ist.

Liest gerendertes YAML (Pfad als Argument, sonst stdin), zieht daraus jede
Image-Referenz samt dem nodeSelector, der darueber steht, und fragt fuer jedes
Image die Registry nach seiner Manifest-Liste. Aufgerufen wird das aus
.github/scripts/validate.sh, das die Kustomize-Manifeste UND die Helm-Charts
rendert.

WARUM ES DAS GIBT: raspi5 ist arm64, die beiden anderen Nodes sind amd64, und
alle drei tragen das worker-Label. Ein Image ohne arm64 scheitert deshalb NICHT
zuverlaessig, sondern nur dann, wenn der Scheduler den Pod zufaellig auf raspi5
legt. Mal gruen, mal rot, und im Fehlerbild ("exec format error" oder ein
CrashLoop ohne Ausgabe) steht die Ursache nicht drin. Ein Renovate-Bump, der
das ausloest, wuerde ausserdem automatisch gemergt.

Dieser Test macht daraus einen roten PR, bevor es das Cluster erreicht.

Ein Image ohne arm64 ist genau dann in Ordnung, wenn JEDE Stelle, an der es
verwendet wird, einen nodeSelector auf kubernetes.io/arch traegt: dann kann der
Scheduler es gar nicht erst auf raspi5 legen. Das prueft das Skript selbst am
gerenderten YAML, eine Allowlist daneben gibt es deshalb nicht. Erkannt wird
ausschliesslich nodeSelector, keine nodeAffinity.

So haelt es manifests/kube-prometheus-stack/values.yaml mit Prometheus, dort
allerdings aus einem anderen Grund (Speicherhunger, nicht fehlendes Image).
"""
import json
import sys
import urllib.error
import urllib.request

import yaml

ARCH_LABEL = "kubernetes.io/arch"

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
    # A dot or colon in the first segment means a registry host, otherwise it
    # is Docker Hub. "localhost" is the documented special case.
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
        # Single manifest without a list. The architecture is not in there
        # without fetching the config blob, so treat it as unknown rather than
        # guessing.
        return set(), None

    found = set()
    for entry in doc["manifests"]:
        platform = entry.get("platform") or {}
        arch = platform.get("architecture")
        # buildkit attestation manifests carry architecture: unknown and would
        # otherwise dilute the result.
        if not arch or arch == "unknown":
            continue
        found.add(f"{platform.get('os', '?')}/{arch}")
    return found, None


def collect(node, arch, found):
    """Jede image-Referenz mit dem arch-Pin sammeln, der ueber ihr steht.

    Der nodeSelector eines Pods steht im selben Mapping wie seine Container,
    bei den Operator-CRs (Prometheus, Alertmanager) sogar neben dem image
    selbst. Ein Pin gilt deshalb fuer das Mapping, in dem er steht, und fuer
    alles darunter. Images ohne Pin landen mit None in der Menge.
    """
    if isinstance(node, dict):
        selector = node.get("nodeSelector")
        # Longhorn volumes have a field of the same name holding a string.
        if isinstance(selector, dict) and selector.get(ARCH_LABEL):
            arch = str(selector[ARCH_LABEL])
        image = node.get("image")
        if isinstance(image, str) and image.strip():
            found.setdefault(image.strip(), set()).add(arch)
        for value in node.values():
            collect(value, arch, found)
    elif isinstance(node, list):
        for item in node:
            collect(item, arch, found)


def main():
    if len(sys.argv) > 1:
        with open(sys.argv[1]) as handle:
            text = handle.read()
    else:
        text = sys.stdin.read()

    red, green, yellow, reset = "\033[31m", "\033[32m", "\033[33m", "\033[0m"

    images = {}
    try:
        for doc in yaml.safe_load_all(text):
            collect(doc, None, images)
    except yaml.YAMLError as exc:
        print(f"{red}gerendertes YAML nicht parsebar: {exc}{reset}", file=sys.stderr)
        return 2

    if not images:
        print("keine Images gefunden", file=sys.stderr)
        return 2

    missing, unknown, pinned, ok = [], [], [], 0

    for image in sorted(images):
        pins = images[image]
        arches, err = architectures(image)
        name = image.split("@")[0]
        if err:
            unknown.append((image, err))
            print(f"{yellow}?{reset} {name}  (Registry nicht erreichbar: {err})")
        elif any(a.endswith("/arm64") for a in arches):
            ok += 1
            print(f"{green}✓{reset} {name}")
        elif None not in pins and "arm64" not in pins:
            pinned.append(image)
            fixed = ", ".join(sorted(pins))
            print(f"{yellow}~{reset} {name}  (kein arm64, per nodeSelector auf {fixed})")
        else:
            missing.append((image, sorted(arches)))
            print(f"{red}✗{reset} {name}  KEIN arm64: {sorted(arches) or 'unbekannt'}")

    print()
    if unknown:
        # Do not fail hard: a registry having a bad moment should not block a
        # Renovate PR. It stays visible regardless.
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
        print("     festnageln, an JEDER Stelle, an der das Image vorkommt.")
        print("     Dieser Test liest den Pin aus den gerenderten Manifesten,")
        print("     eine Allowlist gibt es nicht.")
        return 1

    summary = f"{ok} von {len(images)} Images koennen arm64"
    if pinned:
        summary += f", {len(pinned)} per nodeSelector festgenagelt"
    if unknown:
        summary += f", {len(unknown)} nicht geprueft"
    print(f"{green}{summary}{reset}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
