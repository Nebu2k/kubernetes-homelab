.PHONY: docs help

help:
	@echo "Available targets:"
	@echo "  make docs    - Generate README.md from template"

docs:
	@echo "🔄 Generating README.md..."
	@cd docs-generator && conda run -n jinja2 python generate_readme.py
	@echo "✅ Done! README.md updated."
