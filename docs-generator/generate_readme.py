#!/usr/bin/env python3
"""
README.md Generator for Kubernetes Homelab
Automatically extracts data from repository and renders README from template.
"""

import yaml
from pathlib import Path
from jinja2 import Environment, FileSystemLoader
from collections import defaultdict

# Repository root
REPO_ROOT = Path(__file__).parent.parent
APPS_DIR = REPO_ROOT / "apps"
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
        
        # Determine component purpose
        purpose = get_component_purpose(app_name)
        
        sync_waves[int(sync_wave)].append({
            'name': app_name,
            'purpose': purpose
        })
    
    return dict(sorted(sync_waves.items()))


def get_component_purpose(name):
    """Automatically determine component purpose from ArgoCD Application spec."""
    app_file = APPS_DIR / f"{name}.yaml"
    
    if not app_file.exists():
        return name.replace('-', ' ').title()
    
    try:
        with open(app_file, 'r') as f:
            app = yaml.safe_load(f)
            
        if not app or app.get('kind') != 'Application':
            return name.replace('-', ' ').title()
        
        spec = app['spec']
        
        # Get source(s)
        sources = spec.get('sources', [spec.get('source')] if 'source' in spec else [])
        
        # Find the main source (either chart or path)
        chart_source = None
        path_source = None
        
        for source in sources:
            if not source:
                continue
            if 'chart' in source:
                chart_source = source
            elif 'path' in source:
                path_source = source
        
        # If it's a Helm chart, derive purpose from chart name
        if chart_source:
            chart_name = chart_source.get('chart', '')
            return get_chart_purpose(chart_name, name)
        
        # If it's a path-based config, analyze the overlay directory
        elif path_source:
            overlay_path = Path(REPO_ROOT / path_source['path'])
            return get_overlay_purpose(overlay_path, name)
        
        return name.replace('-', ' ').title()
        
    except Exception as e:
        # Fallback to formatted name
        return name.replace('-', ' ').title()


def get_chart_purpose(chart_name, app_name):
    """Derive purpose from Helm chart name - using generic chart name formatting."""
    # Simply format the chart name nicely
    # The actual purpose will be clear from the chart name itself
    return chart_name.replace('-', ' ').title()


def get_overlay_purpose(overlay_path, app_name):
    """Analyze overlay directory to determine purpose."""
    if not overlay_path.exists():
        return app_name.replace('-', ' ').title()
    
    # Check what types of resources are in the overlay
    resource_types = set()
    
    try:
        for yaml_file in overlay_path.glob('*.yaml'):
            if yaml_file.name == 'kustomization.yaml':
                continue
                
            with open(yaml_file, 'r') as f:
                content = f.read()
                # Parse all documents in the file
                for doc in yaml.safe_load_all(content):
                    if doc and 'kind' in doc:
                        resource_types.add(doc['kind'])
        
        # Determine purpose based on resource types
        if 'Ingress' in resource_types:
            if 'ConfigMap' in resource_types or 'Secret' in resource_types:
                return 'Ingress & configuration'
            return 'Ingress configuration'
        
        if 'ClusterIssuer' in resource_types or 'Issuer' in resource_types:
            return 'Certificate issuers'
        
        if 'IPAddressPool' in resource_types:
            return 'IP address pool'
        
        if 'ConfigMap' in resource_types and 'Job' in resource_types:
            return 'Jobs & configuration'
        
        if 'ConfigMap' in resource_types:
            if 'coredns' in app_name.lower():
                return 'DNS forwarding config'
            return 'Configuration'
        
        if 'CronJob' in resource_types or 'Job' in resource_types:
            return 'Automated jobs'
        
        if 'Secret' in resource_types:
            return 'Secrets'
        
        # Fallback based on resource types
        if resource_types:
            return ', '.join(sorted(resource_types))
        
    except Exception as e:
        pass
    
    return app_name.replace('-', ' ').title()


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
            
        # Get version from targetRevision
        version = source.get('targetRevision', 'latest')
        chart = source.get('chart', '')
        
        if chart:
            versions[app_name] = {
                'chart': chart,
                'version': version
            }
    
    return versions


def get_documentation_links():
    """Extract documentation links from Helm chart repositories - fully automated."""
    docs = {}
    
    # Extract unique charts from applications
    for app_file in APPS_DIR.glob("*.yaml"):
        if app_file.name == "kustomization.yaml":
            continue
            
        try:
            with open(app_file, 'r') as f:
                app = yaml.safe_load(f)
                
            if not app or app.get('kind') != 'Application':
                continue
                
            spec = app['spec']
            sources = spec.get('sources', [spec.get('source')] if 'source' in spec else [])
            
            for source in sources:
                if not source:
                    continue
                    
                repo_url = source.get('repoURL', '')
                chart = source.get('chart', '')
                
                if chart and repo_url and not repo_url.startswith('https://github.com/Nebu2k'):
                    # Use chart name as display name, repo URL as link
                    doc_name = chart.replace('-', ' ').title()
                    docs[doc_name] = repo_url
                    
        except Exception as e:
            continue
    
    # Add always-present core components
    docs['K3s'] = 'https://docs.k3s.io/'
    
    # Sort by name
    return dict(sorted(docs.items()))


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
            
            lines.append(f"{file_prefix}{overlay_file.name}")
    
    return "\n".join(lines)


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
