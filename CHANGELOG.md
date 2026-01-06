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
