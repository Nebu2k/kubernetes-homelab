## [2.10.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.9.0...v2.10.0) (2026-01-08)


### ✨ Features

* **deployment:** add init container to disable IPv6 in uptime-kuma deployment ([6054e4b](https://github.com/Nebu2k/kubernetes-homelab/commit/6054e4b2c714feef93c027e68e1704a691ca02d4))

## [2.9.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.8.9...v2.9.0) (2026-01-08)


### ✨ Features

* **manifests:** update kubeseal command comments in unsealed YAML examples ([9256d3d](https://github.com/Nebu2k/kubernetes-homelab/commit/9256d3de4a502a899fcde3305a8950d381ba236c))

## [2.8.9](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.8.8...v2.8.9) (2026-01-08)


### 🐛 Bug Fixes

* **ingress:** update TLS configuration to use secretName for Portainer, Dreambox, Proxmox, and UniFi IngressRoutes ([7667f3a](https://github.com/Nebu2k/kubernetes-homelab/commit/7667f3ae81dca654db575601df7bcd70fc714270))

## [2.8.8](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.8.7...v2.8.8) (2026-01-08)


### 🐛 Bug Fixes

* **ingress:** set TLS configurations for Portainer, Dreambox, Proxmox, and UniFi IngressRoutes ([d4c490a](https://github.com/Nebu2k/kubernetes-homelab/commit/d4c490a15aae5713f023e57a615c5e507f612974))

## [2.8.7](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.8.6...v2.8.7) (2026-01-08)


### 🐛 Bug Fixes

* **ingress:** optimize jq queries for fetching hostnames from Ingresses and IngressRoutes ([b380798](https://github.com/Nebu2k/kubernetes-homelab/commit/b380798887ecc93a6b61b2253bcce7056dedf7f2))

## [2.8.6](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.8.5...v2.8.6) (2026-01-08)


### 🐛 Bug Fixes

* **ingress:** update scripts to fetch hostnames from Kubernetes Ingresses and Traefik IngressRoutes ([7d5d2e4](https://github.com/Nebu2k/kubernetes-homelab/commit/7d5d2e450b70030277ab305a5ec7674c1b74d6e0))

## [2.8.5](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.8.4...v2.8.5) (2026-01-08)


### 🐛 Bug Fixes

* **ingress:** remove standard Ingress configuration for Portainer ([6a49448](https://github.com/Nebu2k/kubernetes-homelab/commit/6a494484c2d2ee85e427ac3feadf1774ddcc8f7d))

## [2.8.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.8.3...v2.8.4) (2026-01-08)


### 🐛 Bug Fixes

* **ingress:** remove standard Ingress configuration for Proxmox and UniFi ([0e9fdee](https://github.com/Nebu2k/kubernetes-homelab/commit/0e9fdeefb8c8d0591728c7aca80633fd92ed949d))

## [2.8.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.8.2...v2.8.3) (2026-01-08)


### ♻️ Code Refactoring

* **ingress:** remove standard Ingress configuration for Dreambox ([f86f22b](https://github.com/Nebu2k/kubernetes-homelab/commit/f86f22b83a0c903da40430fa23fd0138e418c668))

## [2.8.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.8.1...v2.8.2) (2026-01-08)


### 🐛 Bug Fixes

* **ingress:** add Traefik annotations for HTTPS and insecure transport in Dreambox, Proxmox, and UniFi configurations ([de32319](https://github.com/Nebu2k/kubernetes-homelab/commit/de32319990377debd72679de4ba8b4574dfea5a2))

## [2.8.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.8.0...v2.8.1) (2026-01-08)


### 🐛 Bug Fixes

* **ingress:** remove secretName for TLS in Portainer, Dreambox, Proxmox, and UniFi configurations ([729a042](https://github.com/Nebu2k/kubernetes-homelab/commit/729a042ffd79c9efa75c396d9acae032bc8d4863))

## [2.8.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.34...v2.8.0) (2026-01-08)


### ✨ Features

* **traefik:** add kustomization.yaml for traefik resources and update application sources ([779014d](https://github.com/Nebu2k/kubernetes-homelab/commit/779014d026ee226aba57341d021c6ed440b56567))


### 🐛 Bug Fixes

* **ingress:** add TLS secret names for Portainer, Dreambox, Proxmox, and UniFi IngressRoutes ([bcb3697](https://github.com/Nebu2k/kubernetes-homelab/commit/bcb3697d3d6e7a68f87e996eca1cfa14ef95f568))
* **ingress:** enable passthrough for TLS in Portainer, Dreambox, Proxmox, and UniFi configurations ([6df307e](https://github.com/Nebu2k/kubernetes-homelab/commit/6df307ee3ad3e6d6b5d49ad2e4d9ed5efac8c924))
* **ingress:** remove secretName from tls configuration for Portainer, Dreambox, Proxmox, and UniFi ([4ecfe9a](https://github.com/Nebu2k/kubernetes-homelab/commit/4ecfe9ab592335c15b5be606e5bc24bd516e7ac2))
* **ingress:** replace passthrough with secretName for TLS in Portainer, Dreambox, Proxmox, and UniFi configurations ([ebfb97b](https://github.com/Nebu2k/kubernetes-homelab/commit/ebfb97b47a22d1b1b3444679cf2081b7b4dfe4db))
* **traefik:** disable cross-namespace access for Kubernetes CRD providers ([b36a8a2](https://github.com/Nebu2k/kubernetes-homelab/commit/b36a8a2923a27f30691c9142a3ee3ce5c40bfa7d))
* **traefik:** enable cross-namespace access for Kubernetes CRD providers ([030e058](https://github.com/Nebu2k/kubernetes-homelab/commit/030e0589490ba7cee595175227a886fa421587fb))


### ♻️ Code Refactoring

* **ingress:** simplify domain fetching by removing Traefik IngressRoutes queries ([f9be0ae](https://github.com/Nebu2k/kubernetes-homelab/commit/f9be0aede5733985397f400b8aeada5d1cce1f50))

## [2.8.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.34...v2.8.0) (2026-01-08)


### ✨ Features

* **traefik:** add kustomization.yaml for traefik resources and update application sources ([779014d](https://github.com/Nebu2k/kubernetes-homelab/commit/779014d026ee226aba57341d021c6ed440b56567))


### 🐛 Bug Fixes

* **ingress:** add TLS secret names for Portainer, Dreambox, Proxmox, and UniFi IngressRoutes ([bcb3697](https://github.com/Nebu2k/kubernetes-homelab/commit/bcb3697d3d6e7a68f87e996eca1cfa14ef95f568))
* **ingress:** enable passthrough for TLS in Portainer, Dreambox, Proxmox, and UniFi configurations ([6df307e](https://github.com/Nebu2k/kubernetes-homelab/commit/6df307ee3ad3e6d6b5d49ad2e4d9ed5efac8c924))
* **ingress:** remove secretName from tls configuration for Portainer, Dreambox, Proxmox, and UniFi ([4ecfe9a](https://github.com/Nebu2k/kubernetes-homelab/commit/4ecfe9ab592335c15b5be606e5bc24bd516e7ac2))
* **traefik:** disable cross-namespace access for Kubernetes CRD providers ([b36a8a2](https://github.com/Nebu2k/kubernetes-homelab/commit/b36a8a2923a27f30691c9142a3ee3ce5c40bfa7d))
* **traefik:** enable cross-namespace access for Kubernetes CRD providers ([030e058](https://github.com/Nebu2k/kubernetes-homelab/commit/030e0589490ba7cee595175227a886fa421587fb))


### ♻️ Code Refactoring

* **ingress:** simplify domain fetching by removing Traefik IngressRoutes queries ([f9be0ae](https://github.com/Nebu2k/kubernetes-homelab/commit/f9be0aede5733985397f400b8aeada5d1cce1f50))

## [2.8.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.34...v2.8.0) (2026-01-08)


### ✨ Features

* **traefik:** add kustomization.yaml for traefik resources and update application sources ([779014d](https://github.com/Nebu2k/kubernetes-homelab/commit/779014d026ee226aba57341d021c6ed440b56567))


### 🐛 Bug Fixes

* **ingress:** add TLS secret names for Portainer, Dreambox, Proxmox, and UniFi IngressRoutes ([bcb3697](https://github.com/Nebu2k/kubernetes-homelab/commit/bcb3697d3d6e7a68f87e996eca1cfa14ef95f568))
* **ingress:** remove secretName from tls configuration for Portainer, Dreambox, Proxmox, and UniFi ([4ecfe9a](https://github.com/Nebu2k/kubernetes-homelab/commit/4ecfe9ab592335c15b5be606e5bc24bd516e7ac2))
* **traefik:** disable cross-namespace access for Kubernetes CRD providers ([b36a8a2](https://github.com/Nebu2k/kubernetes-homelab/commit/b36a8a2923a27f30691c9142a3ee3ce5c40bfa7d))
* **traefik:** enable cross-namespace access for Kubernetes CRD providers ([030e058](https://github.com/Nebu2k/kubernetes-homelab/commit/030e0589490ba7cee595175227a886fa421587fb))


### ♻️ Code Refactoring

* **ingress:** simplify domain fetching by removing Traefik IngressRoutes queries ([f9be0ae](https://github.com/Nebu2k/kubernetes-homelab/commit/f9be0aede5733985397f400b8aeada5d1cce1f50))

## [2.8.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.34...v2.8.0) (2026-01-08)


### ✨ Features

* **traefik:** add kustomization.yaml for traefik resources and update application sources ([779014d](https://github.com/Nebu2k/kubernetes-homelab/commit/779014d026ee226aba57341d021c6ed440b56567))


### 🐛 Bug Fixes

* **ingress:** add TLS secret names for Portainer, Dreambox, Proxmox, and UniFi IngressRoutes ([bcb3697](https://github.com/Nebu2k/kubernetes-homelab/commit/bcb3697d3d6e7a68f87e996eca1cfa14ef95f568))
* **traefik:** disable cross-namespace access for Kubernetes CRD providers ([b36a8a2](https://github.com/Nebu2k/kubernetes-homelab/commit/b36a8a2923a27f30691c9142a3ee3ce5c40bfa7d))
* **traefik:** enable cross-namespace access for Kubernetes CRD providers ([030e058](https://github.com/Nebu2k/kubernetes-homelab/commit/030e0589490ba7cee595175227a886fa421587fb))


### ♻️ Code Refactoring

* **ingress:** simplify domain fetching by removing Traefik IngressRoutes queries ([f9be0ae](https://github.com/Nebu2k/kubernetes-homelab/commit/f9be0aede5733985397f400b8aeada5d1cce1f50))

## [2.8.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.34...v2.8.0) (2026-01-08)


### ✨ Features

* **traefik:** add kustomization.yaml for traefik resources and update application sources ([779014d](https://github.com/Nebu2k/kubernetes-homelab/commit/779014d026ee226aba57341d021c6ed440b56567))


### 🐛 Bug Fixes

* **ingress:** add TLS secret names for Portainer, Dreambox, Proxmox, and UniFi IngressRoutes ([bcb3697](https://github.com/Nebu2k/kubernetes-homelab/commit/bcb3697d3d6e7a68f87e996eca1cfa14ef95f568))
* **traefik:** enable cross-namespace access for Kubernetes CRD providers ([030e058](https://github.com/Nebu2k/kubernetes-homelab/commit/030e0589490ba7cee595175227a886fa421587fb))


### ♻️ Code Refactoring

* **ingress:** simplify domain fetching by removing Traefik IngressRoutes queries ([f9be0ae](https://github.com/Nebu2k/kubernetes-homelab/commit/f9be0aede5733985397f400b8aeada5d1cce1f50))

## [2.8.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.34...v2.8.0) (2026-01-08)


### ✨ Features

* **traefik:** add kustomization.yaml for traefik resources and update application sources ([779014d](https://github.com/Nebu2k/kubernetes-homelab/commit/779014d026ee226aba57341d021c6ed440b56567))


### 🐛 Bug Fixes

* **ingress:** add TLS secret names for Portainer, Dreambox, Proxmox, and UniFi IngressRoutes ([bcb3697](https://github.com/Nebu2k/kubernetes-homelab/commit/bcb3697d3d6e7a68f87e996eca1cfa14ef95f568))


### ♻️ Code Refactoring

* **ingress:** simplify domain fetching by removing Traefik IngressRoutes queries ([f9be0ae](https://github.com/Nebu2k/kubernetes-homelab/commit/f9be0aede5733985397f400b8aeada5d1cce1f50))

## [2.8.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.34...v2.8.0) (2026-01-08)


### ✨ Features

* **traefik:** add kustomization.yaml for traefik resources and update application sources ([779014d](https://github.com/Nebu2k/kubernetes-homelab/commit/779014d026ee226aba57341d021c6ed440b56567))


### 🐛 Bug Fixes

* **ingress:** add TLS secret names for Portainer, Dreambox, Proxmox, and UniFi IngressRoutes ([bcb3697](https://github.com/Nebu2k/kubernetes-homelab/commit/bcb3697d3d6e7a68f87e996eca1cfa14ef95f568))

## [2.8.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.34...v2.8.0) (2026-01-08)


### ✨ Features

* **traefik:** add kustomization.yaml for traefik resources and update application sources ([779014d](https://github.com/Nebu2k/kubernetes-homelab/commit/779014d026ee226aba57341d021c6ed440b56567))

## [2.7.34](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.33...v2.7.34) (2026-01-08)


### 🐛 Bug Fixes

* **ingress:** add IngressRoute and standard Ingress for Portainer, Dreambox, Proxmox, and UniFi with TLS configuration ([0896cb8](https://github.com/Nebu2k/kubernetes-homelab/commit/0896cb88f7c1f51f57a8e1fe1aff5a962c22111a))

## [2.7.33](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.32...v2.7.33) (2026-01-08)


### 🐛 Bug Fixes

* **uptime-kuma:** add NODEJS_IP_FAMILY environment variable ([99bc598](https://github.com/Nebu2k/kubernetes-homelab/commit/99bc5981fbae058822819345e82775d79c2f5eb4))

## [2.7.32](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.31...v2.7.32) (2026-01-08)


### 🐛 Bug Fixes

* **unifi-poller:** add timeout and failureThreshold to liveness and readiness probes ([d9ae723](https://github.com/Nebu2k/kubernetes-homelab/commit/d9ae723cc3b51422abd748825b71a14a69d8857a))

## [2.7.31](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.30...v2.7.31) (2026-01-08)


### 🐛 Bug Fixes

* **prometheus:** remove service labels for Lens auto-detection ([7cfd931](https://github.com/Nebu2k/kubernetes-homelab/commit/7cfd931515efc48f08feee409169f03e2c77f53e))

## [2.7.30](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.29...v2.7.30) (2026-01-07)


### 🐛 Bug Fixes

* **kube-prometheus-stack:** update targetRevision to 80.13.2 ([fc8e79e](https://github.com/Nebu2k/kubernetes-homelab/commit/fc8e79e5f836e1810b111346f783c385b340360a))

## [2.7.29](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.28...v2.7.29) (2026-01-07)


### 🐛 Bug Fixes

* **prometheus:** add service labels for Lens auto-detection ([f4b5f2e](https://github.com/Nebu2k/kubernetes-homelab/commit/f4b5f2e2559b6cb02de08216b2b4ba59d891c7eb))

## [2.7.28](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.27...v2.7.28) (2026-01-07)


### 🐛 Bug Fixes

* **proxmox-exporter:** update sealed secret credentials for Proxmox API ([8c5e93d](https://github.com/Nebu2k/kubernetes-homelab/commit/8c5e93dbb952a03a743107fc5d72c45d1b48c52c))

## [2.7.27](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.26...v2.7.27) (2026-01-07)


### 🐛 Bug Fixes

* **proxmox-exporter:** update sealed secret credentials for Proxmox API ([8b64a11](https://github.com/Nebu2k/kubernetes-homelab/commit/8b64a11487c399d16a5fd3d5d3e2cd1453e84d16))

## [2.7.26](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.25...v2.7.26) (2026-01-07)


### 🐛 Bug Fixes

* **proxmox-exporter:** update container port to 9221 in deployment and service ([fb5df24](https://github.com/Nebu2k/kubernetes-homelab/commit/fb5df24a4563c63b73179720f7aea7d66fbe2246))

## [2.7.25](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.24...v2.7.25) (2026-01-07)


### 🐛 Bug Fixes

* **proxmox-exporter:** update container image to ghcr.io/bigtcze/pve-exporter:1 ([d52b4a2](https://github.com/Nebu2k/kubernetes-homelab/commit/d52b4a21505f740a766dc6628b5e4bc9bc28aeda))

## [2.7.24](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.23...v2.7.24) (2026-01-07)


### 🐛 Bug Fixes

* **proxmox-exporter:** update container image to v1.10.1 ([d5cc771](https://github.com/Nebu2k/kubernetes-homelab/commit/d5cc7714e30dd7cd1ad4e8936fa86f9d130d2950))

## [2.7.23](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.22...v2.7.23) (2026-01-07)


### 🐛 Bug Fixes

* **proxmox-exporter:** update deployment configuration and service port to 9091 ([439b7b5](https://github.com/Nebu2k/kubernetes-homelab/commit/439b7b537998059200af51427641e1ca8312fba2))

## [2.7.22](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.21...v2.7.22) (2026-01-07)


### 🐛 Bug Fixes

* **grafana:** update Proxmox dashboard revision to 1 ([df68547](https://github.com/Nebu2k/kubernetes-homelab/commit/df6854762d829ee95003a7ac5324307f5931b27a))

## [2.7.21](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.20...v2.7.21) (2026-01-07)


### 🐛 Bug Fixes

* **proxmox-exporter:** add replication collector to deployment configuration ([e212c3e](https://github.com/Nebu2k/kubernetes-homelab/commit/e212c3e154e5d00d420fbce3868046f61bc1c9f4))

## [2.7.20](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.19...v2.7.20) (2026-01-07)


### 🐛 Bug Fixes

* **grafana:** update Proxmox dashboard gnetId and remove unused dashboard configuration ([948fb2e](https://github.com/Nebu2k/kubernetes-homelab/commit/948fb2efe0088dfe05bf6052ba0cb035c2f005bd))

## [2.7.19](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.18...v2.7.19) (2026-01-07)


### 🐛 Bug Fixes

* **grafana:** rename Proxmox dashboard data sources for clarity ([94cccfe](https://github.com/Nebu2k/kubernetes-homelab/commit/94cccfe85932d947f5e7d74a030e1ab932b7ce0a))

## [2.7.18](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.17...v2.7.18) (2026-01-07)


### 🐛 Bug Fixes

* **grafana:** update Proxmox monitoring dashboard configuration ([afa06e6](https://github.com/Nebu2k/kubernetes-homelab/commit/afa06e6d949b5d26d29de70ee67467fb5c75c176))

## [2.7.17](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.16...v2.7.17) (2026-01-07)


### 🐛 Bug Fixes

* **grafana:** update Proxmox dashboards and remove deprecated data sources ([72297ff](https://github.com/Nebu2k/kubernetes-homelab/commit/72297ff3d770960300ec4bd803c3d779c85f7ddf))

## [2.7.16](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.15...v2.7.16) (2026-01-07)


### 🐛 Bug Fixes

* **grafana:** add additional data sources for Proxmox dashboards ([8b78f94](https://github.com/Nebu2k/kubernetes-homelab/commit/8b78f942f5b2208b62f526806a9d02b3de17ded3))

## [2.7.15](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.14...v2.7.15) (2026-01-07)


### 🐛 Bug Fixes

* **servicemonitor:** add path to metrics endpoint for proxmox-exporter ([3630a28](https://github.com/Nebu2k/kubernetes-homelab/commit/3630a28e8947e4d14fe8d42af3f3df3faa3e0d34))

## [2.7.14](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.13...v2.7.14) (2026-01-07)


### 🐛 Bug Fixes

* **charts:** update targetRevision for cert-manager and metallb Helm charts ([1e307a8](https://github.com/Nebu2k/kubernetes-homelab/commit/1e307a83a9b6834763ce17922a2f3bcf32742358))

## [2.7.13](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.12...v2.7.13) (2026-01-07)


### 🐛 Bug Fixes

* **metallb, sealed-secrets:** update targetRevision for metallb and sealed-secrets charts ([a471321](https://github.com/Nebu2k/kubernetes-homelab/commit/a471321b12f284a7c11601acda30a8a38bad8a93))

## [2.7.12](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.11...v2.7.12) (2026-01-07)


### 🐛 Bug Fixes

* **servicemonitor:** update target parameter for proxmox-exporter ([9d79ce1](https://github.com/Nebu2k/kubernetes-homelab/commit/9d79ce1edd074941b2c6aa97d3ba86bc46bb8c63))

## [2.7.11](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.10...v2.7.11) (2026-01-07)


### 🐛 Bug Fixes

* **grafana:** remove unnecessary additional data sources for Proxmox dashboards ([b4d27b7](https://github.com/Nebu2k/kubernetes-homelab/commit/b4d27b7cd66b835e6c6c1bbe290d9192a6ceebdc))

## [2.7.10](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.9...v2.7.10) (2026-01-07)


### 🐛 Bug Fixes

* **proxmox-exporter:** update configuration for user and token naming in deployment ([96ab9b0](https://github.com/Nebu2k/kubernetes-homelab/commit/96ab9b0554ab4d1fa2bb5fe26be49eee2ae17144))

## [2.7.9](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.8...v2.7.9) (2026-01-07)


### 🐛 Bug Fixes

* **proxmox-exporter:** update Proxmox API credentials for consistency and clarity ([1663e76](https://github.com/Nebu2k/kubernetes-homelab/commit/1663e76321a514495ddbc0269256ba652ee1afbd))

## [2.7.8](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.7...v2.7.8) (2026-01-07)


### 🐛 Bug Fixes

* **proxmox-exporter:** update sealed secret credentials for improved security ([3738a6a](https://github.com/Nebu2k/kubernetes-homelab/commit/3738a6a5ca1edea101c0425f8e78b271d406c8d4))

## [2.7.7](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.6...v2.7.7) (2026-01-07)


### 🐛 Bug Fixes

* **proxmox-exporter:** update config file to use token-based authentication ([15bedaf](https://github.com/Nebu2k/kubernetes-homelab/commit/15bedaf0100a6f8281a85238642c33444deb3c38))

## [2.7.6](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.5...v2.7.6) (2026-01-07)


### 🐛 Bug Fixes

* **proxmox-exporter:** update deployment to include config-expander init container and adjust config file path ([8d28365](https://github.com/Nebu2k/kubernetes-homelab/commit/8d2836534d043e18bd67280462689591588054d4))

## [2.7.5](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.4...v2.7.5) (2026-01-07)


### 🐛 Bug Fixes

* **proxmox-exporter:** update pve-api-credentials with new encrypted data ([6c62a86](https://github.com/Nebu2k/kubernetes-homelab/commit/6c62a8651cbb20f49184fc484db1e9b8e8c137b7))

## [2.7.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.3...v2.7.4) (2026-01-07)


### 🐛 Bug Fixes

* **proxmox-exporter:** enhance deployment with config map and update environment variables ([4485e5a](https://github.com/Nebu2k/kubernetes-homelab/commit/4485e5a065e68a2cc231697f64e76f1ab3b616a2))

## [2.7.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.2...v2.7.3) (2026-01-07)


### 🐛 Bug Fixes

* **grafana:** add additional data sources for Proxmox dashboards ([3cbc066](https://github.com/Nebu2k/kubernetes-homelab/commit/3cbc0669dfd94758c946bf4bc22698bb0d09db20))

## [2.7.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.1...v2.7.2) (2026-01-07)


### 🐛 Bug Fixes

* add missing release label to proxmox-exporter ServiceMonitor ([e31fa5a](https://github.com/Nebu2k/kubernetes-homelab/commit/e31fa5a7969e694d73417f7c4c1d2ebecbdc7e99))

## [2.7.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.7.0...v2.7.1) (2026-01-07)


### 🐛 Bug Fixes

* add Proxmox VE dashboards to Grafana configuration ([2ada168](https://github.com/Nebu2k/kubernetes-homelab/commit/2ada16839287a580253ecc2acf1a3bc7836a8ed1))

## [2.7.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.6.0...v2.7.0) (2026-01-07)


### ✨ Features

* add Proxmox exporter resources and configuration ([7ee8a57](https://github.com/Nebu2k/kubernetes-homelab/commit/7ee8a571b3bb281e46a7f5e9d023e9268c3a8ffc))

## [2.6.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.5.0...v2.6.0) (2026-01-07)


### ✨ Features

* add NODE_OPTIONS environment variable for DNS resolution ([42acb7f](https://github.com/Nebu2k/kubernetes-homelab/commit/42acb7fa4b5bc71398f50635aff5ac107271f626))

## [2.5.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.4.7...v2.5.0) (2026-01-07)


### ✨ Features

* add new fields for Nextcloud monitoring in configmap ([1cda24f](https://github.com/Nebu2k/kubernetes-homelab/commit/1cda24f2211eeccd3d0a726a12f36e6845729b10))

## [2.4.7](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.4.6...v2.4.7) (2026-01-07)


### 🐛 Bug Fixes

* remove unnecessary fields from Nextcloud configuration ([017afd5](https://github.com/Nebu2k/kubernetes-homelab/commit/017afd561e3c2c6fb3e39ca3de70dd4a5c256dfa))

## [2.4.6](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.4.5...v2.4.6) (2026-01-07)


### 🐛 Bug Fixes

* update monitored field from cpuload to freespace in Nextcloud configuration ([3cbd29f](https://github.com/Nebu2k/kubernetes-homelab/commit/3cbd29f352d0b8a3a95e9fdf17fadaac887cda1e))

## [2.4.5](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.4.4...v2.4.5) (2026-01-07)


### 🐛 Bug Fixes

* remove dnsConfig section from deployment manifests ([427a8c2](https://github.com/Nebu2k/kubernetes-homelab/commit/427a8c2fe14f7169c63bd10045c2f039c0dabc14))

## [2.4.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.4.3...v2.4.4) (2026-01-07)


### 🐛 Bug Fixes

* update pod-selector annotation format in ingress configuration ([b57466d](https://github.com/Nebu2k/kubernetes-homelab/commit/b57466db60a80a992b372f055bb3052af15f6e4b))

## [2.4.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.4.2...v2.4.3) (2026-01-07)


### 🐛 Bug Fixes

* correct podSelector annotation to pod-selector in ingress configuration ([cb5e2c1](https://github.com/Nebu2k/kubernetes-homelab/commit/cb5e2c186a51976db9c8635655bbe636ea5d9654))

## [2.4.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.4.1...v2.4.2) (2026-01-07)


### 🐛 Bug Fixes

* add Nextcloud monitoring fields for CPU load, memory usage, active users, and number of files ([d7ed804](https://github.com/Nebu2k/kubernetes-homelab/commit/d7ed8041a3ba8846bc7064fc4ef20d15ac83ad07))

## [2.4.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.4.0...v2.4.1) (2026-01-07)


### 🐛 Bug Fixes

* update Nextcloud integration to use username and password instead of token ([36ee92e](https://github.com/Nebu2k/kubernetes-homelab/commit/36ee92e4983c501e40e64b54295b271d6c2d6a6b))

## [2.4.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.3.1...v2.4.0) (2026-01-07)


### ✨ Features

* add Plex and Nextcloud widgets with token management in homepage config ([6455b1d](https://github.com/Nebu2k/kubernetes-homelab/commit/6455b1dcccc4c91a9f42e1f9b8b9be2d2f5a8faa))

## [2.3.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.3.0...v2.3.1) (2026-01-07)


### 🐛 Bug Fixes

* add description for AWS Console entry and format icon line ([e0a8863](https://github.com/Nebu2k/kubernetes-homelab/commit/e0a88638cf6e86424ec12e62f1c4a3f70e5c2f8d))

## [2.3.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.2.7...v2.3.0) (2026-01-07)


### ✨ Features

* add AWS Console entry to services with description and icon ([d95d91e](https://github.com/Nebu2k/kubernetes-homelab/commit/d95d91ec97d5b1d4828407ba3bd3615be57198b6))


### 🐛 Bug Fixes

* update Management layout columns from 3 to 2 in configmap ([12917eb](https://github.com/Nebu2k/kubernetes-homelab/commit/12917eb5435284df7e1cb4a49ae6647074b9d6e6))

## [2.2.7](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.2.6...v2.2.7) (2026-01-07)


### 🐛 Bug Fixes

* update mosquitto image to specific version 2.0.22 ([ff46b2d](https://github.com/Nebu2k/kubernetes-homelab/commit/ff46b2dfa9da38363236375ef3c44c322930db3f))

## [2.2.6](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.2.5...v2.2.6) (2026-01-07)


### 🐛 Bug Fixes

* update container images to stable versions and improve version checking logic ([d98638e](https://github.com/Nebu2k/kubernetes-homelab/commit/d98638e8b932b4ea5c361906ad51000736d6fe86))

## [2.2.5](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.2.4...v2.2.5) (2026-01-06)


### 🐛 Bug Fixes

* update home-assistant and teslamate images to specific versions ([54bf03a](https://github.com/Nebu2k/kubernetes-homelab/commit/54bf03afa9cdf4aceae3eac8abe47999394c1ad4))

## [2.2.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.2.3...v2.2.4) (2026-01-06)


### 🐛 Bug Fixes

* update targetRevision for cert-manager and sealed-secrets charts ([da41357](https://github.com/Nebu2k/kubernetes-homelab/commit/da413577398cfc51a5183e39954862efcd90fc7e))

## [2.2.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.2.2...v2.2.3) (2026-01-06)


### 🐛 Bug Fixes

* update uptime-kuma image version and enhance version checking script ([35f3440](https://github.com/Nebu2k/kubernetes-homelab/commit/35f3440db6a7cedaa78e4be97268085984e09c3d))

## [2.2.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.2.1...v2.2.2) (2026-01-06)


### 🐛 Bug Fixes

* update metallb targetRevision to 6.4.22 ([0ec4d08](https://github.com/Nebu2k/kubernetes-homelab/commit/0ec4d08f5c486380700e55ea097dbd159e9b4021))

## [2.2.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.2.0...v2.2.1) (2026-01-06)


### 🐛 Bug Fixes

* update Longhorn node configuration to disable scheduling on non-storage nodes and set default node selector for persistence ([764115d](https://github.com/Nebu2k/kubernetes-homelab/commit/764115dec8b7e8ae3c69d83e97824fcfafc3b3cb))

## [2.2.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.1.2...v2.2.0) (2026-01-06)


### ✨ Features

* add Longhorn node configuration and update StorageClass to require "storage" tag ([39ebcd9](https://github.com/Nebu2k/kubernetes-homelab/commit/39ebcd9461959ce3ec55d3feed85069a5f316ad5))

## [2.1.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.1.1...v2.1.2) (2026-01-06)


### 🐛 Bug Fixes

* update snapshot cleanup job to retain 0 snapshots ([7055f68](https://github.com/Nebu2k/kubernetes-homelab/commit/7055f68e4b9b8a75435b3cd008b3b2d737b13ce2))

## [2.1.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.1.0...v2.1.1) (2026-01-06)


### 🐛 Bug Fixes

* remove namespace declaration from metallb kustomization ([5506f3c](https://github.com/Nebu2k/kubernetes-homelab/commit/5506f3c297aa6aa0e8668e0443f31359e8246a80))

## [2.1.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.0.0...v2.1.0) (2026-01-06)


### ✨ Features

* metalllb to helm ([4585377](https://github.com/Nebu2k/kubernetes-homelab/commit/45853772bbd4a486c093e729ae786f7dd2148208))

## [2.0.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.8.0...v2.0.0) (2026-01-06)


### ⚠ BREAKING CHANGES

* combine overlays

### ✨ Features

* combine overlays ([f8e9e9b](https://github.com/Nebu2k/kubernetes-homelab/commit/f8e9e9b4020ae773b0fd2dfac39338b4a10f3743))


### 🐛 Bug Fixes

* remove base directory structure from README tree generation ([48bf3e1](https://github.com/Nebu2k/kubernetes-homelab/commit/48bf3e12c6b3de631c17be506006435c946707b3))

## [1.8.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.7.12...v1.8.0) (2026-01-06)


### ✨ Features

* **longhorn:** remove deprecated config and update values file structure ([08a5de4](https://github.com/Nebu2k/kubernetes-homelab/commit/08a5de4b266d50825d2e8354000f275a68585795))

## [1.7.12](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.7.11...v1.7.12) (2026-01-06)


### ♻️ Code Refactoring

* **kube-prometheus-stack:** reorganize configuration and remove deprecated files ([27a302a](https://github.com/Nebu2k/kubernetes-homelab/commit/27a302a601c74f4b9fa5b13e94507f5edaab9a9a))

## [1.7.11](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.7.10...v1.7.11) (2026-01-06)


### 🐛 Bug Fixes

* **cert-manager:** update values file path and migrate configuration to production overlay ([a9d3889](https://github.com/Nebu2k/kubernetes-homelab/commit/a9d38892dca478c7327cb5bdd966e9b5813b68a4))

## [1.7.10](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.7.9...v1.7.10) (2026-01-06)


### 🐛 Bug Fixes

* **cert-manager:** remove cert-manager-config and update kustomization.yaml ([42177b2](https://github.com/Nebu2k/kubernetes-homelab/commit/42177b2bcc01bff81ed7a4ee434066b1f20c1e73))

## [1.7.9](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.7.8...v1.7.9) (2026-01-06)


### 🐛 Bug Fixes

* **n8n:** update secrets management for PostgreSQL and add encryption key ([e03cf1e](https://github.com/Nebu2k/kubernetes-homelab/commit/e03cf1eb2404ed326dfd61621db62facb5d253ad))

## [1.7.8](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.7.7...v1.7.8) (2026-01-06)


### 🐛 Bug Fixes

* **n8n:** update DB_POSTGRESDB_PASSWORD to use secretKeyRef for improved security ([93efcdf](https://github.com/Nebu2k/kubernetes-homelab/commit/93efcdfa114adc79edb0d15ff73de4e2c2451ac7))

## [1.7.7](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.7.6...v1.7.7) (2026-01-06)


### 🐛 Bug Fixes

* **postgresql:** update POSTGRES_PASSWORD to use secretKeyRef for better security ([ef2c899](https://github.com/Nebu2k/kubernetes-homelab/commit/ef2c8994d1406f73fdf3fbd28b11d3a0e931373e))

## [1.7.6](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.7.5...v1.7.6) (2026-01-06)


### 🐛 Bug Fixes

* **postgresql:** remove PGDATA environment variable from StatefulSet ([8fc7921](https://github.com/Nebu2k/kubernetes-homelab/commit/8fc7921c32abd5b8a866157d5301bd4366daa977))

## [1.7.5](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.7.4...v1.7.5) (2026-01-06)


### 🐛 Bug Fixes

* **postgresql:** update PGDATA environment variable and adjust volume mount path ([b949ee6](https://github.com/Nebu2k/kubernetes-homelab/commit/b949ee677902b255f4596267eefe73bd25d69606))

## [1.7.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.7.3...v1.7.4) (2026-01-06)


### 🐛 Bug Fixes

* **postgresql:** remove init container for data directory setup ([1e043e9](https://github.com/Nebu2k/kubernetes-homelab/commit/1e043e9677586400cad9319a28ea258276de1e95))

## [1.7.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.7.2...v1.7.3) (2026-01-06)


### 🐛 Bug Fixes

* **postgresql:** add init container for data directory setup ([15f297e](https://github.com/Nebu2k/kubernetes-homelab/commit/15f297ef9bbfcdb5f86a73bf026466f008dd23a0))

## [1.7.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.7.1...v1.7.2) (2026-01-06)


### 🐛 Bug Fixes

* **postgresql:** update PostgreSQL image to version 18-alpine ([216f81b](https://github.com/Nebu2k/kubernetes-homelab/commit/216f81b66ab9e24ba9b08715d1ca885d20a09416))

## [1.7.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.7.0...v1.7.1) (2026-01-06)


### 🐛 Bug Fixes

* **postgresql:** update image and environment variables for PostgreSQL configuration ([08b6216](https://github.com/Nebu2k/kubernetes-homelab/commit/08b62169b336e6cb208a732b8ec41b820eca940c))

## [1.7.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.6.0...v1.7.0) (2026-01-06)


### ✨ Features

* **n8n:** add init container for fixing permissions on n8n data directory ([845ad6f](https://github.com/Nebu2k/kubernetes-homelab/commit/845ad6ffc1c5e9e9d9c7af2660701fe0b0469fd3))

## [1.6.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.5.1...v1.6.0) (2026-01-06)


### ✨ Features

* **n8n:** restructure deployment with PostgreSQL backend and related resources ([c2e7bcc](https://github.com/Nebu2k/kubernetes-homelab/commit/c2e7bcc763ac7c25fffcb86eadd11bc9b1c90173))

## [1.5.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.5.0...v1.5.1) (2026-01-06)


### 🐛 Bug Fixes

* remove unused namespace resource from metallb kustomization ([79caba1](https://github.com/Nebu2k/kubernetes-homelab/commit/79caba13b2c9b7bb26004f02e584a1f3cedb0397))

## [1.5.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.4.6...v1.5.0) (2026-01-06)


### ✨ Features

* Add metallb-system namespace with pod security labels ([22f5dfd](https://github.com/Nebu2k/kubernetes-homelab/commit/22f5dfd63e01547134e0555594395f7659506a0b))

## [1.4.6](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.4.5...v1.4.6) (2026-01-06)


### 🐛 Bug Fixes

* remove duplicate defaultMode definition in internal CA secret ([2f1ddc7](https://github.com/Nebu2k/kubernetes-homelab/commit/2f1ddc7dc7a1e2962d86939a4b7383b0301f7423))

## [1.4.5](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.4.4...v1.4.5) (2026-01-06)


### 🐛 Bug Fixes

* change git.inputValidation from 'always' to true ([7c12b9d](https://github.com/Nebu2k/kubernetes-homelab/commit/7c12b9d5dafa9ceaec66fc99b8acd5c30b847033))

## [1.4.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.4.3...v1.4.4) (2026-01-06)


### 🐛 Bug Fixes

* remove redundant configMap definition in homepage deployment ([bb5683d](https://github.com/Nebu2k/kubernetes-homelab/commit/bb5683dc3a2d143cbc23d344f8cd78236748fc54))

## [1.4.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.4.2...v1.4.3) (2026-01-06)


### 🐛 Bug Fixes

* update readiness probe configuration and clean up volume definitions in homepage deployment ([9d4c12f](https://github.com/Nebu2k/kubernetes-homelab/commit/9d4c12f5124b8c3fd9f47078b6c34dc61a2ed800))

## [1.4.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.4.1...v1.4.2) (2026-01-06)


### 🐛 Bug Fixes

* add init container for configuration setup in homepage deployment ([c195e94](https://github.com/Nebu2k/kubernetes-homelab/commit/c195e949ac15678255a0c7cfe12fb4c4b0e23bc8))
* update commit message guidelines for clarity on 'fix:' and 'feat:' usage ([3cd6512](https://github.com/Nebu2k/kubernetes-homelab/commit/3cd6512bd3bc608241960b46d3905b96fdb79869))

## [1.4.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.4.0...v1.4.1) (2026-01-06)


### 🐛 Bug Fixes

* update HOMEPAGE_ALLOWED_HOSTS to allow all hosts ([4c9676e](https://github.com/Nebu2k/kubernetes-homelab/commit/4c9676e1fdea9bf0de6566f88cfce2e3e2ef30de))

## [1.4.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.3.0...v1.4.0) (2026-01-06)


### ✨ Features

* refactor homepage deployment configuration and remove obsolete files ([2b1d395](https://github.com/Nebu2k/kubernetes-homelab/commit/2b1d3953317e5bb825499854d97612dcc593c6d0))

## [1.3.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.2.0...v1.3.0) (2026-01-06)


### ✨ Features

* implement uptime-kuma deployment with necessary resources and configurations ([ada2242](https://github.com/Nebu2k/kubernetes-homelab/commit/ada22421880c3b73f8e6376d8b50f7e4e489ee89))

## [1.2.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v1.1.0...v1.2.0) (2026-01-06)


### ✨ Features

* add commit message convention and GitHub Copilot instructions ([bb7bdcc](https://github.com/Nebu2k/kubernetes-homelab/commit/bb7bdcc586a8840d3af9fc19372bae931374d9a6))
* enhance GitHub API integration with token support and simplify version check logic ([780014c](https://github.com/Nebu2k/kubernetes-homelab/commit/780014cacd879f0ffbe811124e9074f5682f846b))
* update nginx image to version 1.29.4-alpine and enhance version checker for Kustomize apps ([4b1268e](https://github.com/Nebu2k/kubernetes-homelab/commit/4b1268e55333fed38685b8080b1873bf5b9d4d14))


### 🐛 Bug Fixes

* add forward.override configuration to CoreDNS ConfigMap ([2915a4c](https://github.com/Nebu2k/kubernetes-homelab/commit/2915a4c6d65199b08fa80cf60020ea62b9457c21))
* add InfoInhibitor alert silence to Alertmanager configuration ([da4407e](https://github.com/Nebu2k/kubernetes-homelab/commit/da4407e2f6725c4669651ebaf978c0a0629a196b))
* add optimized DNS configuration to CoreDNS ConfigMap ([04a6457](https://github.com/Nebu2k/kubernetes-homelab/commit/04a645718ed8b601ba28f03bdb86d059dde1066f))
* enhance Cloudflare DNS configuration in CoreDNS ConfigMap ([73a9dd5](https://github.com/Nebu2k/kubernetes-homelab/commit/73a9dd542f78b382f8d4653c2a08b5b1c85132f6))
* optimize DNS configuration in CoreDNS ConfigMap ([e6bd542](https://github.com/Nebu2k/kubernetes-homelab/commit/e6bd5426ef28e59259639e1303bda068931c895a))
* remove .vscode directory from .gitignore ([9a85b53](https://github.com/Nebu2k/kubernetes-homelab/commit/9a85b53be9d9cb562ebfe89dfba031a2040cdbe3))
* remove Cloudflare DNS override from CoreDNS ConfigMap ([64f325f](https://github.com/Nebu2k/kubernetes-homelab/commit/64f325f5be52983da5c60d95e933485e14c77123))
* remove deprecated annotations from Traefik Dashboard ingressRoute and update ConfigMap for consistency ([519104d](https://github.com/Nebu2k/kubernetes-homelab/commit/519104deec6f3463861fb9e9a7eb16f84895b41d))
* update DNS configuration to reduce query timeouts and improve reliability ([4884d1d](https://github.com/Nebu2k/kubernetes-homelab/commit/4884d1d6403f2b1b5ebc84cff74ac7b8dfc3fdb0))
* update forward.override configuration in CoreDNS ConfigMap ([d192f9e](https://github.com/Nebu2k/kubernetes-homelab/commit/d192f9e83ab52952bcd3ad0a54a0e5fc121934bb))
* update Traefik Dashboard description for accuracy ([71837e8](https://github.com/Nebu2k/kubernetes-homelab/commit/71837e8919e233384b5ffd79382dbc42b0b868b5))
* update Traefik Dashboard description for clarity ([1464966](https://github.com/Nebu2k/kubernetes-homelab/commit/14649666e26031aa193a27493149908f733ef11e))
