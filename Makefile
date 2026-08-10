.PHONY: docs help

# The single entry point for the README generation. The pre-commit hook and
# .github/workflows/docs.yml both call this target so local runs and CI do
# exactly the same thing.
#
# Plain python3 rather than a local conda environment, which a CI runner does
# not have; the three dependencies in docs-generator/requirements.txt suffice.
PYTHON ?= python3

help:
	@echo "Available targets:"
	@echo "  make docs        - Generate README.md from template"

# The script prints progress and result itself, hence no echo here.
docs:
	@$(PYTHON) docs-generator/generate_readme.py

