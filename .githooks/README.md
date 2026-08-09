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

Regenerates `README.md` on **every** commit. The file is generated from:

- ArgoCD Application manifests (`apps/*.yaml`)
- Helm values files (`manifests/*/values.yaml`)
- Homepage widget example files (`manifests/homepage/*-unsealed.yaml.example`)
- README template (`docs-generator/templates/README.md.j2`)
- Generator script (`docs-generator/generate_readme.py`)

**How it works:**

1. Checks that `python3` has `pyyaml`, `jinja2` and `pathspec`
2. Runs `make docs`, the same entry point the CI uses
3. Auto-stages `README.md` if it changed
4. Continues with the commit

**Bypass hook temporarily:**

```bash
git commit --no-verify
```

## Relationship to CI

`.github/workflows/docs.yml` regenerates the README after every push to `main`
and commits it if it differs. That workflow, not this hook, is the last
instance: it also covers Renovate PRs, which are merged on GitHub where no
local hook runs.

The hook still earns its keep. As long as it runs, the README is already
correct in your own commit and CI has nothing to push. Without it, every local
commit would be followed by a bot commit, forcing a rebase before your next
push.

Both call `make docs`, so they cannot drift apart.

## Requirements

A `python3` with the packages in `docs-generator/requirements.txt`:

```bash
python3 -m pip install -r docs-generator/requirements.txt
```

If they are missing, the hook skips generation with a warning instead of
failing the commit. CI regenerates the README after the push anyway.

Use a different interpreter with `PYTHON=/path/to/python git commit ...`.

## Troubleshooting

### "README-Generator übersprungen"

The interpreter is missing dependencies. Install them as shown above, or ignore
it and let CI handle the README.

### Hook not running

Ensure hooks are installed:

```bash
git config core.hooksPath
# Should output: .githooks
```

If not, run `.githooks/install.sh` again.
