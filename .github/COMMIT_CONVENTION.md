# Commit Message Convention

Dieses Projekt verwendet [Conventional Commits](https://www.conventionalcommits.org/)
als Lesehilfe für die git-History. Es gibt keine Versionierung, keine Tags und
keinen generierten Changelog: die History ist die Änderungshistorie. Das Cluster
deployt `HEAD`, ein Rollback läuft über `git revert`.

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

Subject auf Deutsch, im Imperativ oder als knappe Zustandsbeschreibung.

## Types

- **feat**: Neue Funktion oder neuer Dienst
- **fix**: Etwas war kaputt und ist es jetzt nicht mehr
- **perf**: Performance-Verbesserung
- **docs**, **style**, **refactor**, **test**, **build**, **ci**, **chore**: der Rest

Für Breaking Changes ein `!` nach dem Type (`feat(metallb)!: ...`) oder
`BREAKING CHANGE:` im Footer. Beides ist reine Markierung für den Leser.

## Scope (optional)

Der Scope gibt an, welcher Teil des Projekts betroffen ist:

- `traefik`, `cert-manager`, `argocd`, `metallb`, etc. (Komponenten)
- `apps`, `overlays`, `scripts` (Verzeichnisse)
- `docs`, `ci`, `deps` (Kategorien)

Renovate setzt `fix(deps)` für clusterrelevante Updates und `chore(ci)` für
Workflow-Actions, siehe `renovate.json5`.

## Body

Hier gehört hin, was nicht in die Dateien gehört: Begründung, verworfene
Alternativen, Messwerte, Entstehungsgeschichte. Die Manifeste beschreiben den
Ist-Zustand, der Commit beschreibt den Weg dahin.

## Beispiele

```
feat(traefik): Rate-Limiting-Middleware für alle Ingress-Routen

fix(cert-manager): DNS-01-Timeout von 60s auf 300s

docs(readme): Installationsschritte aktualisiert

chore(deps): ArgoCD auf v2.10.0
```
