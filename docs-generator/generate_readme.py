#!/usr/bin/env python3
"""
README.md Generator for Kubernetes Homelab
Automatically extracts data from repository and renders README from template.
"""

import yaml
from pathlib import Path
from jinja2 import Environment, FileSystemLoader
from collections import defaultdict
import pathspec

# Repository root
REPO_ROOT = Path(__file__).parent.parent
APPS_DIR = REPO_ROOT / "apps"
MANIFESTS_DIR = REPO_ROOT / "manifests"
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
        
        sync_waves[int(sync_wave)].append(app_name)
    
    return dict(sorted(sync_waves.items()))


def get_component_versions():
    """Extract component versions from ArgoCD Applications.
    Supports both Helm charts and direct manifest deployments.
    """
    versions = {}
    base_dir = REPO_ROOT / "base"

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

        chart = source.get('chart', '')

        # Case 1: Helm Chart
        if chart:
            chart_version = source.get('targetRevision', 'latest')

            # Try to get app version from values.yaml (image.tag)
            app_version = None
            values_file = base_dir / app_name / "values.yaml"

            if values_file.exists():
                try:
                    with open(values_file, 'r') as f:
                        values = yaml.safe_load(f)
                        if values and 'image' in values:
                            app_version = values['image'].get('tag')
                except Exception:
                    pass

            # Use app version if available, otherwise use Helm chart version
            versions[app_name] = {
                'chart': chart,
                'version': app_version if app_version else chart_version
            }

        # Case 2: Direct Manifest (no Helm chart)
        else:
            # Extract version from deployment.yaml in manifests directory
            manifest_dir = MANIFESTS_DIR / app_name

            # Try multiple possible deployment file names
            deployment_files = [
                manifest_dir / "deployment.yaml",
                manifest_dir / f"{app_name}-deployment.yaml",
            ]

            deployment_file = None
            for df in deployment_files:
                if df.exists():
                    deployment_file = df
                    break

            # Skip if no deployment file exists (config-only apps)
            if not deployment_file:
                continue

            app_version = None
            try:
                with open(deployment_file, 'r') as f:
                    # Handle multi-document YAML files (separated by ---)
                    docs = list(yaml.safe_load_all(f))

                    # Find the Deployment document
                    deployment = None
                    for doc in docs:
                        if doc and doc.get('kind') == 'Deployment':
                            deployment = doc
                            break

                    if deployment:
                        containers = deployment.get('spec', {}).get('template', {}).get('spec', {}).get('containers', [])
                        if containers:
                            # Get image from first container (skip init containers)
                            image = containers[0].get('image', '')
                            if ':' in image:
                                app_version = image.split(':')[-1]
                            else:
                                app_version = 'latest'  # If no tag specified, assume latest
            except Exception:
                pass

            # Only add if we found a version
            if app_version:
                versions[app_name] = {
                    'chart': app_name,  # Use app name as chart name
                    'version': app_version
                }

    return versions


def get_documentation_links():
    """Extract documentation links from Helm chart repositories and add official docs for custom apps."""
    docs = {}

    # Official documentation URLs for custom deployed apps
    OFFICIAL_DOCS = {
        'home-assistant': 'https://www.home-assistant.io/docs/',
        'homepage': 'https://gethomepage.dev/latest/',
        'uptime-kuma': 'https://github.com/louislam/uptime-kuma/wiki',
        'n8n': 'https://docs.n8n.io/',
        'minio': 'https://min.io/docs/minio/kubernetes/upstream/',
        'teslamate': 'https://docs.teslamate.org/',
        'landing-page': 'https://github.com/nginx/nginx',
        'proxmox-exporter': 'https://github.com/prometheus-pve/prometheus-pve-exporter',
        'unifi-poller': 'https://unpoller.com/',
    }

    # Extract unique charts from applications
    for app_file in APPS_DIR.glob("*.yaml"):
        if app_file.name == "kustomization.yaml":
            continue

        try:
            with open(app_file, 'r') as f:
                app = yaml.safe_load(f)

            if not app or app.get('kind') != 'Application':
                continue

            app_name = app['metadata']['name']
            spec = app['spec']
            sources = spec.get('sources', [spec.get('source')] if 'source' in spec else [])

            helm_chart_found = False
            for source in sources:
                if not source:
                    continue

                repo_url = source.get('repoURL', '')
                chart = source.get('chart', '')

                if chart and repo_url and not repo_url.startswith('https://github.com/Nebu2k'):
                    # Use chart name as display name, repo URL as link
                    doc_name = chart.replace('-', ' ').title()
                    docs[doc_name] = repo_url
                    helm_chart_found = True

            # For apps without Helm charts, use official documentation if available
            if not helm_chart_found and app_name in OFFICIAL_DOCS:
                doc_name = app_name.replace('-', ' ').title()
                docs[doc_name] = OFFICIAL_DOCS[app_name]

        except Exception as e:
            continue

    # Add always-present core components
    docs['K3s'] = 'https://docs.k3s.io/'

    # Sort by name
    return dict(sorted(docs.items()))


def load_gitignore_patterns():
    """Load and parse .gitignore patterns using pathspec."""
    gitignore_file = REPO_ROOT / ".gitignore"
    
    if not gitignore_file.exists():
        return None
    
    with open(gitignore_file, 'r') as f:
        spec = pathspec.PathSpec.from_lines(pathspec.patterns.GitWildMatchPattern, f)
    
    return spec


def is_ignored(path, gitignore_spec):
    """Check if a file or directory should be ignored using pathspec."""
    if gitignore_spec is None:
        return False
    
    try:
        rel_path = path.relative_to(REPO_ROOT)
    except ValueError:
        return False
    
    return gitignore_spec.match_file(rel_path)


def generate_tree_fallback():
    """Generate tree structure manually if tree command not available."""
    lines = ["homelab/"]
    
    # Load gitignore spec
    gitignore_spec = load_gitignore_patterns()
    
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
    
    # Manifests directory
    lines.append("└── manifests/")
    manifest_dirs = sorted([d for d in (REPO_ROOT / "manifests").iterdir() 
                          if d.is_dir() and not d.name.startswith('.') and not is_ignored(d, gitignore_spec)])
    
    for i, manifest_dir in enumerate(manifest_dirs):
        is_last_dir = i == len(manifest_dirs) - 1
        dir_prefix = "    └── " if is_last_dir else "    ├── "
        lines.append(f"{dir_prefix}{manifest_dir.name}/")
        
        # Add files in manifest - filter using gitignore spec
        all_files = sorted([f for f in manifest_dir.glob("*.yaml*") 
                          if not f.name.startswith('.') and not is_ignored(f, gitignore_spec)])
        # Additional filter: exclude unsealed.yaml files that don't have .example extension
        manifest_files = [f for f in all_files 
                         if not (f.name.endswith('-unsealed.yaml') and not f.name.endswith('.example'))]
        
        for j, manifest_file in enumerate(manifest_files):
            is_last_file = j == len(manifest_files) - 1
            if is_last_dir:
                file_prefix = "        └── " if is_last_file else "        ├── "
            else:
                file_prefix = "    │   └── " if is_last_file else "    │   ├── "
            
            lines.append(f"{file_prefix}{manifest_file.name}")
    
    return "\n".join(lines)


def get_homepage_widget_secrets():
    """
    Find all *-unsealed.yaml.example files in homepage manifests
    and generate seal commands for them.
    Returns list of dictionaries with secret metadata.
    """
    homepage_dir = MANIFESTS_DIR / "homepage"
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
    repo_structure = generate_tree_fallback()
    
    print("  🔐 Extracting Homepage widget secrets...")
    homepage_secrets = get_homepage_widget_secrets()
    print(f"      Found {len(homepage_secrets)} secrets to automate")
    for sec in homepage_secrets:
        print(f"        - {sec['base_name']}")
    
    print("  📚 Extracting documentation links...")
    documentation_links = get_documentation_links()
    print(f"      Found {len(documentation_links)} documentation sources")
    
    # Prepare template data
    data = {
        'sync_waves': sync_waves,
        'versions': versions,
        'repo_structure': repo_structure,
        'homepage_secrets': homepage_secrets,
        'documentation_links': documentation_links
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
