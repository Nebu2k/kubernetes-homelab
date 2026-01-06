#!/usr/bin/env python3
"""
Simple version checker for Kubernetes homelab components.
Checks Helm charts and container images for updates.
"""

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


def get_latest_helm_version(chart_name: str) -> Optional[str]:
    """Get latest Helm chart version."""
    output = run_command(["helm", "search", "repo", chart_name, "-o", "json"])
    if not output:
        return None
    
    try:
        data = json.loads(output)
        return data[0]["version"] if data else None
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


def _filter_stable_tag(tags: list) -> Optional[str]:
    """Filter and return latest stable tag."""
    stable = []
    for tag in tags:
        if tag in ["latest", "stable"]:
            continue
        if any(x in tag.lower() for x in ["alpha", "beta", "rc", "dev", "nightly", "test"]):
            continue
        if any(x in tag.lower() for x in ["alpine", "slim", "debian", "ubuntu"]):
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
        
        # Get latest version
        latest = get_latest_helm_version(chart)
        
        if latest:
            try:
                is_outdated = version.parse(latest.lstrip("v")) > version.parse(current.lstrip("v"))
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
    print(f"{'Component':<25} {'Image':<40} {'Current':<15} {'Latest':<15} {'Status':<10}")
    print("-" * 110)
    
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
        image_found = False
        for yaml_file in path.glob("*.yaml"):
            if yaml_file.name == "kustomization.yaml":
                continue
            
            with open(yaml_file) as f:
                for doc in yaml.safe_load_all(f):
                    if not doc or doc.get("kind") not in ["Deployment", "StatefulSet"]:
                        continue
                    
                    containers = doc.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
                    
                    for container in containers:
                        image_full = container.get("image", "")
                        if ":" not in image_full:
                            continue
                        
                        image, current_tag = image_full.rsplit(":", 1)
                        
                        # Get latest tag
                        latest_tag = get_latest_docker_tag(image)
                        
                        if latest_tag:
                            try:
                                is_outdated = version.parse(latest_tag.lstrip("v")) > version.parse(current_tag.lstrip("v"))
                            except version.InvalidVersion:
                                is_outdated = current_tag != latest_tag
                            
                            status = "⚠️ Update" if is_outdated else "✅ OK"
                            
                            if is_outdated:
                                updates.append(name)
                        else:
                            latest_tag = "N/A"
                            status = "❌ Error"
                        
                        # Truncate long image names
                        image_short = image if len(image) <= 40 else "..." + image[-37:]
                        
                        print(f"{name:<25} {image_short:<40} {current_tag:<15} {latest_tag:<15} {status:<10}")
                        image_found = True
                        break
                    
                    if image_found:
                        break
            
            if image_found:
                break
    
    return updates


def main():
    """Main entry point."""
    print("🔄 Updating Helm repositories...\n")
    if not run_command(["helm", "repo", "update"]):
        print("❌ Failed to update Helm repos\n")
        return
    
    print("✅ Helm repos updated\n")
    print("=" * 110)
    print("📊 VERSION CHECK REPORT")
    print("=" * 110 + "\n")
    
    helm_updates = check_helm_apps()
    kustomize_updates = check_kustomize_apps()
    
    # Summary
    print("\n" + "=" * 110)
    total = len(helm_updates) + len(kustomize_updates)
    
    if total > 0:
        print(f"📈 {total} update(s) available: {len(helm_updates)} Helm, {len(kustomize_updates)} Kustomize")
    else:
        print("📈 All components up to date! ✅")
    
    print("=" * 110 + "\n")


if __name__ == "__main__":
    main()
