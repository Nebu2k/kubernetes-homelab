.PHONY: docs help

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
	@echo "  make docs    - Generate README.md from template"

# Das Skript gibt selbst Fortschritt und Ergebnis aus, deshalb hier kein echo.
docs:
	@$(PYTHON) docs-generator/generate_readme.py
