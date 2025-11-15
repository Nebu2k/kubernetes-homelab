#!/usr/bin/env python3
"""
README.md Generator for Kubernetes Homelab
Automatically extracts data from repository and renders README from template.
"""

import os
import yaml
import subprocess
from pathlib import Path
from jinja2 import Environment, FileSystemLoader
from collections import defaultdict

# Repository root
REPO_ROOT = Path(__file__).parent.parent
APPS_DIR = REPO_ROOT / "apps"
BASE_DIR = REPO_ROOT / "base"
OVERLAYS_DIR = REPO_ROOT / "overlays" / "production"
TEMPLATE_DIR = Path(__file__).parent / "templates"
OUTPUT_FILE = REPO_ROOT / "README.md"


def get_sync_waves():
    """Extract sync-wave annotations from ArgoCD Applications."""
    sync_waves = defaultdict(list)
    
    for app_file in APPS_DIR.glob("*.yaml"):
        if app_file.name == "kustomization.yaml":
            continue
            
        with open(app_file, 'r') as f:
            app = yaml.safe_load(f)
            
        if not app or app.get('kind') != 'Application':
            continue
            
        app_name = app['metadata']['name']
        annotations = app['metadata'].get('annotations', {})
        sync_wave = annotations.get('argocd.argoproj.io/sync-wave', '0')
        
        # Get purpose from spec
        source = app['spec'].get('source', {})
        chart = source.get('chart', '')
        repo_url = source.get('repoURL', '')
        
        # Determine component type and purpose
        purpose = get_component_purpose(app_name)
        
        sync_waves[int(sync_wave)].append({
            'name': app_name,
            'purpose': purpose,
            'chart': chart,
            'repo': repo_url
        })
    
    return dict(sorted(sync_waves.items()))


def get_component_purpose(name):
    """Map component names to their purposes."""
    purposes = {
        'sealed-secrets': 'Decrypt secrets',
        'metallb': 'LoadBalancer',
        'metallb-config': 'IPAddressPool',
        'reloader': 'Auto-reload on config changes',
        'cert-manager': 'TLS certificates',
        'cert-manager-config': 'ClusterIssuers',
        'nginx-ingress': 'HTTP(S) routing',
        'nginx-ingress-config': 'Custom headers',
        'longhorn': 'Persistent storage',
        'longhorn-config': 'Backup jobs, S3 config',
        'portainer': 'Management UI',
        'portainer-config': 'Management UI ingresses',
        'victoria-metrics-config': 'Grafana admin credentials',
        'victoria-metrics-k8s-stack': 'Monitoring Stack',
        'uptime-kuma': 'Uptime monitoring & status page',
        'uptime-kuma-config': 'Uptime Kuma ingress',
        'homepage': 'Homelab dashboard',
        'homepage-config': 'Homepage ingress, config & widget secrets',
        'argocd-config': 'Management UI ingresses',
        'coredns-config': 'CoreDNS forwarding to AdGuard',
        'private-services': 'External service ingresses',
        'demo-app': 'Sample application'
    }
    return purposes.get(name, name.replace('-', ' ').title())


def get_component_versions():
    """Extract component versions from ArgoCD Applications."""
    versions = {}
    
    for app_file in APPS_DIR.glob("*.yaml"):
        if app_file.name == "kustomization.yaml":
            continue
            
        with open(app_file, 'r') as f:
            app = yaml.safe_load(f)
            
        if not app or app.get('kind') != 'Application':
            continue
            
        app_name = app['metadata']['name']
        spec = app['spec']
        
        # Handle both 'source' (singular) and 'sources' (plural)
        source = None
        if 'source' in spec:
            source = spec['source']
        elif 'sources' in spec and len(spec['sources']) > 0:
            # Use the first source that has a chart
            for src in spec['sources']:
                if 'chart' in src:
                    source = src
                    break
        
        if not source:
            continue
            
        # Get version from targetRevision or chart version
        version = source.get('targetRevision', 'latest')
        chart = source.get('chart', '')
        
        if chart:
            versions[app_name] = {
                'chart': chart,
                'version': version
            }
    
    return versions


def get_repository_structure():
    """Generate repository structure using manual tree generation."""
    # Always use manual tree generation for consistency
    return generate_tree_fallback()


def generate_tree_fallback():
    """Generate tree structure manually if tree command not available."""
    lines = ["homelab/"]
    
    # Bootstrap directory
    lines.append("├── bootstrap/")
    lines.append("│   └── root-app.yaml              # App-of-Apps (deploys everything)")
    
    # Apps directory with sync-waves
    lines.append("├── apps/")
    apps_files = sorted((REPO_ROOT / "apps").glob("*.yaml"))
    sync_waves_map = {}
    
    for app_file in apps_files:
        if app_file.name == "kustomization.yaml":
            continue
        with open(app_file, 'r') as f:
            try:
                app = yaml.safe_load(f)
                if app and app.get('kind') == 'Application':
                    wave = app['metadata'].get('annotations', {}).get('argocd.argoproj.io/sync-wave', '0')
                    sync_waves_map[app_file.name] = wave
            except:
                pass
    
    # Add kustomization first
    lines.append("│   ├── kustomization.yaml         # List of all apps")
    
    # Add apps with wave annotations
    sorted_apps = sorted([f for f in apps_files if f.name != "kustomization.yaml"], 
                        key=lambda x: (int(sync_waves_map.get(x.name, '999')), x.name))
    
    for i, app_file in enumerate(sorted_apps):
        wave = sync_waves_map.get(app_file.name, '')
        wave_comment = f"# Wave {wave}" if wave else ""
        is_last = i == len(sorted_apps) - 1
        prefix = "│   └── " if is_last else "│   ├── "
        lines.append(f"{prefix}{app_file.name:<30} {wave_comment}")
    
    # Base directory
    lines.append("├── base/")
    base_dirs = sorted([d for d in (REPO_ROOT / "base").iterdir() if d.is_dir()])
    for i, base_dir in enumerate(base_dirs):
        is_last = i == len(base_dirs) - 1
        prefix = "│   └── " if is_last else "│   ├── "
        lines.append(f"{prefix}{base_dir.name}/")
        
        # Add values.yaml if exists
        values_file = base_dir / "values.yaml"
        if values_file.exists():
            sub_prefix = "        └── " if is_last else "│       └── "
            lines.append(f"{sub_prefix}values.yaml")
    
    # Overlays/production directory
    lines.append("└── overlays/production/")
    overlay_dirs = sorted([d for d in (REPO_ROOT / "overlays" / "production").iterdir() 
                          if d.is_dir() and not d.name.startswith('.')])
    
    for i, overlay_dir in enumerate(overlay_dirs):
        is_last_dir = i == len(overlay_dirs) - 1
        dir_prefix = "    └── " if is_last_dir else "    ├── "
        lines.append(f"{dir_prefix}{overlay_dir.name}/")
        
        # Add files in overlay
        overlay_files = sorted([f for f in overlay_dir.glob("*.yaml") if not f.name.startswith('.')])
        for j, overlay_file in enumerate(overlay_files):
            is_last_file = j == len(overlay_files) - 1
            if is_last_dir:
                file_prefix = "        └── " if is_last_file else "        ├── "
            else:
                file_prefix = "    │   └── " if is_last_file else "    │   ├── "
            
            # Add comment for important files
            comment = get_file_comment(overlay_dir.name, overlay_file.name)
            comment_text = f"  # {comment}" if comment else ""
            lines.append(f"{file_prefix}{overlay_file.name}{comment_text}")
    
    return "\n".join(lines)


def get_file_comment(dir_name, file_name):
    """Get descriptive comment for important files."""
    comments = {
        'cert-manager': {
            'cluster-issuer.yaml': 'Let\'s Encrypt issuers',
            'cloudflare-dns-sync-configmap.yaml': 'Cloudflare DNS sync script',
            'cloudflare-dns-sync-rbac.yaml': 'ServiceAccount + RBAC',
            'cloudflare-dns-sync-job.yaml': 'PostSync Hook + CronJob'
        },
        'metallb': {
            'metallb-ip-pool.yaml': 'IPAddressPool + L2Advertisement'
        },
        'nginx-ingress': {
            'custom-headers.yaml': 'Security headers ConfigMap'
        },
        'homepage': {
            'configmap.yaml': 'Dashboard configuration',
            'ingress.yaml': 'Homepage HTTPS ingress',
            'rbac.yaml': 'Kubernetes API access'
        },
        'private-services': {
            'adguard-dns-sync-rbac.yaml': 'ServiceAccount + RBAC',
            'adguard-dns-sync-job.yaml': 'PostSync Hook + CronJob'
        },
        'argocd': {
            'ingress.yaml': 'ArgoCD HTTPS ingress'
        },
        'portainer': {
            'ingress.yaml': 'Portainer HTTPS ingress'
        }
    }
    
    return comments.get(dir_name, {}).get(file_name, '')


def get_homepage_widget_secrets():
    """
    Find all *-unsealed.yaml.example files in homepage overlay
    and generate seal commands for them.
    Returns list of dictionaries with secret metadata.
    """
    homepage_dir = OVERLAYS_DIR / "homepage"
    secrets = []
    
    if not homepage_dir.exists():
        return secrets
    
    # Find all unsealed.yaml.example files
    for example_file in sorted(homepage_dir.glob("*-unsealed.yaml.example")):
        # Extract secret name from filename
        # e.g., "adguard-credentials-unsealed.yaml.example" -> "adguard-credentials"
        # Remove "-unsealed.yaml.example" suffix
        base_name = example_file.name.replace("-unsealed.yaml.example", "")
        
        secrets.append({
            'example_file': example_file.name,
            'unsealed_file': f"{base_name}-unsealed.yaml",
            'sealed_file': f"{base_name}-sealed.yaml",
            'secret_name': f"homepage-{base_name}",
            'base_name': base_name
        })
    
    return secrets


def main():
    """Generate README from template."""
    print("🔄 Generating README.md...")
    
    # Extract data
    print("  📊 Extracting sync-waves...")
    sync_waves = get_sync_waves()
    
    print("  📦 Extracting component versions...")
    versions = get_component_versions()
    
    print("  📁 Generating repository structure...")
    repo_structure = get_repository_structure()
    
    print("  🔐 Extracting Homepage widget secrets...")
    homepage_secrets = get_homepage_widget_secrets()
    print(f"      Found {len(homepage_secrets)} secrets to automate")
    for sec in homepage_secrets:
        print(f"        - {sec['base_name']}")
    
    # Prepare template data
    data = {
        'sync_waves': sync_waves,
        'versions': versions,
        'repo_structure': repo_structure,
        'homepage_secrets': homepage_secrets
    }
    
    # Render template
    print("  📝 Rendering template...")
    env = Environment(loader=FileSystemLoader(TEMPLATE_DIR))
    template = env.get_template('README.md.j2')
    rendered = template.render(**data)
    
    # Write output
    print(f"  ✍️  Writing to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w') as f:
        f.write(rendered)
    
    print("✅ README.md generated successfully!")
    print(f"   Location: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
