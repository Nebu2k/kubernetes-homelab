#!/usr/bin/env python3
"""
Version Checker for Kubernetes Homelab Components v2
Checks Helm charts and their application versions.
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed

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
            # Handle OCI registries
            if repo_url.startswith('oci://'):
                return self._get_oci_helm_version(repo_url, chart_name)
            
            # Map repo URL to expected prefix
            repo_mapping = {
                'metallb.github.io': 'metallb/',
                'jetstack': 'jetstack/',
                'traefik': 'traefik/',
                'prometheus-community': 'prometheus-community/',
                'jameswynn': 'homepage/',
                'stakater': 'stakater/',
                'kubereboot': 'kured/',
                'longhorn': 'longhorn/',
                'portainer': 'portainer/',
                'bitnami.com/charts': 'sealed-secrets/',
            }
            
            expected_prefix = None
            for key, prefix in repo_mapping.items():
                if key in repo_url:
                    expected_prefix = prefix
                    break
            
            # Search for chart versions
            result = subprocess.run(
                ["helm", "search", "repo", chart_name, "--versions", "-o", "json"],
                capture_output=True,
                check=True,
                text=True
            )
            
            versions_data = json.loads(result.stdout)
            if not versions_data:
                return None
            
            # Filter by expected repo prefix
            if expected_prefix:
                versions_data = [v for v in versions_data if v['name'].startswith(expected_prefix)]
            
            if not versions_data:
                return None
            
            # Return first version (already sorted by helm)
            return versions_data[0]['version']
            
        except Exception:
            return None

    def _get_oci_helm_version(self, repo_url: str, chart_name: str) -> Optional[str]:
        """Get version from OCI registry via GitHub releases."""
        try:
            # For 8gears OCI registry
            if '8gears' in repo_url:
                github_url = "https://api.github.com/repos/8gears/n8n-helm-chart/releases"
                response = requests.get(github_url, timeout=10)
                
                if response.status_code == 200:
                    releases = response.json()
                    for release in releases:
                        if not release.get('draft') and not release.get('prerelease'):
                            tag = release.get('tag_name', '')
                            if tag:
                                return tag
            
            return None
            
        except Exception:
            return None

    def _get_helm_app_version(self, repo_url: str, chart_name: str, chart_version: str) -> Tuple[Optional[str], Optional[str]]:
        """Get appVersion and default image repository from Helm chart."""
        try:
            # Build chart reference
            if repo_url.startswith('oci://'):
                # Try to get app version from GitHub releases for n8n
                if '8gears' in repo_url and chart_name == 'n8n':
                    try:
                        github_url = "https://api.github.com/repos/8gears/n8n-helm-chart/releases"
                        response = requests.get(github_url, timeout=10)
                        
                        if response.status_code == 200:
                            releases = response.json()
                            for release in releases:
                                if release.get('tag_name') == chart_version:
                                    body = release.get('body', '')
                                    match = re.search(r'n8n.*?version\s+([\d.]+)', body, re.IGNORECASE)
                                    if match:
                                        return match.group(1), 'n8nio/n8n'
                                    break
                    except Exception:
                        pass
                
                chart_ref = f"{repo_url.rstrip('/')}/{chart_name}"
            else:
                # Regular Helm repo
                result = subprocess.run(
                    ["helm", "search", "repo", chart_name, "-o", "json"],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                if result.returncode != 0:
                    return None, None
                
                repos = json.loads(result.stdout)
                
                # Map URL to prefix
                repo_mapping = {
                    'metallb.github.io': 'metallb/',
                    'jetstack': 'jetstack/',
                    'traefik': 'traefik/',
                    'prometheus-community': 'prometheus-community/',
                    'jameswynn': 'homepage/',
                    'stakater': 'stakater/',
                    'kubereboot': 'kured/',
                    'longhorn': 'longhorn/',
                    'portainer': 'portainer/',
                }
                
                expected_prefix = None
                for key, prefix in repo_mapping.items():
                    if key in repo_url:
                        expected_prefix = prefix
                        break
                
                if expected_prefix:
                    chart_ref = f"{expected_prefix}{chart_name}"
                elif repos:
                    chart_ref = repos[0]['name']
                else:
                    return None, None
            
            # Get appVersion from chart metadata
            result = subprocess.run(
                ["helm", "show", "chart", chart_ref, "--version", chart_version],
                capture_output=True,
                check=True,
                text=True,
                timeout=30
            )
            
            chart_data = yaml.safe_load(result.stdout)
            app_version = chart_data.get('appVersion')
            
            # Clean up app version (remove common prefixes)
            if app_version:
                app_version = re.sub(r'^(ce-latest-ee-|version-|release-|v)', '', app_version)
            
            # Get default image repository from values
            result = subprocess.run(
                ["helm", "show", "values", chart_ref, "--version", chart_version],
                capture_output=True,
                check=True,
                text=True,
                timeout=30
            )
            
            values_data = yaml.safe_load(result.stdout)
            image_repo = None
            
            if values_data:
                # Try common patterns
                if 'image' in values_data:
                    if isinstance(values_data['image'], dict):
                        image_repo = values_data['image'].get('repository')
                        
                        # Check for nested structures (e.g., longhorn: image.longhorn.engine.repository)
                        if not image_repo:
                            for key1 in values_data['image']:
                                if isinstance(values_data['image'][key1], dict):
                                    # Try direct repository
                                    nested_repo = values_data['image'][key1].get('repository')
                                    if nested_repo:
                                        image_repo = nested_repo
                                        break
                                    # Try deeper nesting (image.longhorn.engine.repository)
                                    for key2 in values_data['image'][key1]:
                                        if isinstance(values_data['image'][key1][key2], dict):
                                            nested_repo = values_data['image'][key1][key2].get('repository')
                                            if nested_repo:
                                                image_repo = nested_repo
                                                break
                                    if image_repo:
                                        break
                    elif isinstance(values_data['image'], str):
                        image_repo = values_data['image']
                
                # Check other common patterns (prometheus, grafana, alertmanager, etc.)
                if not image_repo:
                    for key in ['controller', 'main', 'webhook', 'prometheus', 'grafana', 'alertmanager', 'server']:
                        if key in values_data and isinstance(values_data[key], dict):
                            if 'image' in values_data[key]:
                                img = values_data[key]['image']
                                if isinstance(img, dict):
                                    image_repo = img.get('repository')
                                    if image_repo:
                                        break
            
            return app_version, image_repo
            
        except Exception:
            return None, None

    def get_latest_docker_tag(self, image_repo: str) -> Optional[str]:
        """Get latest stable Docker image tag."""
        # Determine registry type
        if image_repo.startswith('ghcr.io/'):
            return self._get_ghcr_latest_tag(image_repo)
        elif image_repo.startswith('quay.io/'):
            return self._get_quay_latest_tag(image_repo)
        else:
            return self._get_dockerhub_latest_tag(image_repo)

    def _get_dockerhub_latest_tag(self, image_repo: str) -> Optional[str]:
        """Get latest stable tag from Docker Hub."""
        try:
            # Parse repo
            repo_parts = image_repo.split('/')
            if len(repo_parts) == 1:
                namespace, repo_name = 'library', repo_parts[0]
            else:
                namespace, repo_name = repo_parts[0], '/'.join(repo_parts[1:])
            
            url = f"https://hub.docker.com/v2/repositories/{namespace}/{repo_name}/tags"
            params = {'page_size': 100}
            
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            tags = [tag_info.get('name', '') for tag_info in data.get('results', [])]
            
            return self._find_latest_stable_tag(tags)
                
        except Exception:
            return None

    def _get_quay_latest_tag(self, image_repo: str) -> Optional[str]:
        """Get latest stable tag from Quay.io."""
        try:
            parts = image_repo.replace('quay.io/', '').split('/')
            if len(parts) < 2:
                return None
            
            namespace, repo_name = parts[0], parts[1]
            
            url = f"https://quay.io/api/v1/repository/{namespace}/{repo_name}/tag/"
            params = {'limit': 100, 'onlyActiveTags': True}
            
            response = requests.get(url, params=params, timeout=10)
            if response.status_code != 200:
                return None
            
            data = response.json()
            tags = [tag_info.get('name', '') for tag_info in data.get('tags', [])]
            
            return self._find_latest_stable_tag(tags)
                
        except Exception:
            return None

    def _get_ghcr_latest_tag(self, image_repo: str) -> Optional[str]:
        """Get latest stable tag from GitHub Container Registry."""
        try:
            parts = image_repo.replace('ghcr.io/', '').split('/')
            if len(parts) < 2:
                return None
            
            owner, package = parts[0], parts[1]
            
            # Try GitHub releases API
            github_url = f"https://api.github.com/repos/{owner}/{package}/releases"
            try:
                response = requests.get(github_url, timeout=10)
                if response.status_code == 200:
                    releases = response.json()
                    tags = []
                    for release in releases:
                        if not release.get('draft') and not release.get('prerelease'):
                            tag = release.get('tag_name', '')
                            if tag:
                                tags.append(tag)
                    
                    if tags:
                        return self._find_latest_stable_tag(tags)
            except Exception:
                pass
            
            return None
            
        except Exception:
            return None

    def _find_latest_stable_tag(self, tags: List[str]) -> Optional[str]:
        """Find the latest stable semantic version from a list of tags."""
        stable_tags = []
        
        for tag in tags:
            # Skip non-stable tags
            if tag in ['latest', 'stable', 'develop', 'master', 'main', 'edge', 'nightly', 'next', 'beta', 'lts']:
                continue
            
            # Skip prefixes
            if tag.startswith(('nightly', 'base', 'builder', 'ce-latest-ee-', 'chart-', 'sha256-')):
                continue
            
            # Skip suffixes
            if tag.endswith(('.sig', '.att', '.asc', '-head')):
                continue
            
            # Skip tags containing -head (e.g., v1.10.x-head)
            if '-head' in tag or '-SNAPSHOT' in tag:
                continue
            
            # Skip pre-release versions
            if re.search(r'-(alpha|beta|rc|dev|pre|test|snapshot)', tag, re.IGNORECASE):
                continue
            
            # Skip architecture/OS/variant tags (anywhere in string)
            if re.search(r'(amd64|arm64|armv7|i386|ppc64le|s390x|alpine|debian|ubuntu|windowsservercore|nanoserver|slim|rootless|fips)', tag, re.IGNORECASE):
                continue
            
            # Skip SHA hashes
            if re.search(r'sha256|sha512|md5', tag, re.IGNORECASE):
                continue
            
            # Must contain at least one digit (version number)
            if not re.search(r'\d', tag):
                continue
            
            stable_tags.append(tag)
        
        if not stable_tags:
            return None
        
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

    def _check_single_helm_chart(self, app_file: Path) -> Optional[Dict]:
        """Check a single Helm chart for updates."""
        if app_file.name == "kustomization.yaml":
            return None
        
        try:
            with open(app_file, 'r') as f:
                app = yaml.safe_load(f)
            
            if not app or app.get('kind') != 'Application':
                return None
            
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
                return None
            
            chart_name = source['chart']
            repo_url = source.get('repoURL', '')
            current_version = source.get('targetRevision', 'unknown')
            
            print(f"  Checking {app_name} ({chart_name})...", end=" ", flush=True)
            
            # Get latest chart version
            latest_version = self.get_latest_helm_version(repo_url, chart_name)
            
            if latest_version:
                try:
                    current_ver = version.parse(current_version.lstrip('v'))
                    latest_ver = version.parse(latest_version.lstrip('v'))
                    chart_update_available = latest_ver > current_ver
                except version.InvalidVersion:
                    chart_update_available = current_version != latest_version
            else:
                chart_update_available = False
                latest_version = 'N/A'
            
            # Get app version and image repo from chart
            app_version, chart_image_repo = self._get_helm_app_version(repo_url, chart_name, current_version)
            
            # Check for manual image tag override
            manual_image_tag = None
            values_file = BASE_DIR / app_name / "values.yaml"
            if values_file.exists():
                try:
                    with open(values_file, 'r') as f:
                        values = yaml.safe_load(f)
                        if values and 'image' in values:
                            manual_image_tag = values['image'].get('tag')
                except Exception:
                    pass
            
            # Get latest available app version from Docker registry
            latest_app_version = None
            if chart_image_repo:
                latest_app_version = self.get_latest_docker_tag(chart_image_repo)
            
            status = "✅" if chart_update_available else "✗"
            print(f"{status}")
            
            return {
                'component': app_name,
                'chart': chart_name,
                'chart_current': current_version,
                'chart_latest': latest_version,
                'chart_update_available': chart_update_available,
                'app_version': app_version,
                'manual_image_tag': manual_image_tag,
                'latest_app_version': latest_app_version,
                'chart_image_repo': chart_image_repo
            }
                
        except Exception as e:
            print(f"❌ Error: {e}")
            return None

    def check_helm_charts(self):
        """Check all Helm charts for updates (parallelized)."""
        print("📊 Checking Helm chart versions...\n")
        
        app_files = [f for f in sorted(APPS_DIR.glob("*.yaml")) if f.name != "kustomization.yaml"]
        
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = {executor.submit(self._check_single_helm_chart, app_file): app_file for app_file in app_files}
            
            for future in as_completed(futures):
                result = future.result()
                if result:
                    self.helm_results.append(result)
        
        # Sort by component name
        self.helm_results.sort(key=lambda x: x['component'])

    def print_report(self):
        """Print report to console."""
        print("\n" + "="*120)
        print("📊 VERSION CHECK REPORT")
        print("="*120)
        
        if not self.helm_results:
            print("\nNo Helm charts found.")
            return
        
        print("\n🎯 HELM CHARTS\n")
        print(f"{'Component':<20} {'Chart':<12} {'Latest':<12} {'App Ver':<12} {'Manual Tag':<12} {'Latest App':<12} {'Status':<15}")
        print("-" * 120)
        
        for result in self.helm_results:
            component = result['component']
            chart_current = result['chart_current']
            chart_latest = result['chart_latest']
            app_ver = result.get('app_version') or 'N/A'
            manual_tag = result.get('manual_image_tag') or 'N/A'
            latest_app = result.get('latest_app_version') or 'N/A'
            
            # Determine status
            statuses = []
            
            # Check chart update
            if result['chart_update_available']:
                statuses.append("⚠️ Chart")
            
            # Check app version status
            app_outdated = False
            manual_outdated = False
            
            if latest_app != 'N/A':
                # Check if chart's app version is outdated
                if app_ver != 'N/A':
                    try:
                        app_current = version.parse(str(app_ver).lstrip('v'))
                        app_latest = version.parse(str(latest_app).lstrip('v'))
                        app_outdated = app_latest > app_current
                    except version.InvalidVersion:
                        app_outdated = str(app_ver) != str(latest_app)
                
                # Check if manual tag is outdated
                if manual_tag != 'N/A':
                    try:
                        manual_current = version.parse(str(manual_tag).lstrip('v'))
                        manual_latest = version.parse(str(latest_app).lstrip('v'))
                        manual_outdated = manual_latest > manual_current
                    except version.InvalidVersion:
                        manual_outdated = str(manual_tag) != str(latest_app)
            
            # Build status message
            if manual_tag != 'N/A' and not manual_outdated:
                # Manual tag is current
                if app_ver != 'N/A' and app_outdated:
                    statuses.append("⚠️ Helm app")
            elif app_outdated:
                statuses.append("⚠️ App")
            
            if manual_outdated:
                statuses.append("⚠️ Tag")
            
            status = " ".join(statuses) if statuses else "✅ OK"
            
            print(f"{component:<20} {chart_current:<12} {chart_latest:<12} {app_ver:<12} {manual_tag:<12} {latest_app:<12} {status:<15}")
        
        # Summary
        chart_updates = sum(1 for r in self.helm_results if r['chart_update_available'])
        
        app_outdated_count = 0
        manual_outdated_count = 0
        
        for result in self.helm_results:
            app_ver = result.get('app_version')
            manual_tag = result.get('manual_image_tag')
            latest_app = result.get('latest_app_version')
            
            if latest_app and latest_app != 'N/A':
                # Check app version
                if app_ver and app_ver != 'N/A':
                    try:
                        app_current = version.parse(str(app_ver).lstrip('v'))
                        app_latest = version.parse(str(latest_app).lstrip('v'))
                        if app_latest > app_current:
                            app_outdated_count += 1
                    except version.InvalidVersion:
                        pass
                
                # Check manual tag
                if manual_tag and manual_tag != 'N/A':
                    try:
                        manual_current = version.parse(str(manual_tag).lstrip('v'))
                        manual_latest = version.parse(str(latest_app).lstrip('v'))
                        if manual_latest > manual_current:
                            manual_outdated_count += 1
                    except version.InvalidVersion:
                        pass
        
        print("\n" + "="*120)
        print(f"📈 SUMMARY: {chart_updates} chart updates available")
        if app_outdated_count > 0:
            print(f"⚠️  WARNING: {app_outdated_count} charts with outdated appVersion")
        if manual_outdated_count > 0:
            print(f"⚠️  WARNING: {manual_outdated_count} charts with outdated manual image tags")
        print("="*120 + "\n")

    def write_markdown_report(self, output_file: Path):
        """Write report to Markdown file."""
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        with open(output_file, 'w') as f:
            f.write("# Component Version Check Report\n\n")
            f.write(f"**Generated:** {now}\n\n")
            
            if not self.helm_results:
                f.write("*No Helm charts found.*\n")
                return
            
            f.write("## 🎯 Helm Charts\n\n")
            f.write("| Component | Chart Ver | Latest Chart | App Version | Manual Tag | Latest App | Status |\n")
            f.write("|-----------|-----------|--------------|-------------|------------|------------|--------|\n")
            
            for result in self.helm_results:
                component = result['component']
                chart_current = result['chart_current']
                chart_latest = result['chart_latest']
                app_ver = result.get('app_version') or 'N/A'
                manual_tag = result.get('manual_image_tag') or 'N/A'
                latest_app = result.get('latest_app_version') or 'N/A'
                
                # Determine status
                statuses = []
                
                if result['chart_update_available']:
                    statuses.append("⚠️ Chart Update")
                
                # Check app version status
                app_outdated = False
                manual_outdated = False
                
                if latest_app != 'N/A':
                    if app_ver != 'N/A':
                        try:
                            app_current = version.parse(str(app_ver).lstrip('v'))
                            app_latest = version.parse(str(latest_app).lstrip('v'))
                            app_outdated = app_latest > app_current
                        except version.InvalidVersion:
                            app_outdated = str(app_ver) != str(latest_app)
                    
                    if manual_tag != 'N/A':
                        try:
                            manual_current = version.parse(str(manual_tag).lstrip('v'))
                            manual_latest = version.parse(str(latest_app).lstrip('v'))
                            manual_outdated = manual_latest > manual_current
                        except version.InvalidVersion:
                            manual_outdated = str(manual_tag) != str(latest_app)
                
                # Build status
                if manual_tag != 'N/A' and not manual_outdated:
                    if app_ver != 'N/A' and app_outdated:
                        statuses.append("⚠️ Helm uses old app")
                elif app_outdated:
                    statuses.append("⚠️ App Outdated")
                
                if manual_outdated:
                    statuses.append("⚠️ Tag Outdated")
                
                status = "<br>".join(statuses) if statuses else "✅ Up to date"
                
                f.write(f"| {component} | {chart_current} | {chart_latest} | {app_ver} | {manual_tag} | {latest_app} | {status} |\n")
            
            # Summary
            chart_updates = sum(1 for r in self.helm_results if r['chart_update_available'])
            app_outdated_count = sum(1 for r in self.helm_results 
                                     if r.get('app_version') and r.get('latest_app_version') 
                                     and r.get('app_version') != 'N/A' and r.get('latest_app_version') != 'N/A')
            
            f.write(f"\n## 📈 Summary\n\n")
            f.write(f"- **Helm chart updates available:** {chart_updates}\n")
            if app_outdated_count > 0:
                f.write(f"- **⚠️ Charts with app version info:** {len([r for r in self.helm_results if r.get('latest_app_version') and r.get('latest_app_version') != 'N/A'])}\n")
        
        print(f"✅ Markdown report written to: {output_file}")


def main():
    parser = argparse.ArgumentParser(
        description="Check for Helm chart and application updates",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        '--format',
        choices=['console', 'md', 'markdown'],
        default='console',
        help='Output format (default: console)'
    )
    parser.add_argument(
        '--output',
        type=Path,
        default=Path('version-report.md'),
        help='Output file for markdown report (default: version-report.md)'
    )
    parser.add_argument(
        '--skip-helm-update',
        action='store_true',
        help='Skip Helm repository update'
    )
    
    args = parser.parse_args()
    
    checker = VersionChecker()
    
    # Update Helm repos unless skipped
    if not args.skip_helm_update:
        if not checker.run_helm_repo_update():
            sys.exit(1)
    
    # Check Helm charts
    checker.check_helm_charts()
    
    # Print console report
    checker.print_report()
    
    # Write markdown report if requested
    if args.format in ['md', 'markdown']:
        checker.write_markdown_report(args.output)


if __name__ == "__main__":
    main()
