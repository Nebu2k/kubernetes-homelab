.PHONY: docs help vendor-suc

# Einziger Einstiegspunkt fuer die README-Generierung. Der pre-commit-Hook und
# .github/workflows/docs.yml rufen beide dieses Target auf, damit lokal und in
# CI garantiert dasselbe passiert.
#
# Frueher stand hier "conda run -n jinja2". Das band die Generierung an eine
# lokale conda-Umgebung, die es auf einem CI-Runner nicht gibt. Die drei
# Abhaengigkeiten aus docs-generator/requirements.txt reichen in jedem python3.
PYTHON ?= python3

help:
	@echo "Available targets:"
	@echo "  make docs        - Generate README.md from template"
	@echo "  make vendor-suc  - system-upgrade-controller-Manifeste neu ziehen"

# Das Skript gibt selbst Fortschritt und Ergebnis aus, deshalb hier kein echo.
docs:
	@$(PYTHON) docs-generator/generate_readme.py

# --- system-upgrade-controller ---------------------------------------------
# crd.yaml und deployment.yaml sind Upstream-Releaseartefakte. Renovate pflegt
# nur den Image-Tag im Deployment, die CRD wuerde ohne dieses Target still
# zurueckbleiben. Deshalb ist der Image-Tag die einzige Quelle der Wahrheit und
# die Version wird daraus abgeleitet, statt sie hier ein zweites Mal zu pflegen.
SUC_DIR := manifests/system-upgrade-controller
SUC_VERSION ?= $(shell sed -n 's|.*image: rancher/system-upgrade-controller:\(v[0-9.]*\).*|\1|p' $(SUC_DIR)/deployment.yaml | head -1)
SUC_URL := https://github.com/rancher/system-upgrade-controller/releases/download/$(SUC_VERSION)

vendor-suc:
	@test -n "$(SUC_VERSION)" || { echo "Version nicht aus $(SUC_DIR)/deployment.yaml ableitbar"; exit 1; }
	@echo "Ziehe system-upgrade-controller $(SUC_VERSION)"
	@curl -fsSL -o $(SUC_DIR)/crd.yaml $(SUC_URL)/crd.yaml
	@curl -fsSL -o $(SUC_DIR)/deployment.yaml $(SUC_URL)/system-upgrade-controller.yaml
	@echo "Fertig. Diff pruefen: git diff $(SUC_DIR)"
