#!/usr/bin/env python3
"""
Version Checker for Kubernetes Homelab Components
Checks for updates to Helm charts and Docker images.
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime

import requests
import yaml
from packaging import version

# Repository root
REPO_ROOT = Path(__file__).parent.parent
APPS_DIR = REPO_ROOT / "apps"
BASE_DIR = REPO_ROOT / "base"


class VersionChecker:
    def __init__(self):
        self.helm_results = []
        self.image_results = []
        
    def run_helm_repo_update(self) -> bool:
        """Update all Helm repositories."""
        print("🔄 Updating Helm repositories...")
        try:
            subprocess.run(
                ["helm", "repo", "update"],
                capture_output=True,
                check=True,
                text=True
            )
            print("✅ Helm repositories updated\n")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to update Helm repos: {e.stderr}")
            return False
        except FileNotFoundError:
            print("❌ helm command not found. Please install Helm.")
            return False

    def get_latest_helm_version(self, repo_url: str, chart_name: str) -> Optional[str]:
        """Get latest Helm chart version from repository."""
        try:
            # Handle OCI registries specially
            if repo_url.startswith('oci://'):
                return self._get_oci_helm_version(repo_url, chart_name)
            
            # Determine the expected repo name from URL
            # e.g., https://metallb.github.io/metallb -> metallb
            # e.g., https://charts.jetstack.io -> (depends on repo add command)
            expected_repo_prefix = None
            
            # Try to match common repo patterns
            if 'metallb.github.io' in repo_url:
                expected_repo_prefix = 'metallb/'
            elif 'bitnami' in repo_url:
                expected_repo_prefix = 'bitnami/'
            elif 'jetstack' in repo_url:
                expected_repo_prefix = 'jetstack/'
            elif 'traefik' in repo_url:
                expected_repo_prefix = 'traefik/'
            elif 'prometheus-community' in repo_url:
                expected_repo_prefix = 'prometheus-community/'
            elif 'jameswynn' in repo_url:
                expected_repo_prefix = 'homepage/'
            elif 'stakater' in repo_url:
                expected_repo_prefix = 'stakater/'
            elif 'kubereboot' in repo_url:
                expected_repo_prefix = 'kured/'
            elif 'longhorn' in repo_url:
                expected_repo_prefix = 'longhorn/'
            elif '8gears' in repo_url:
                expected_repo_prefix = '8gears/'
            
            # Search for all versions of the chart
            result = subprocess.run(
                ["helm", "search", "repo", chart_name, "--versions", "-o", "json"],
                capture_output=True,
                check=True,
                text=True
            )
            
            versions_data = json.loads(result.stdout)
            if not versions_data:
                return None
            
            # Filter by expected repo prefix if we could determine it
            if expected_repo_prefix:
                versions_data = [
                    v for v in versions_data 
                    if v.get('name', '').startswith(expected_repo_prefix)
                ]
            
            # Filter out pre-release versions
            stable_versions = []
            for v in versions_data:
                ver = v.get("version", "")
                # Skip pre-release (alpha, beta, rc, dev, etc.)
                if not re.search(r'-(alpha|beta|rc|dev|pre|test)', ver, re.IGNORECASE):
                    stable_versions.append(ver)
            
            return stable_versions[0] if stable_versions else None
            
        except (subprocess.CalledProcessError, json.JSONDecodeError, FileNotFoundError):
            return None

    def _get_oci_helm_version(self, repo_url: str, chart_name: str) -> Optional[str]:
        """Get latest Helm chart version from OCI registry."""
        try:
            # For 8gears OCI registry, check GitHub releases
            if '8gears' in repo_url:
                github_url = "https://api.github.com/repos/8gears/n8n-helm-chart/releases"
                response = requests.get(github_url, timeout=10)
                
                if response.status_code == 200:
                    releases = response.json()
                    stable_versions = []
                    
                    for release in releases:
                        if release.get('draft') or release.get('prerelease'):
                            continue
                        tag = release.get('tag_name', '')
                        if tag and not re.search(r'-(alpha|beta|rc|dev|pre|test)', tag, re.IGNORECASE):
                            stable_versions.append(tag)
                    
                    if stable_versions:
                        try:
                            sorted_versions = sorted(
                                stable_versions,
                                key=lambda t: version.parse(t.lstrip('v')),
                                reverse=True
                            )
                            return sorted_versions[0]
                        except version.InvalidVersion:
                            return stable_versions[0]
            
            # For other OCI registries, could implement other strategies here
            return None
            
        except Exception:
            return None

    def check_helm_charts(self):
        """Check all Helm charts for updates."""
        print("📊 Checking Helm chart versions...\n")
        
        for app_file in sorted(APPS_DIR.glob("*.yaml")):
            if app_file.name == "kustomization.yaml":
                continue
            
            try:
                with open(app_file, 'r') as f:
                    app = yaml.safe_load(f)
                
                if not app or app.get('kind') != 'Application':
                    continue
                
                app_name = app['metadata']['name']
                spec = app['spec']
                
                # Handle both 'source' and 'sources'
                source = None
                if 'source' in spec:
                    source = spec['source']
                elif 'sources' in spec:
                    for src in spec['sources']:
                        if 'chart' in src:
                            source = src
                            break
                
                if not source or 'chart' not in source:
                    continue
                
                chart_name = source['chart']
                repo_url = source.get('repoURL', '')
                current_version = source.get('targetRevision', 'unknown')
                
                print(f"  Checking {app_name} ({chart_name})...", end=" ")
                
                latest_version = self.get_latest_helm_version(repo_url, chart_name)
                
                if latest_version:
                    try:
                        current_ver = version.parse(current_version.lstrip('v'))
                        latest_ver = version.parse(latest_version.lstrip('v'))
                        update_available = latest_ver > current_ver
                    except version.InvalidVersion:
                        update_available = current_version != latest_version
                    
                    status = "✅" if update_available else "✗"
                    print(f"{status}")
                    
                    self.helm_results.append({
                        'component': app_name,
                        'chart': chart_name,
                        'current': current_version,
                        'latest': latest_version,
                        'update_available': update_available
                    })
                else:
                    print("⚠️  (unable to fetch)")
                    self.helm_results.append({
                        'component': app_name,
                        'chart': chart_name,
                        'current': current_version,
                        'latest': 'N/A',
                        'update_available': False
                    })
                    
            except Exception as e:
                print(f"❌ Error processing {app_file.name}: {e}")
                continue

    def get_latest_docker_tag(self, image_repo: str, current_tag: str) -> Optional[str]:
        """Get latest Docker image tag from registry."""
        
        # Determine registry type
        if image_repo.startswith('ghcr.io/'):
            return self._get_ghcr_latest_tag(image_repo, current_tag)
        else:
            # Assume Docker Hub
            return self._get_dockerhub_latest_tag(image_repo, current_tag)

    def _get_dockerhub_latest_tag(self, image_repo: str, current_tag: str) -> Optional[str]:
        """Get latest tag from Docker Hub."""
        try:
            # Parse repo (handle library/ images)
            repo_parts = image_repo.split('/')
            if len(repo_parts) == 1:
                namespace = 'library'
                repo_name = repo_parts[0]
            else:
                namespace = repo_parts[0]
                repo_name = '/'.join(repo_parts[1:])
            
            url = f"https://hub.docker.com/v2/repositories/{namespace}/{repo_name}/tags"
            params = {'page_size': 100}
            
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            tags = data.get('results', [])
            
            # Filter stable versions
            stable_tags = []
            for tag_info in tags:
                tag_name = tag_info.get('name', '')
                
                # Skip latest, develop, master, main, etc.
                if tag_name in ['latest', 'develop', 'master', 'main', 'edge', 'nightly', 'next', 'beta', 'stable']:
                    continue
                
                # Skip pre-release
                if re.search(r'-(alpha|beta|rc|dev|pre|test|snapshot)', tag_name, re.IGNORECASE):
                    continue
                
                # Skip architecture-specific tags (e.g., 2.3.0-amd64, 2.3.0-arm64)
                if re.search(r'-(amd64|arm64|armv7|i386)$', tag_name):
                    continue
                
                stable_tags.append(tag_name)
            
            if not stable_tags:
                # Fallback to 'latest' if no stable versions found
                return 'latest'
            
            # Sort by semantic version if possible
            try:
                sorted_tags = sorted(
                    stable_tags,
                    key=lambda t: version.parse(t.lstrip('v')),
                    reverse=True
                )
                return sorted_tags[0]
            except version.InvalidVersion:
                # If not semantic versioning, return first
                return stable_tags[0]
                
        except Exception as e:
            return None

    def _get_ghcr_latest_tag(self, image_repo: str, current_tag: str) -> Optional[str]:
        """Get latest tag from GitHub Container Registry."""
        try:
            # GHCR - Format: ghcr.io/owner/repo
            parts = image_repo.replace('ghcr.io/', '').split('/')
            if len(parts) < 2:
                return None
            
            owner = parts[0]
            package = parts[1]
            
            # Try to get releases from GitHub API (most reliable)
            github_api_url = f"https://api.github.com/repos/{owner}/{package}/releases"
            try:
                response = requests.get(github_api_url, timeout=10)
                if response.status_code == 200:
                    releases = response.json()
                    stable_versions = []
                    
                    for release in releases:
                        if release.get('draft') or release.get('prerelease'):
                            continue
                        tag = release.get('tag_name', '')
                        if tag:
                            stable_versions.append(tag)
                    
                    if stable_versions:
                        try:
                            sorted_tags = sorted(
                                stable_versions,
                                key=lambda t: version.parse(t.lstrip('v')),
                                reverse=True
                            )
                            return sorted_tags[0]
                        except version.InvalidVersion:
                            return stable_versions[0]
            except Exception:
                pass
            
            # Fallback: Try GitHub API
            url = f"https://api.github.com/users/{owner}/packages/container/{package}/versions"
            headers = {'Accept': 'application/vnd.github.v3+json'}
            
            response = requests.get(url, headers=headers, timeout=10)
            
            if response.status_code == 404:
                # Try organization endpoint
                url = f"https://api.github.com/orgs/{owner}/packages/container/{package}/versions"
                response = requests.get(url, headers=headers, timeout=10)
            
            if response.status_code != 200:
                return None
            
            data = response.json()
            
            # Extract tags from versions
            all_tags = []
            for pkg_version in data:
                tags = pkg_version.get('metadata', {}).get('container', {}).get('tags', [])
                all_tags.extend(tags)
            
            # Filter stable versions
            stable_tags = []
            for tag_name in all_tags:
                if tag_name in ['latest', 'develop', 'master', 'main', 'edge', 'nightly']:
                    continue
                if re.search(r'-(alpha|beta|rc|dev|pre|test)', tag_name, re.IGNORECASE):
                    continue
                stable_tags.append(tag_name)
            
            if not stable_tags:
                return None
                stable_tags.append(tag_name)
            
            if not stable_tags:
                return 'latest'
            
            # Sort by semantic version
            try:
                sorted_tags = sorted(
                    stable_tags,
                    key=lambda t: version.parse(t.lstrip('v')),
                    reverse=True
                )
                return sorted_tags[0]
            except version.InvalidVersion:
                return stable_tags[0]
                
        except Exception:
            return None

    def check_docker_images(self):
        """Check all Docker images for updates."""
        print("\n🐳 Checking Docker image versions...\n")
        
        for values_dir in sorted(BASE_DIR.iterdir()):
            if not values_dir.is_dir():
                continue
            
            values_file = values_dir / "values.yaml"
            if not values_file.exists():
                continue
            
            try:
                with open(values_file, 'r') as f:
                    values = yaml.safe_load(f)
                
                if not values or 'image' not in values:
                    continue
                
                image_config = values['image']
                image_repo = image_config.get('repository', '')
                current_tag = image_config.get('tag', 'latest')
                
                if not image_repo:
                    continue
                
                component_name = values_dir.name
                print(f"  Checking {component_name} ({image_repo})...", end=" ")
                
                latest_tag = self.get_latest_docker_tag(image_repo, current_tag)
                
                if latest_tag:
                    try:
                        current_ver = version.parse(str(current_tag).lstrip('v'))
                        latest_ver = version.parse(str(latest_tag).lstrip('v'))
                        update_available = latest_ver > current_ver
                    except version.InvalidVersion:
                        update_available = str(current_tag) != str(latest_tag)
                    
                    status = "✅" if update_available else "✗"
                    print(f"{status}")
                    
                    self.image_results.append({
                        'component': component_name,
                        'repository': image_repo,
                        'current': str(current_tag),
                        'latest': str(latest_tag),
                        'update_available': update_available
                    })
                else:
                    print("⚠️  (unable to fetch)")
                    self.image_results.append({
                        'component': component_name,
                        'repository': image_repo,
                        'current': str(current_tag),
                        'latest': 'N/A',
                        'update_available': False
                    })
                    
            except Exception as e:
                print(f"❌ Error processing {values_dir.name}: {e}")
                continue

    def print_report(self):
        """Print report to console."""
        print("\n" + "="*80)
        print("📊 VERSION CHECK REPORT")
        print("="*80)
        
        # Helm Charts
        print("\n🎯 HELM CHARTS\n")
        if self.helm_results:
            print(f"{'Component':<20} {'Chart':<25} {'Current':<15} {'Latest':<15} {'Update':<10}")
            print("-" * 90)
            for result in self.helm_results:
                status = "✅ Yes" if result['update_available'] else "✗ No"
                print(f"{result['component']:<20} {result['chart']:<25} {result['current']:<15} {result['latest']:<15} {status:<10}")
        else:
            print("No Helm charts found.")
        
        # Docker Images
        print("\n🐳 DOCKER IMAGES\n")
        if self.image_results:
            print(f"{'Component':<20} {'Current':<15} {'Latest':<15} {'Update':<10}")
            print("-" * 65)
            for result in self.image_results:
                status = "✅ Yes" if result['update_available'] else "✗ No"
                print(f"{result['component']:<20} {result['current']:<15} {result['latest']:<15} {status:<10}")
        else:
            print("No Docker images found.")
        
        # Summary
        helm_updates = sum(1 for r in self.helm_results if r['update_available'])
        image_updates = sum(1 for r in self.image_results if r['update_available'])
        
        print("\n" + "="*80)
        print(f"📈 SUMMARY: {helm_updates} Helm chart updates, {image_updates} Docker image updates available")
        print("="*80 + "\n")

    def write_markdown_report(self, output_file: Path):
        """Write report to Markdown file."""
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        with open(output_file, 'w') as f:
            f.write("# Component Version Check Report\n\n")
            f.write(f"**Generated:** {now}\n\n")
            
            # Helm Charts
            f.write("## 🎯 Helm Charts\n\n")
            if self.helm_results:
                f.write("| Component | Chart | Current | Latest | Update Available |\n")
                f.write("|-----------|-------|---------|--------|------------------|\n")
                for result in self.helm_results:
                    status = "✅ Yes" if result['update_available'] else "✗ No"
                    f.write(f"| {result['component']} | {result['chart']} | {result['current']} | {result['latest']} | {status} |\n")
            else:
                f.write("*No Helm charts found.*\n")
            
            # Docker Images
            f.write("\n## 🐳 Docker Images\n\n")
            if self.image_results:
                f.write("| Component | Repository | Current | Latest | Update Available |\n")
                f.write("|-----------|------------|---------|--------|------------------|\n")
                for result in self.image_results:
                    status = "✅ Yes" if result['update_available'] else "✗ No"
                    f.write(f"| {result['component']} | {result['repository']} | {result['current']} | {result['latest']} | {status} |\n")
            else:
                f.write("*No Docker images found.*\n")
            
            # Summary
            helm_updates = sum(1 for r in self.helm_results if r['update_available'])
            image_updates = sum(1 for r in self.image_results if r['update_available'])
            
            f.write(f"\n## 📈 Summary\n\n")
            f.write(f"- **Helm chart updates available:** {helm_updates}\n")
            f.write(f"- **Docker image updates available:** {image_updates}\n")
        
        print(f"✅ Markdown report written to: {output_file}")


def main():
    parser = argparse.ArgumentParser(
        description="Check for Helm chart and Docker image updates",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        '--format',
        choices=['console', 'md'],
        default='console',
        help='Output format (default: console)'
    )
    parser.add_argument(
        '--output',
        type=Path,
        default=Path('update/version-report.md'),
        help='Output file for Markdown format (default: update/version-report.md)'
    )
    parser.add_argument(
        '--skip-helm-update',
        action='store_true',
        help='Skip helm repo update'
    )
    
    args = parser.parse_args()
    
    checker = VersionChecker()
    
    # Update Helm repos
    if not args.skip_helm_update:
        if not checker.run_helm_repo_update():
            print("⚠️  Continuing without Helm repo update...")
    
    # Check versions
    checker.check_helm_charts()
    checker.check_docker_images()
    
    # Output results
    if args.format == 'md':
        # Ensure output directory exists
        args.output.parent.mkdir(parents=True, exist_ok=True)
        checker.write_markdown_report(args.output)
    
    # Always print console report
    checker.print_report()


if __name__ == "__main__":
    main()
