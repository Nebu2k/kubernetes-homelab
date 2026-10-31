.PHONY: docs help talos-config

# Process substitution in talos-config keeps the decrypted secrets off disk.
SHELL := /bin/bash

# The single entry point for the README generation. .github/workflows/docs.yml
# calls this target, so a local run does exactly what CI does.
#
# Plain python3 rather than a local conda environment, which a CI runner does
# not have; the three dependencies in docs-generator/requirements.txt suffice.
PYTHON ?= python3

# Talos machine configs, built with talosctl alone: "gen config" renders the
# shared base from talos/patches/all/ and talos/patches/controlplane/, then
# "machineconfig patch" lays talos/patches/nodes/<node>.yaml on top. Output goes
# to talos/clusterconfig/ (gitignored, it carries the CAs in plaintext).
#
# TALOS_CONTRACT is the config format, not the Talos version a node runs: that
# is the tag of machine.install.image in each node patch. It stays at v1.13
# while the kubelet extraMounts in talos/patches/all/kubelet.yaml have no 1.14
# counterpart.
TALOS_CONTRACT := v1.13
# renovate: datasource=github-releases depName=kubernetes/kubernetes
KUBERNETES_VERSION := v1.36.6
TALOS_NODES := talos-cp-1 prodesk raspi5
TALOS_ENDPOINTS := 192.168.2.20 192.168.2.22 192.168.2.23
TALOS_OUT := talos/clusterconfig

# Without it sops looks under ~/Library/Application Support on macOS and only
# reports "0 successful groups required, got 0".
export SOPS_AGE_KEY_FILE ?= $(HOME)/.config/sops/age/keys.txt

help:
	@echo "Available targets:"
	@echo "  make docs          - Generate README.md from template"
	@echo "  make talos-config  - Generate the Talos machine configs into $(TALOS_OUT)/"

# The script prints progress and result itself, hence no echo here.
docs:
	@$(PYTHON) docs-generator/generate_readme.py

# The install disk is set per node, so the base gets none instead of the
# /dev/sda default, which would sit next to prodesk's diskSelector.
talos-config:
	@mkdir -p $(TALOS_OUT)
	@talosctl gen config homelab https://192.168.2.29:6443 \
		--with-secrets <(sops -d talos/secrets.sops.yaml) \
		--talos-version $(TALOS_CONTRACT) \
		--kubernetes-version $(KUBERNETES_VERSION:v%=%) \
		--install-disk "" \
		--with-docs=false --with-examples=false \
		$(foreach p,$(sort $(wildcard talos/patches/all/*.yaml)),--config-patch @$(p)) \
		$(foreach p,$(sort $(wildcard talos/patches/controlplane/*.yaml)),--config-patch-control-plane @$(p)) \
		--output-types controlplane,talosconfig \
		--output $(TALOS_OUT) --force
	@for node in $(TALOS_NODES); do \
		talosctl machineconfig patch $(TALOS_OUT)/controlplane.yaml \
			--patch @talos/patches/nodes/$$node.yaml \
			--output $(TALOS_OUT)/homelab-$$node.yaml || exit 1; \
		talosctl validate --config $(TALOS_OUT)/homelab-$$node.yaml --mode metal --strict || exit 1; \
	done
	@rm $(TALOS_OUT)/controlplane.yaml
	@talosctl --talosconfig $(TALOS_OUT)/talosconfig config endpoint $(TALOS_ENDPOINTS)
	@talosctl --talosconfig $(TALOS_OUT)/talosconfig config node $(TALOS_ENDPOINTS)
	@echo "Generated $(TALOS_NODES:%=$(TALOS_OUT)/homelab-%.yaml) and $(TALOS_OUT)/talosconfig"
