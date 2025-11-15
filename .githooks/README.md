# Git Hooks

This directory contains Git hooks that automate tasks in this repository.

## Installation

After cloning the repository, run:

```bash
.githooks/install.sh
```

This configures Git to use hooks from this directory instead of `.git/hooks/`.

## Available Hooks

### pre-commit

Automatically regenerates `README.md` when relevant files change:

- ArgoCD Application manifests (`apps/*.yaml`)
- Helm values files (`base/*/values.yaml`)
- Homepage widget example files (`overlays/production/homepage/*-unsealed.yaml.example`)
- README template (`docs-generator/templates/README.md.j2`)
- Generator script (`docs-generator/generate_readme.py`)

**How it works:**

1. Detects if trigger files are staged for commit
2. Runs `make docs` to regenerate README
3. Auto-stages the updated README if changed
4. Continues with the commit

**Bypass hook temporarily:**

```bash
git commit --no-verify
```

## Requirements

- Conda environment `jinja2` with dependencies installed
- See `docs-generator/requirements.txt`

## Troubleshooting

**Error: "Conda environment 'jinja2' not found"**

Create the environment:

```bash
conda create -n jinja2 python=3.11 -y
conda run -n jinja2 pip install -r docs-generator/requirements.txt
```

**Hook not running:**

Ensure hooks are installed:

```bash
git config core.hooksPath
# Should output: .githooks
```

If not, run `.githooks/install.sh` again.
