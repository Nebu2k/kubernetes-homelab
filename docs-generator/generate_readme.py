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

# Spellings that neither title case nor the acronym list get right
SPECIAL_CASES = {
    'metallb': 'MetalLB',
    'argocd': 'ArgoCD',
    'teslamate': 'TeslaMate',
    'piaware': 'PiAware',
    'readsb': 'readsb',
    'unifi': 'UniFi',
    'ngx': 'ngx',
    'rpi5': 'RPi5',
    'etcd': 'etcd',
    'talhelper': 'talhelper',
    # Full names that are spelled lowercase upstream
    'kube-prometheus-stack': 'kube-prometheus-stack',
    'paperless-ngx': 'paperless-ngx',
    'csi-driver-smb': 'csi-driver-smb',
}

# Common acronyms that should stay uppercase
ACRONYMS = {'nfs', 's3', 'api', 'dns', 'tls', 'ssl', 'http', 'https',
            'k8s', 'cpu', 'ram', 'gpu', 'io', 'ip', 'vpn', 'ssh',
            'csi', 'smb', 'cifs', 'fr24', 'ripe', 'pve'}


def get_sync_waves():
    """Extract sync-wave annotations from ArgoCD Applications."""
    sync_waves = defaultdict(list)

    # sorted(), because Path.glob() passes the filesystem's order through.
    # Without it macOS and the CI runner produce different READMEs, and the
    # local hook and the docs workflow overwrite each other in turn.
    for app_file in sorted(APPS_DIR.glob("*.yaml")):
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
    
    # Waves by number, components within a wave alphabetically.
    return {wave: sorted(apps) for wave, apps in sorted(sync_waves.items())}


def get_component_versions():
    """Extract component versions from ArgoCD Applications.
    Supports both Helm charts and direct manifest deployments.
    """
    versions = {}
    base_dir = REPO_ROOT / "base"

    # sorted() determines the row order of the version table here, see
    # get_sync_waves(). Without it the order is arbitrary and drifts between
    # the local hook and CI.
    for app_file in sorted(APPS_DIR.glob("*.yaml")):
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
                'display': smart_title_case(app_name),
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
                    'display': smart_title_case(app_name),
                    'version': app_version
                }

    return versions


def smart_title_case(text):
    """Convert text to title case while preserving known acronyms in uppercase."""
    if text.lower() in SPECIAL_CASES:
        return SPECIAL_CASES[text.lower()]

    words = text.replace('-', ' ').split()
    result = []
    
    for word in words:
        word_lower = word.lower()
        if word_lower in SPECIAL_CASES:
            result.append(SPECIAL_CASES[word_lower])
        elif word_lower in ACRONYMS:
            result.append(word.upper())
        else:
            result.append(word.capitalize())
    
    return ' '.join(result)


def get_documentation_links():
    """Extract documentation links from Helm chart repositories and add official docs for custom apps."""
    docs = {}

    # Official documentation URLs for custom deployed apps
    OFFICIAL_DOCS = {
        'blocky': 'https://0xerr0r.github.io/blocky/latest/',
        'home-assistant': 'https://www.home-assistant.io/docs/',
        'homepage': 'https://gethomepage.dev/latest/',
        'gatus': 'https://github.com/TwiN/gatus',
        'teslamate': 'https://docs.teslamate.org/',
        'proxmox-exporter': 'https://github.com/prometheus-pve/prometheus-pve-exporter',
        'unifi-poller': 'https://unpoller.com/',
    }

    # Extract unique charts from applications
    # sorted() for the same reason, see get_sync_waves().
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
            sources = spec.get('sources', [spec.get('source')] if 'source' in spec else [])

            helm_chart_found = False
            for source in sources:
                if not source:
                    continue

                repo_url = source.get('repoURL', '')
                chart = source.get('chart', '')

                if chart and repo_url and not repo_url.startswith('https://github.com/Nebu2k'):
                    # Use chart name as display name, repo URL as link
                    doc_name = smart_title_case(chart)
                    docs[doc_name] = repo_url
                    helm_chart_found = True

            # For apps without Helm charts, use official documentation if available
            if not helm_chart_found and app_name in OFFICIAL_DOCS:
                doc_name = smart_title_case(app_name)
                docs[doc_name] = OFFICIAL_DOCS[app_name]

        except Exception as e:
            continue

    # Add always-present core components
    docs['Talos Linux'] = 'https://www.talos.dev/latest/'
    docs['talhelper'] = 'https://budimanjojo.github.io/talhelper/'

    # Sort by name (case-insensitive)
    return dict(sorted(docs.items(), key=lambda item: item[0].lower()))


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
    """Generate the repository structure, directories only.

    Listing every single manifest file blew the tree up to a few hundred lines
    that nobody reads and that changes on every commit. One line per component
    is enough to find one's way around; what is inside a component directory is
    obvious once you are in it.
    """
    gitignore_spec = load_gitignore_patterns()

    app_count = len([f for f in (REPO_ROOT / "apps").glob("*.yaml")
                     if f.name != "kustomization.yaml"])

    lines = [
        "kubernetes-homelab/",
        "├── bootstrap/root-app.yaml    # App-of-Apps, the only thing applied by hand",
        f"├── apps/                      # {app_count} ArgoCD Applications, one per component (waves above)",
        "├── manifests/                 # what those Applications point at",
    ]

    manifest_dirs = sorted([d for d in MANIFESTS_DIR.iterdir()
                            if d.is_dir() and not d.name.startswith('.')
                            and not is_ignored(d, gitignore_spec)])

    for i, manifest_dir in enumerate(manifest_dirs):
        is_last = i == len(manifest_dirs) - 1
        lines.append(f"│   {'└──' if is_last else '├──'} {manifest_dir.name}/")

    # The Talos layer. Not GitOps: talconfig.yaml is the source talhelper
    # generates the machine configs from, and those sit next to it encrypted.
    lines += [
        "├── talos/                     # machine configs (talhelper), see talos/README.md",
        "├── docs-generator/            # renders this README from templates/README.md.j2",
        "└── reseal-all-secrets.sh      # reseals every *-unsealed.yaml under manifests/",
    ]

    return "\n".join(lines)


def get_cluster_versions():
    """Read Talos and Kubernetes version from talos/talconfig.yaml.

    Hardcoding them in the template means they survive every Talos upgrade
    untouched and quietly turn into a lie.
    """
    talconfig = REPO_ROOT / "talos" / "talconfig.yaml"

    if not talconfig.exists():
        return {}

    with open(talconfig, 'r') as f:
        config = yaml.safe_load(f)

    return {
        'talos': config.get('talosVersion', ''),
        'kubernetes': config.get('kubernetesVersion', ''),
    }


def get_sealed_secrets():
    """
    Find every *-unsealed.yaml.example across all manifest directories and
    derive the seal command for it.

    The .example files are the single source of truth here: a new secret shows
    up in the README as soon as its template is committed, and a removed one
    disappears with it. Nothing about secrets is hardcoded in the template, so
    the generated README cannot keep advertising a backup target that has
    already moved.

    Returns a list of dicts, sorted by component then secret name.
    """
    secrets = []

    if not MANIFESTS_DIR.exists():
        return secrets

    for example_file in sorted(MANIFESTS_DIR.glob("*/*-unsealed.yaml.example")):
        component = example_file.parent.name
        # "unifi-token-unsealed.yaml.example" -> "unifi-token"
        base_name = example_file.name.replace("-unsealed.yaml.example", "")

        secrets.append({
            'component': component,
            'example_file': example_file.name,
            'unsealed_file': f"{base_name}-unsealed.yaml",
            'sealed_file': f"{base_name}-sealed.yaml",
            'example_path': f"manifests/{component}/{example_file.name}",
            'unsealed_path': f"manifests/{component}/{base_name}-unsealed.yaml",
            'sealed_path': f"manifests/{component}/{base_name}-sealed.yaml",
            'base_name': base_name,
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
    
    print("  🔐 Extracting sealed secrets...")
    sealed_secrets = get_sealed_secrets()
    # Homepage widgets are documented separately: they can only be sealed once
    # Grafana and friends are running and their tokens exist.
    homepage_secrets = [s for s in sealed_secrets if s['component'] == 'homepage']
    bootstrap_secrets = [s for s in sealed_secrets if s['component'] != 'homepage']
    print(f"      Found {len(sealed_secrets)} secrets "
          f"({len(bootstrap_secrets)} bootstrap, {len(homepage_secrets)} homepage)")

    print("  📚 Extracting documentation links...")
    documentation_links = get_documentation_links()
    print(f"      Found {len(documentation_links)} documentation sources")

    cluster = get_cluster_versions()

    # Prepare template data
    data = {
        'sync_waves': sync_waves,
        'versions': versions,
        'cluster': cluster,
        'repo_structure': repo_structure,
        'sealed_secrets': sealed_secrets,
        'bootstrap_secrets': bootstrap_secrets,
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
