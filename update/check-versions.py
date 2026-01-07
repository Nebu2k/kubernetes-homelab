#!/usr/bin/env python3
"""
Simple version checker for Kubernetes homelab components.
Checks Helm charts and container images for updates.
"""

import argparse
import json
import subprocess
from pathlib import Path
from typing import Optional

import requests
import yaml
from packaging import version

REPO_ROOT = Path(__file__).parent.parent
APPS_DIR = REPO_ROOT / "apps"
MANIFESTS_DIR = REPO_ROOT / "manifests"


def run_command(cmd: list) -> Optional[str]:
    """Run shell command and return output."""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True, timeout=30)
        return result.stdout
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, FileNotFoundError):
        return None


def get_latest_helm_version(chart_name: str, repo_url: Optional[str] = None) -> Optional[str]:
    """Get latest Helm chart version from specific repository."""
    output = run_command(["helm", "search", "repo", chart_name, "-o", "json"])
    if not output:
        return None
    
    try:
        data = json.loads(output)
        if not data:
            return None
        
        # If repo URL is provided, filter results to match that repo
        if repo_url:
            # Normalize repo URL (remove trailing slash)
            repo_url = repo_url.rstrip("/")
            
            # Find matching chart from the specific repo
            for chart in data:
                chart_repo = chart.get("name", "").split("/")[0] if "/" in chart.get("name", "") else ""
                
                # Get the repo URL for this chart
                repo_list_output = run_command(["helm", "repo", "list", "-o", "json"])
                if repo_list_output:
                    try:
                        repos = json.loads(repo_list_output)
                        for repo in repos:
                            if repo["name"] == chart_repo and repo["url"].rstrip("/") == repo_url:
                                return chart["version"]
                    except (json.JSONDecodeError, KeyError):
                        pass
        
        # Fallback to first result if no repo match found
        return data[0]["version"]
    except (json.JSONDecodeError, KeyError, IndexError):
        return None


def get_latest_docker_tag(image: str) -> Optional[str]:
    """Get latest Docker image tag from Docker Hub, GHCR, or Quay."""
    if image.startswith("ghcr.io/"):
        return _get_ghcr_tag(image)
    elif image.startswith("quay.io/"):
        return _get_quay_tag(image)
    else:
        return _get_dockerhub_tag(image)


def _get_dockerhub_tag(image: str) -> Optional[str]:
    """Get latest tag from Docker Hub."""
    try:
        parts = image.split("/")
        namespace = "library" if len(parts) == 1 else parts[0]
        repo = parts[-1]
        
        url = f"https://hub.docker.com/v2/repositories/{namespace}/{repo}/tags"
        response = requests.get(url, params={"page_size": 50}, timeout=10)
        response.raise_for_status()
        
        tags = [t["name"] for t in response.json().get("results", [])]
        return _filter_stable_tag(tags)
    except Exception:
        return None


def _get_ghcr_tag(image: str) -> Optional[str]:
    """Get latest tag from GitHub Container Registry."""
    try:
        parts = image.replace("ghcr.io/", "").split("/")
        if len(parts) < 2:
            return None
        
        owner, repo = parts[0], parts[1]
        url = f"https://api.github.com/repos/{owner}/{repo}/releases"
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        tags = []
        for release in response.json():
            if not release.get("draft") and not release.get("prerelease"):
                tag = release.get("tag_name", "")
                if tag:
                    tags.append(tag)
        
        return _filter_stable_tag(tags)
    except Exception:
        return None


def _get_quay_tag(image: str) -> Optional[str]:
    """Get latest tag from Quay.io."""
    try:
        parts = image.replace("quay.io/", "").split("/")
        if len(parts) < 2:
            return None
        
        namespace, repo = parts[0], parts[1]
        url = f"https://quay.io/api/v1/repository/{namespace}/{repo}/tag/"
        response = requests.get(url, params={"limit": 50}, timeout=10)
        response.raise_for_status()
        
        tags = [t["name"] for t in response.json().get("tags", [])]
        return _filter_stable_tag(tags)
    except Exception:
        return None


def _normalize_version(ver: str) -> str:
    """Strip common version suffixes like -alpine, -slim, etc."""
    suffixes = [
        "-alpine", "-slim", "-debian", "-ubuntu", "-perl", "-python", "-node", "-ruby",
        "-arm64", "-amd64", "-armv7", "-arm32v6",
        "-distroless", "-bullseye", "-buster",
        "-uclibc", "-openssl", "-musl", "-glibc",
    ]
    ver_lower = ver.lower()
    for suffix in suffixes:
        if ver_lower.endswith(suffix.lower()):
            return ver[:len(ver) - len(suffix)]
    return ver


def _filter_stable_tag(tags: list) -> Optional[str]:
    """Filter and return latest stable tag."""
    # Debian/distro release codenames and other tags to exclude
    exclude_patterns = [
        "trixie", "bookworm", "bullseye", "buster", "stretch", "jessie",  # Debian
        "jammy", "focal", "bionic", "xenial",  # Ubuntu
        "alpine", "slim", "debian", "ubuntu",  # Base images
        "perl", "python", "node", "ruby",  # Language base images
        "edge", "base", "latest", "stable", "master",  # Generic tags
        "builder", "build", "nightly", "next",  # Build tags
        "beta", "rc", "alpha", "dev", "test", "pr-",  # Pre-release and test tags
        "rootless", "distroless",  # Variant tags
    ]
    
    stable = []
    for tag in tags:
        tag_lower = tag.lower()
        
        # Skip empty tags
        if not tag:
            continue
        
        # Skip if any exclude pattern matches
        if any(pattern in tag_lower for pattern in exclude_patterns):
            continue
        
        # Skip tags with no version-like characters
        if not any(c.isdigit() for c in tag):
            continue
        
        stable.append(tag)
    
    if not stable:
        return None
    
    try:
        sorted_tags = sorted(stable, key=lambda t: version.parse(t.lstrip("v")), reverse=True)
        return sorted_tags[0]
    except version.InvalidVersion:
        return stable[0]


def check_helm_apps():
    """Check Helm-based applications."""
    print("🎯 Helm Charts\n")
    print(f"{'Component':<25} {'Current':<15} {'Latest':<15} {'Status':<10}")
    print("-" * 70)
    
    updates = []
    
    for app_file in sorted(APPS_DIR.glob("*.yaml")):
        if app_file.name == "kustomization.yaml":
            continue
        
        with open(app_file) as f:
            app = yaml.safe_load(f)
        
        if not app or app.get("kind") != "Application":
            continue
        
        # Get source (single or multi-source)
        spec = app["spec"]
        source = spec.get("source")
        if not source and "sources" in spec:
            for src in spec["sources"]:
                if "chart" in src:
                    source = src
                    break
        
        if not source or "chart" not in source:
            continue
        
        name = app["metadata"]["name"]
        chart = source["chart"]
        current = source.get("targetRevision", "unknown")
        repo_url = source.get("repoURL")
        
        # Get latest version
        latest = get_latest_helm_version(chart, repo_url)
        
        if latest:
            try:
                normalized_current = _normalize_version(current.lstrip("v"))
                normalized_latest = _normalize_version(latest.lstrip("v"))
                is_outdated = version.parse(normalized_latest) > version.parse(normalized_current)
            except version.InvalidVersion:
                is_outdated = current != latest
            
            status = "⚠️ Update" if is_outdated else "✅ OK"
            
            if is_outdated:
                updates.append(name)
        else:
            latest = "N/A"
            status = "❌ Error"
        
        print(f"{name:<25} {current:<15} {latest:<15} {status:<10}")
    
    return updates


def check_kustomize_apps():
    """Check Kustomize-based applications."""
    print("\n\n📦 Kustomize Apps\n")
    print(f"{'Component':<25} {'Image':<50} {'Current':<15} {'Latest':<15} {'Status':<10}")
    print("-" * 125)
    
    updates = []
    
    for app_file in sorted(APPS_DIR.glob("*.yaml")):
        if app_file.name == "kustomization.yaml":
            continue
        
        with open(app_file) as f:
            app = yaml.safe_load(f)
        
        if not app or app.get("kind") != "Application":
            continue
        
        spec = app["spec"]
        
        # Handle both single source and multi-source
        source = spec.get("source")
        if not source and "sources" in spec:
            # Multi-source: find the Kustomize source (has path, no chart)
            for src in spec["sources"]:
                if "path" in src and "chart" not in src:
                    source = src
                    break
        
        # Skip if Helm app or no path
        if not source or "path" not in source or "chart" in source:
            continue
        
        name = app["metadata"]["name"]
        path = REPO_ROOT / source["path"]
        
        if not path.exists():
            continue
        
        # Find container images
        for yaml_file in path.glob("*.yaml"):
            if yaml_file.name == "kustomization.yaml":
                continue
            
            with open(yaml_file) as f:
                for doc in yaml.safe_load_all(f):
                    if not doc or doc.get("kind") not in ["Deployment", "StatefulSet"]:
                        continue
                    
                    pod_spec = doc.get("spec", {}).get("template", {}).get("spec", {})
                    
                    # Check both regular containers and init containers
                    all_containers = []
                    all_containers.extend(pod_spec.get("containers", []))
                    all_containers.extend(pod_spec.get("initContainers", []))
                    
                    for container in all_containers:
                        image_full = container.get("image", "")
                        if ":" not in image_full:
                            continue
                        
                        image, current_tag = image_full.rsplit(":", 1)
                        
                        # If using latest/stable, it's always up-to-date by definition
                        if current_tag in ["latest", "stable"]:
                            status = "🔄 Dynamic"
                            # Truncate long image names with ellipsis
                            image_display = image if len(image) <= 50 else image[:47] + "..."
                            print(f"{name:<25} {image_display:<50} {current_tag:<15} {'N/A':<15} {status:<10}")
                            continue
                        
                        # Get latest tag
                        latest_tag = get_latest_docker_tag(image)
                        
                        if latest_tag:
                            try:
                                normalized_current = _normalize_version(current_tag.lstrip("v"))
                                normalized_latest = _normalize_version(latest_tag.lstrip("v"))
                                is_outdated = version.parse(normalized_latest) > version.parse(normalized_current)
                            except version.InvalidVersion:
                                is_outdated = current_tag != latest_tag
                            
                            status = "⚠️ Update" if is_outdated else "✅ OK"
                            
                            if is_outdated:
                                updates.append(name)
                        else:
                            latest_tag = "N/A"
                            status = "❌ Error"
                        
                        # Truncate long image names with ellipsis
                        image_display = image if len(image) <= 50 else image[:47] + "..."
                        print(f"{name:<25} {image_display:<50} {current_tag:<15} {latest_tag:<15} {status:<10}")
    
    return updates


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Check versions of homelab components")
    parser.add_argument("--skip-helm", action="store_true", help="Skip Helm chart checks, only check Kustomize apps")
    args = parser.parse_args()
    
    print("=" * 110)
    print("📊 VERSION CHECK REPORT")
    print("=" * 110 + "\n")
    
    helm_updates = []
    if not args.skip_helm:
        print("🔄 Updating Helm repositories...\n")
        if not run_command(["helm", "repo", "update"]):
            print("❌ Failed to update Helm repos\n")
            return
        
        print("✅ Helm repos updated\n")
        helm_updates = check_helm_apps()
    
    kustomize_updates = check_kustomize_apps()
    
    # Summary
    print("\n" + "=" * 110)
    total = len(helm_updates) + len(kustomize_updates)
    
    if total > 0:
        if args.skip_helm:
            print(f"📈 {total} update(s) available: {len(kustomize_updates)} Kustomize")
        else:
            print(f"📈 {total} update(s) available: {len(helm_updates)} Helm, {len(kustomize_updates)} Kustomize")
    else:
        print("📈 All components up to date! ✅")
    
    print("=" * 110 + "\n")


if __name__ == "__main__":
    main()
