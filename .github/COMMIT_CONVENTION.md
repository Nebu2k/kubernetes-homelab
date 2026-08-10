# Commit Message Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/)
as a reading aid for the git history. There is no versioning, no tags and no
generated changelog: the history *is* the change log. The cluster deploys
`HEAD`, a rollback is a `git revert`.

## Format

```text
<type>(<scope>): <subject>

<body>

<footer>
```

Everything in English, including the subject. Imperative mood or a short
statement of the resulting state.

## Types

- **feat**: New capability or new service
- **fix**: Something was broken and is not anymore
- **perf**: Performance improvement
- **docs**, **style**, **refactor**, **test**, **build**, **ci**, **chore**: the rest

For breaking changes add a `!` after the type (`feat(metallb)!: ...`) or
`BREAKING CHANGE:` in the footer. Both are pure markers for the reader.

## Scope (optional)

The scope names the part of the project a change touches:

- `traefik`, `cert-manager`, `argocd`, `metallb`, etc. (components)
- `apps`, `overlays`, `scripts` (directories)
- `docs`, `ci`, `deps` (categories)

Renovate uses `fix(deps)` for cluster-relevant updates and `chore(ci)` for
workflow actions, see `renovate.json5`.

## Body

This is where everything goes that does not belong in the files themselves:
rationale, rejected alternatives, measurements, how it came about. The
manifests describe the current state, the commit describes the way there.

## Examples

```text
feat(traefik): rate limiting middleware for all ingress routes

fix(cert-manager): raise DNS-01 timeout from 60s to 300s

docs(readme): update installation steps

chore(deps): ArgoCD to v2.10.0
```
