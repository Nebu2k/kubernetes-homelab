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
