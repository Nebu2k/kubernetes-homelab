# Commit Message Convention

Dieses Projekt verwendet [Conventional Commits](https://www.conventionalcommits.org/) für automatische semantische Versionierung.

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Types

- **feat**: Neue Funktion (→ minor version bump, z.B. 1.0.0 → 1.1.0)
- **fix**: Bug Fix (→ patch version bump, z.B. 1.0.0 → 1.0.1)
- **perf**: Performance Verbesserung (→ patch)
- **docs**: Dokumentationsänderung (→ patch)
- **style**: Code-Formatierung, keine funktionale Änderung (→ patch)
- **refactor**: Code-Refactoring (→ patch)
- **test**: Tests hinzugefügt/geändert (→ patch)
- **build**: Build-System Änderungen (→ patch)
- **ci**: CI/CD Konfigurationsänderungen (→ patch)
- **chore**: Sonstige Änderungen, z.B. Dependencies (→ kein Release)

## Breaking Changes

Für **major version bumps** (z.B. 1.0.0 → 2.0.0):

1. Füge `BREAKING CHANGE:` im Footer hinzu:
   ```
   feat(api): neue API-Struktur

   BREAKING CHANGE: Die alte API wurde entfernt
   ```

2. Oder verwende `!` nach dem Type:
   ```
   feat!: neue API-Struktur
   ```

## Beispiele

### Minor Release (neue Features)
```
feat(traefik): Add custom middleware for rate limiting

Implementiert neue Rate-Limiting Middleware für alle Ingress-Routen.
```

### Patch Release (Bug Fixes)
```
fix(cert-manager): Fix DNS-01 challenge timeout

Erhöht Timeout von 60s auf 300s für Cloudflare DNS-01 Challenges.
```

### Patch Release (Dokumentation)
```
docs(readme): Update installation instructions
```

### Major Release (Breaking Change)
```
feat(metallb)!: Migrate to L2 advertisement

BREAKING CHANGE: BGP configuration has been removed. 
All services now use L2 advertisement. 
Update your metallb-config accordingly.
```

### Kein Release
```
chore(deps): Update ArgoCD to v2.10.0
```

## Scope (optional)

Der Scope gibt an, welcher Teil des Projekts betroffen ist:
- `traefik`, `cert-manager`, `argocd`, `metallb`, etc. (Komponenten)
- `apps`, `overlays`, `scripts` (Verzeichnisse)
- `docs`, `ci`, `deps` (Kategorien)

## Multi-Commit Releases

Wenn mehrere Commits gepusht werden:
- Der höchste Bump-Type gewinnt (major > minor > patch)
- Alle Commits werden in den Release Notes aufgelistet
- CHANGELOG.md wird automatisch aktualisiert

## Testen ohne Release

Commits auf anderen Branches als `main` erstellen kein Release.
```bash
git checkout -b feature/test-changes
git commit -m "feat: test feature"
git push origin feature/test-changes
```
