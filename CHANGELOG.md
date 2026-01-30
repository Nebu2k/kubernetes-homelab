## [3.20.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.19.3...v3.20.0) (2026-01-30)


### ✨ Features

* add system backup jobs and filesystem trim to recurring jobs configuration ([f9958e2](https://github.com/Nebu2k/kubernetes-homelab/commit/f9958e27d42aa03d0a7c767f84c7ef13abc6dbce))

## [3.19.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.19.2...v3.19.3) (2026-01-30)


### ♻️ Code Refactoring

* remove OVH S3 secret and update backup job configurations ([949c096](https://github.com/Nebu2k/kubernetes-homelab/commit/949c096592c7882262918cefc7790467abd00816))

## [3.19.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.19.1...v3.19.2) (2026-01-30)


### ♻️ Code Refactoring

* remove OVH S3 recurring backup jobs from configuration ([3e7aab1](https://github.com/Nebu2k/kubernetes-homelab/commit/3e7aab1e70217619fcecc18ebeeee9e6216bc48f))

## [3.19.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.19.0...v3.19.1) (2026-01-30)


### ♻️ Code Refactoring

* remove dummy default job to streamline backup job configuration ([b93399c](https://github.com/Nebu2k/kubernetes-homelab/commit/b93399c9d52db49e4a0cc928591e8b7677cebcef))

## [3.19.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.18.0...v3.19.0) (2026-01-30)


### ✨ Features

* add OVH S3 backup support with recurring jobs and secrets ([1fed886](https://github.com/Nebu2k/kubernetes-homelab/commit/1fed886d0d6703c038c13c57e52b05a886a9e50c))

## [3.18.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.17.3...v3.18.0) (2026-01-30)


### ✨ Features

* add dummy default job to prevent backups for volumes without explicit jobs ([f94739a](https://github.com/Nebu2k/kubernetes-homelab/commit/f94739abae83060c92618e51a85c77119374357c))

## [3.17.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.17.2...v3.17.3) (2026-01-30)


### 🐛 Bug Fixes

* add Longhorn recurring job annotations to PVC configurations ([5dee931](https://github.com/Nebu2k/kubernetes-homelab/commit/5dee931c6569e98c26de650bd004490854c8a919))

## [3.17.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.17.1...v3.17.2) (2026-01-30)


### 🐛 Bug Fixes

* remove unused Longhorn recurring job annotations from PVC configurations ([ef1471e](https://github.com/Nebu2k/kubernetes-homelab/commit/ef1471ef0d4d910fb9f6d8de67a82f27075c231d))

## [3.17.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.17.0...v3.17.1) (2026-01-30)


### 🐛 Bug Fixes

* update Longhorn recurring job annotations in PVC configuration ([edccbca](https://github.com/Nebu2k/kubernetes-homelab/commit/edccbca6921dda30530f070f7101d6d3727dfd03))

## [3.17.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.16.1...v3.17.0) (2026-01-30)


### ✨ Features

* update recurring job configuration for Longhorn backups ([18ab46a](https://github.com/Nebu2k/kubernetes-homelab/commit/18ab46af6f2c129abc4485122b82318d714798f7))

## [3.16.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.16.0...v3.16.1) (2026-01-30)


### 🐛 Bug Fixes

* update recurring job list for Longhorn backup configuration ([69780bc](https://github.com/Nebu2k/kubernetes-homelab/commit/69780bc9387ce72436d6c0ebb592b8cdc0b92eaa))

## [3.16.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.15.1...v3.16.0) (2026-01-30)


### ✨ Features

* add MinIO backend configuration and setup script for Terraform ([59154a0](https://github.com/Nebu2k/kubernetes-homelab/commit/59154a0efc1b64146cd7dd575fca258769f7a978))

## [3.15.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.15.0...v3.15.1) (2026-01-30)


### 🐛 Bug Fixes

* update MinIO ingress namespaces to private-services ([1b901ba](https://github.com/Nebu2k/kubernetes-homelab/commit/1b901baac122267121edd918cfe9fc6b42b54cef))

## [3.15.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.14.1...v3.15.0) (2026-01-30)


### ✨ Features

* add MinIO service entry to homepage config and remove annotations from MinIO ingress ([ffd6ca6](https://github.com/Nebu2k/kubernetes-homelab/commit/ffd6ca60cab5b7f4a14739d2837ec10745d7c375))

## [3.14.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.14.0...v3.14.1) (2026-01-30)


### 🐛 Bug Fixes

* update MinIO service and endpoints to use the correct namespace ([be26937](https://github.com/Nebu2k/kubernetes-homelab/commit/be269370b19cc6fcd0cea795fdd600b8aa843be7))

## [3.14.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.13.0...v3.14.0) (2026-01-30)


### ✨ Features

* enhance duplicate entry detection and removal in AdGuard DNS sync ([6d67503](https://github.com/Nebu2k/kubernetes-homelab/commit/6d67503f067f77e012e1e32850184a6e49caf1b3))

## [3.13.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.12.0...v3.13.0) (2026-01-30)


### ✨ Features

* improve AdGuard DNS sync by enhancing duplicate entry detection and cleanup ([5e78056](https://github.com/Nebu2k/kubernetes-homelab/commit/5e78056f4fab0f9bbabad5a2411167eae2b80177))

## [3.12.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.11.0...v3.12.0) (2026-01-30)


### ✨ Features

* enhance prometheus lifecycle management and add duplicate entry cleanup for AdGuard DNS sync ([33a1a5c](https://github.com/Nebu2k/kubernetes-homelab/commit/33a1a5c85dcd5724c2822685eefc18e655a4c5a2))

## [3.11.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.10.1...v3.11.0) (2026-01-30)


### ✨ Features

* add MinIO ingress and service configurations for external access ([15357d3](https://github.com/Nebu2k/kubernetes-homelab/commit/15357d33d41f175272083be03b9b60cbbac3c9c1))

## [3.10.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.10.0...v3.10.1) (2026-01-30)


### ♻️ Code Refactoring

* remove MinIO resources and configurations ([96b728c](https://github.com/Nebu2k/kubernetes-homelab/commit/96b728c8b7903098e66667b5b8b1b29da057999c))

## [3.10.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.9.2...v3.10.0) (2026-01-30)


### ✨ Features

* add MinIO VM configuration and secrets for Longhorn backups ([aa0b286](https://github.com/Nebu2k/kubernetes-homelab/commit/aa0b286a778672064bc72addc75998bed54bbe1c))

## [3.9.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.9.1...v3.9.2) (2026-01-30)


### 🐛 Bug Fixes

* update defaultClassReplicaCount to match defaultReplicaCount ([353633e](https://github.com/Nebu2k/kubernetes-homelab/commit/353633ec34503d569f553da8faae58b68cc8f5cb))

## [3.9.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.9.0...v3.9.1) (2026-01-30)


### 🐛 Bug Fixes

* increase storage and retention size for Prometheus ([4d51bb0](https://github.com/Nebu2k/kubernetes-homelab/commit/4d51bb0547a560ad00c56274810e0cef45a06058))

## [3.9.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.8.3...v3.9.0) (2026-01-27)


### ✨ Features

* add vscode ingress configuration and service ([e87dc6a](https://github.com/Nebu2k/kubernetes-homelab/commit/e87dc6a7d416e3c6dbb691720d84e2a67cd04144))

## [3.8.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.8.2...v3.8.3) (2026-01-26)


### 🐛 Bug Fixes

* add Cloudflare proxied annotation to nextcloud ingress ([8a2ee67](https://github.com/Nebu2k/kubernetes-homelab/commit/8a2ee6724b68364b6b8ff3acbe4967e24ff79f59))

## [3.8.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.8.1...v3.8.2) (2026-01-24)


### 🐛 Bug Fixes

* update endpoint and id in newt-auth sealed secret configuration ([62ff984](https://github.com/Nebu2k/kubernetes-homelab/commit/62ff9849d98480185bdbf902475d1a1c169ef3a5))

## [3.8.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.8.0...v3.8.1) (2026-01-23)


### 🐛 Bug Fixes

* update endpoint and id in newt-auth sealed secret configuration ([5acd097](https://github.com/Nebu2k/kubernetes-homelab/commit/5acd097d096e3e0e4390589f6fcfbab7b27e26d5))

## [3.8.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.7.7...v3.8.0) (2026-01-23)


### ✨ Features

* add newt resource and sealed secret configuration ([c1c6953](https://github.com/Nebu2k/kubernetes-homelab/commit/c1c69530c105af1b6db0ee67c4a7b27717bc7866))

## [3.7.7](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.7.6...v3.7.7) (2026-01-23)


### ♻️ Code Refactoring

* remove S3 backup target configuration and update default backup store to S3 ([5dc6e63](https://github.com/Nebu2k/kubernetes-homelab/commit/5dc6e63f680b75091714de462788bedcdc7b35b0))

## [3.7.6](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.7.5...v3.7.6) (2026-01-23)


### 🐛 Bug Fixes

* simplify backup target URL in Longhorn configuration ([0c184d4](https://github.com/Nebu2k/kubernetes-homelab/commit/0c184d4723aca9153eb02d88c3fc05f1e4a9fc57))

## [3.7.5](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.7.4...v3.7.5) (2026-01-23)


### 🐛 Bug Fixes

* update backup target URL format in Longhorn configuration ([744fbef](https://github.com/Nebu2k/kubernetes-homelab/commit/744fbef2d519e5473acf6a88b47358996844d1ff))

## [3.7.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.7.3...v3.7.4) (2026-01-23)


### 🐛 Bug Fixes

* correct backup target URL format in Longhorn configuration ([dfea9f5](https://github.com/Nebu2k/kubernetes-homelab/commit/dfea9f5b05ee64645faa4e519389c734d20d64b9))

## [3.7.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.7.2...v3.7.3) (2026-01-23)


### 🐛 Bug Fixes

* remove unused syncRequestedAt field from S3 backup target configuration ([a129781](https://github.com/Nebu2k/kubernetes-homelab/commit/a12978154d000cfefc246b3b0d297195e993fdc7))

## [3.7.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.7.1...v3.7.2) (2026-01-23)


### 🐛 Bug Fixes

* update pollInterval format to include seconds in S3 backup target configuration ([93d6ea8](https://github.com/Nebu2k/kubernetes-homelab/commit/93d6ea8a64270ca36a065b41261a8449c6b27bc6))

## [3.7.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.7.0...v3.7.1) (2026-01-23)


### 🐛 Bug Fixes

* update pollInterval format to string in S3 backup target configuration ([adc0e3f](https://github.com/Nebu2k/kubernetes-homelab/commit/adc0e3fc1638f9a6c5a89016cfcfeb1948121576))

## [3.7.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.6.2...v3.7.0) (2026-01-23)


### ✨ Features

* add S3 backup target and update recurring backup jobs for NFS ([26ae63f](https://github.com/Nebu2k/kubernetes-homelab/commit/26ae63f56e151911d017b6b6b34f4569250f1775))

## [3.6.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.6.1...v3.6.2) (2026-01-23)


### 🐛 Bug Fixes

* remove duplicate retrans option from NFS mount options ([15c03ed](https://github.com/Nebu2k/kubernetes-homelab/commit/15c03ed9e986d79424d45471b0a05a324ba1149a))
* update NFS mount options to include nfsvers and remove duplicate retrans ([44a3d74](https://github.com/Nebu2k/kubernetes-homelab/commit/44a3d74c41e7debdaf5e248164d117eab67b8a97))

## [3.6.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.6.0...v3.6.1) (2026-01-23)


### ♻️ Code Refactoring

* update nfs-storage configuration and remove deprecated files ([2468969](https://github.com/Nebu2k/kubernetes-homelab/commit/2468969d60fb789cd4c7132518cf262afce72517))

## [3.6.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.5.1...v3.6.0) (2026-01-23)


### ✨ Features

* add NFS storage configuration and related resources ([798922d](https://github.com/Nebu2k/kubernetes-homelab/commit/798922d473d89a64ee059346cf45531436fe6d20))


### 🐛 Bug Fixes

* add StorageClass configuration to disable local path as default ([6cf6e3e](https://github.com/Nebu2k/kubernetes-homelab/commit/6cf6e3e7c4e34d424c721dc56cd4c7f8451df69d))
* update NFS path in values.yaml for correct data storage location ([ba7d597](https://github.com/Nebu2k/kubernetes-homelab/commit/ba7d5972d4617cc021f2f9b9c148898075f0340f))
* update repoURL in nfs-storage.yaml and add smart_title_case function for title formatting ([7998b4a](https://github.com/Nebu2k/kubernetes-homelab/commit/7998b4a733f50ea7e4dca59e0ef588c29ab75e94))


### ♻️ Code Refactoring

* consolidate special cases and acronyms for title casing in smart_title_case function ([676b0e4](https://github.com/Nebu2k/kubernetes-homelab/commit/676b0e403a4a8a3b0fae08e9b8344b1493a1ffb7))

## [3.5.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.5.0...v3.5.1) (2026-01-23)


### 🐛 Bug Fixes

* improve registry validation in get_latest_docker_tag function ([f693910](https://github.com/Nebu2k/kubernetes-homelab/commit/f693910d15ff04a10962759b3ea011220d073fa8))

## [3.5.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.4.0...v3.5.0) (2026-01-23)


### ✨ Features

* **paperless-ngx:** update smb-sync container image and sync interval; add liveness probe ([29343bd](https://github.com/Nebu2k/kubernetes-homelab/commit/29343bd92020de6d151737e537c51ffedea84996))

## [3.4.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.3.5...v3.4.0) (2026-01-23)


### ✨ Features

* **paperless-ngx:** update resource requests and limits for improved performance; add Dockerfile for SMB sync image ([1a0c844](https://github.com/Nebu2k/kubernetes-homelab/commit/1a0c84494727c7618071b59658c87077a524ec1a))

## [3.3.5](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.3.4...v3.3.5) (2026-01-22)


### 🐛 Bug Fixes

* **longhorn:** revert defaultReplicaCount to 3 for improved I/O performance on Control-Plane ([593a2e2](https://github.com/Nebu2k/kubernetes-homelab/commit/593a2e2d35ddcb6a5e76f37b6c6c5c46ea9404ab))

## [3.3.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.3.3...v3.3.4) (2026-01-22)


### 🐛 Bug Fixes

* **longhorn:** add disk specifications for k3s-worker-1, raspi4, and raspi5 nodes ([20a5282](https://github.com/Nebu2k/kubernetes-homelab/commit/20a52822d3c4d195626c2c35c6050d9fd3b42e30))

## [3.3.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.3.2...v3.3.3) (2026-01-22)


### 🐛 Bug Fixes

* **longhorn:** add missing name fields in node specifications ([46080a5](https://github.com/Nebu2k/kubernetes-homelab/commit/46080a54d537966dc26588a4a591e1a3efe45216))

## [3.3.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.3.1...v3.3.2) (2026-01-22)


### 🐛 Bug Fixes

* **longhorn:** enable scheduling for raspi4 node ([24773fd](https://github.com/Nebu2k/kubernetes-homelab/commit/24773fd545fb541e2c063a9d0e4fdd3a4c4fd52f))

## [3.3.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.3.0...v3.3.1) (2026-01-21)


### 🐛 Bug Fixes

* **longhorn:** reduce backup concurrency to prevent overload on ARM nodes ([f47c72d](https://github.com/Nebu2k/kubernetes-homelab/commit/f47c72df0d2c7e83533f628490685e427ac39806))

## [3.3.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.2.2...v3.3.0) (2026-01-21)


### ✨ Features

* **prometheus:** enable EndpointSlice discovery role for Kubernetes v1.33+ ([3ab1ef9](https://github.com/Nebu2k/kubernetes-homelab/commit/3ab1ef9f1bb7983741ee31000cc16a92f8d59540))

## [3.2.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.2.1...v3.2.2) (2026-01-20)


### ♻️ Code Refactoring

* remove system-upgrade-controller and related resources ([a3a399c](https://github.com/Nebu2k/kubernetes-homelab/commit/a3a399cb319fc9332afc220da436f99851c91daa))

## [3.2.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.2.0...v3.2.1) (2026-01-20)


### 🐛 Bug Fixes

* increase SYSTEM_UPGRADE_JOB_ACTIVE_DEADLINE_SECONDS to 1800 ([596ce65](https://github.com/Nebu2k/kubernetes-homelab/commit/596ce65051d8a2da1f679171654b9f4fb168cba0))

## [3.2.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.1.6...v3.2.0) (2026-01-20)


### ✨ Features

* add system-upgrade-controller and upgrade plans for k3s ([2c6811b](https://github.com/Nebu2k/kubernetes-homelab/commit/2c6811b0ab4ab9ac5d24993ef65b2c3f96b26d07))

## [3.1.6](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.1.5...v3.1.6) (2026-01-20)


### 🐛 Bug Fixes

* update node affinity to use prodesk for home-assistant deployment ([e0fc92c](https://github.com/Nebu2k/kubernetes-homelab/commit/e0fc92c9e13f2ff1b902c2e935ae88d10c7583b2))

## [3.1.5](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.1.4...v3.1.5) (2026-01-20)


### 🐛 Bug Fixes

* update node affinity to use k3s-worker-1 for home-assistant deployment ([2151410](https://github.com/Nebu2k/kubernetes-homelab/commit/215141030bcc90508a24a174d2e5df1b8159df81))

## [3.1.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.1.3...v3.1.4) (2026-01-19)


### ♻️ Code Refactoring

* disable scheduling for k3s-worker-1 in Longhorn node configuration ([bf1d68a](https://github.com/Nebu2k/kubernetes-homelab/commit/bf1d68abbfbeeaa7fde6d1d935ef7e8aeff3b651))

## [3.1.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.1.2...v3.1.3) (2026-01-19)


### ♻️ Code Refactoring

* simplify MetalLB LoadBalancer configuration in values.yaml ([e9f51fd](https://github.com/Nebu2k/kubernetes-homelab/commit/e9f51fd7febc227c88cf5755e2b7ae42561fac94))

## [3.1.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.1.1...v3.1.2) (2026-01-19)


### ♻️ Code Refactoring

* remove optional IPv6 DualStack configuration steps from README ([b9c3a29](https://github.com/Nebu2k/kubernetes-homelab/commit/b9c3a29da3dcdd22b7c3b090dafdefa1cf1c8733))

## [3.1.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.1.0...v3.1.1) (2026-01-19)


### ♻️ Code Refactoring

* remove commonLabels from kustomization.yaml ([8894d1e](https://github.com/Nebu2k/kubernetes-homelab/commit/8894d1ed9cd32c65ba31151dcc8caf8dddd9257b))

## [3.1.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.0.1...v3.1.0) (2026-01-19)


### ✨ Features

* add optional IPv6 DualStack configuration steps for K3s installation ([610bdf3](https://github.com/Nebu2k/kubernetes-homelab/commit/610bdf325e957ccf04406c3713f0c7a811655826))

## [3.0.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v3.0.0...v3.0.1) (2026-01-19)


### 🐛 Bug Fixes

* redirect script output to stderr for better error visibility during DNS sync ([7b509fb](https://github.com/Nebu2k/kubernetes-homelab/commit/7b509fb1bce9c9a93a493ed5a97062ee819cf09a))

## [3.0.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.38.0...v3.0.0) (2026-01-19)


### ⚠ BREAKING CHANGES

* enhance DNS sync script output by adding conditional display of targets and summary counts

### ✨ Features

* enhance DNS sync script output by adding conditional display of targets and summary counts ([91fba7b](https://github.com/Nebu2k/kubernetes-homelab/commit/91fba7b2710a09844168df5ecbd92d92336682b3))

## [2.38.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.37.13...v2.38.0) (2026-01-19)


### ✨ Features

* add support for .gitignore patterns in README generation ([667cf3f](https://github.com/Nebu2k/kubernetes-homelab/commit/667cf3fb2b369c7f73b4e656ed1d4cf0d3c272bd))
* enhance dual-stack DNS sync by supporting separate IPv4 and IPv6 mappings ([9706bf6](https://github.com/Nebu2k/kubernetes-homelab/commit/9706bf6573e8111ff1443dbb8e3a7caf4075e971))
* enhance dual-stack support across configurations and scripts ([1276a57](https://github.com/Nebu2k/kubernetes-homelab/commit/1276a57ab87cc05e8b1541b4709c3235d25a9023))
* improve DNS sync script to handle separate IPv4 and IPv6 addresses more robustly ([b1e5a84](https://github.com/Nebu2k/kubernetes-homelab/commit/b1e5a8405995ec20603dd582f415ef5c64593584))
* refactor DNS sync script to use printf for improved data handling ([aa1c2f6](https://github.com/Nebu2k/kubernetes-homelab/commit/aa1c2f65003fe250f1137c972bbdb218f203a907))
* update adguard DNS sync job to use printf for better handling of input data ([5fd0120](https://github.com/Nebu2k/kubernetes-homelab/commit/5fd0120d4b2842d94d736934f0d15a12685081a4))
* update DNS sync script to return counts via stdout and remove empty lines from entries ([2d7dc63](https://github.com/Nebu2k/kubernetes-homelab/commit/2d7dc63604636087ff2beb27722839b792baa1f3))
* update IPv6 addresses in configuration for improved network handling ([493bd75](https://github.com/Nebu2k/kubernetes-homelab/commit/493bd75c57d149188becaf6e9ffff9be0dcc8dcb))

## [2.37.13](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.37.12...v2.37.13) (2026-01-19)


### 🐛 Bug Fixes

* update mountPath for agent data storage to correct directory ([9feb852](https://github.com/Nebu2k/kubernetes-homelab/commit/9feb85244b25e4bc7c061706b0d7f645394d6a73))

## [2.37.12](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.37.11...v2.37.12) (2026-01-19)


### 🐛 Bug Fixes

* reduce default replica counts to improve performance and reduce rebuild load ([5963b4d](https://github.com/Nebu2k/kubernetes-homelab/commit/5963b4ded9e98fa7b8f25638eefaead0689a1138))

## [2.37.11](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.37.10...v2.37.11) (2026-01-19)


### 🐛 Bug Fixes

* reduce concurrency for backup jobs to prevent etcd overload ([1c73628](https://github.com/Nebu2k/kubernetes-homelab/commit/1c7362804979f5b1cca4422401ccc591838137ec))

## [2.37.10](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.37.9...v2.37.10) (2026-01-18)


### 🐛 Bug Fixes

* add volume and volumeMount for agent data in DaemonSet ([90e5edc](https://github.com/Nebu2k/kubernetes-homelab/commit/90e5edc40ace955881b809c6e1ea27b11be179ea))

## [2.37.9](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.37.8...v2.37.9) (2026-01-18)


### 🐛 Bug Fixes

* add comment for concurrentReplicaRebuildPerNodeLimit in Longhorn settings ([ab1587c](https://github.com/Nebu2k/kubernetes-homelab/commit/ab1587c6a1547dd5f74d352edc85757d6f9aa4c2))

## [2.37.8](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.37.7...v2.37.8) (2026-01-18)


### 🐛 Bug Fixes

* remove offlineReplicaRebuilding configuration from Longhorn settings ([fdcfc5e](https://github.com/Nebu2k/kubernetes-homelab/commit/fdcfc5e4d326d97a47e9eeabb340f15879d99a0e))

## [2.37.7](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.37.6...v2.37.7) (2026-01-18)


### 🐛 Bug Fixes

* update offlineReplicaRebuilding configuration for Longhorn settings ([1f75a72](https://github.com/Nebu2k/kubernetes-homelab/commit/1f75a72919b6302bd28f19f829b78818c88de7dd))

## [2.37.6](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.37.5...v2.37.6) (2026-01-18)


### 🐛 Bug Fixes

* enable offline replica rebuilding for degraded volumes in Longhorn settings ([aaa5474](https://github.com/Nebu2k/kubernetes-homelab/commit/aaa5474b81d83fe0fda5649f492800eac9c40b50))

## [2.37.5](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.37.4...v2.37.5) (2026-01-18)


### 🐛 Bug Fixes

* update scrapeTimeout to 30s in ServiceMonitor configuration ([516a8ce](https://github.com/Nebu2k/kubernetes-homelab/commit/516a8cec311f8f614adb5d0e80391a4e67eb401b))

## [2.37.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.37.3...v2.37.4) (2026-01-18)


### ♻️ Code Refactoring

* update proxmox-exporter deployment and ServiceMonitor configuration ([6cc8e49](https://github.com/Nebu2k/kubernetes-homelab/commit/6cc8e4967038631c150ac33e092ff7145e7a769b))

## [2.37.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.37.2...v2.37.3) (2026-01-18)


### 🐛 Bug Fixes

* update Proxmox host IP in ServiceMonitor configuration ([ef65313](https://github.com/Nebu2k/kubernetes-homelab/commit/ef65313cbb7e017fc33bbcd03bdecf6f2d3a9276))

## [2.37.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.37.1...v2.37.2) (2026-01-18)


### ♻️ Code Refactoring

* update proxmox-exporter configuration and deployment settings ([8164ee2](https://github.com/Nebu2k/kubernetes-homelab/commit/8164ee2c58026b5cbca5b3a3fd431d4bea2297d3))

## [2.37.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.37.0...v2.37.1) (2026-01-18)


### 🐛 Bug Fixes

* increase scrapeTimeout to 120s for proxmox-exporter ServiceMonitor ([a54a3e8](https://github.com/Nebu2k/kubernetes-homelab/commit/a54a3e80b58e630caf82797ca97e26aa2b725087))

## [2.37.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.36.0...v2.37.0) (2026-01-17)


### ✨ Features

* remove adguard-pi5 ingress configuration from kustomization ([b239e33](https://github.com/Nebu2k/kubernetes-homelab/commit/b239e333d8804e157fda9341b8b6270a4a91ee1f))

## [2.36.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.35.0...v2.36.0) (2026-01-17)


### ✨ Features

* enhance kubectl installation script to support multiple architectures ([0555c84](https://github.com/Nebu2k/kubernetes-homelab/commit/0555c8472b32341106ca89414b49b8e193593b58))

## [2.35.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.34.9...v2.35.0) (2026-01-17)


### ✨ Features

* add Role and RoleBinding for ca-copier to access internal CA secret ([d149b95](https://github.com/Nebu2k/kubernetes-homelab/commit/d149b95879888ad48fb295a587e58c4e2acb5ce4))

## [2.34.9](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.34.8...v2.34.9) (2026-01-17)


### 🐛 Bug Fixes

* update S3 backup process to use current export directory and enable versioning ([2a571b6](https://github.com/Nebu2k/kubernetes-homelab/commit/2a571b67227d5621ecd5425fcfb7271e7cebd77e))

## [2.34.8](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.34.7...v2.34.8) (2026-01-17)


### 🐛 Bug Fixes

* increase sleep duration in backup script to one hour ([805f39c](https://github.com/Nebu2k/kubernetes-homelab/commit/805f39c008d292c16fd438819154a6760c78b2e3))

## [2.34.7](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.34.6...v2.34.7) (2026-01-17)


### 🐛 Bug Fixes

* update AWS credentials in s3-backup-credentials-sealed.yaml ([2b3c62c](https://github.com/Nebu2k/kubernetes-homelab/commit/2b3c62c39bad2069f13e8e4cf55c3cf9436cb1aa))

## [2.34.6](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.34.5...v2.34.6) (2026-01-17)


### 🐛 Bug Fixes

* reduce sleep duration in backup sync script from 3600 seconds to 60 seconds ([6fa1cc1](https://github.com/Nebu2k/kubernetes-homelab/commit/6fa1cc1063d7d6f3277cc74ae3853f7e0b24e98f))

## [2.34.5](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.34.4...v2.34.5) (2026-01-17)


### 🐛 Bug Fixes

* enhance kubectl installation to support multiple architectures ([f542c40](https://github.com/Nebu2k/kubernetes-homelab/commit/f542c4094819aba7bdafdf2355ddc629a0139552))

## [2.34.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.34.3...v2.34.4) (2026-01-17)


### 🐛 Bug Fixes

* update backup and CA copy jobs to use alpine image and install kubectl ([d9263ab](https://github.com/Nebu2k/kubernetes-homelab/commit/d9263ab0f13577e6f4cab1d7ecba5f3c1bec90bc))

## [2.34.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.34.2...v2.34.3) (2026-01-17)


### 🐛 Bug Fixes

* change shell from bash to sh in backup-trigger command ([ff5dc2b](https://github.com/Nebu2k/kubernetes-homelab/commit/ff5dc2bde693057f0c3e3a21138cc351987ee537))

## [2.34.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.34.1...v2.34.2) (2026-01-17)


### 🐛 Bug Fixes

* change shell from bash to sh in S3 backup sidecar command ([95a4e41](https://github.com/Nebu2k/kubernetes-homelab/commit/95a4e4113de6e996791cccbe9e67ce3a08b7a945))

## [2.34.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.34.0...v2.34.1) (2026-01-17)


### 🐛 Bug Fixes

* update grafana and teslamate images to use correct version format ([0ac89a3](https://github.com/Nebu2k/kubernetes-homelab/commit/0ac89a3ea508c5e7fc7f1b02496efe1e44b4cbec))

## [2.34.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.33.4...v2.34.0) (2026-01-17)


### ✨ Features

* add S3 backup cronjob and credentials management ([6946624](https://github.com/Nebu2k/kubernetes-homelab/commit/69466249af1cf64691133b9c1fc8eb3f34e4a5f4))
* update backup cronjob and add S3 backup sidecar for document export ([5e7aa44](https://github.com/Nebu2k/kubernetes-homelab/commit/5e7aa447bd1c82c95ec08a6e78defa989367f824))


### 🐛 Bug Fixes

* improve backup synchronization and verification process in deployment ([bd59729](https://github.com/Nebu2k/kubernetes-homelab/commit/bd59729aea84f1ca79337c63bdbd3e31a851957c))
* update container images to specific versions for stability and security ([650618c](https://github.com/Nebu2k/kubernetes-homelab/commit/650618c6d23edb292bd3fba17690f2f3a4c4767b))

## [2.33.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.33.3...v2.33.4) (2026-01-16)


### 🐛 Bug Fixes

* update n8n image to version 2.4.4 ([e9831f6](https://github.com/Nebu2k/kubernetes-homelab/commit/e9831f628b28b306520c9cbcb57cd439f6591923))

## [2.33.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.33.2...v2.33.3) (2026-01-16)


### 🐛 Bug Fixes

* adjust PostgreSQL volume mount path and remove PGDATA environment variable ([9e45393](https://github.com/Nebu2k/kubernetes-homelab/commit/9e453932a5929066eec5e39c4ad45ac3a00435ee))

## [2.33.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.33.1...v2.33.2) (2026-01-16)


### 🐛 Bug Fixes

* update MinIO image to latest-cicd and adjust PostgreSQL PGDATA path ([e1d66b7](https://github.com/Nebu2k/kubernetes-homelab/commit/e1d66b7982c2aa80f7d95214031f0d301fb8c768))

## [2.33.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.33.0...v2.33.1) (2026-01-16)


### 🐛 Bug Fixes

* update PostgreSQL and Redis images to latest versions ([4807bea](https://github.com/Nebu2k/kubernetes-homelab/commit/4807bead4ba06a51e97ae83142c8e691a54f5a24))

## [2.33.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.32.2...v2.33.0) (2026-01-16)


### ✨ Features

* add SMB sync sidecar and sealed secret for credentials ([c0c0412](https://github.com/Nebu2k/kubernetes-homelab/commit/c0c0412e74d5c077eb1a43d49d5e0bf7f9473811))

## [2.32.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.32.1...v2.32.2) (2026-01-16)


### 🐛 Bug Fixes

* add recurring-job annotation to home-assistant PVC ([4aa0169](https://github.com/Nebu2k/kubernetes-homelab/commit/4aa0169ff3443e8b2e5d19556d8a66ab4308adaa))

## [2.32.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.32.0...v2.32.1) (2026-01-16)


### 🐛 Bug Fixes

* exclude unsealed.yaml files without .example extension in README generation ([0643a97](https://github.com/Nebu2k/kubernetes-homelab/commit/0643a9733020ee439562d93c73192860972bfcac))
* update PAPERLESS_ALLOWED_HOSTS to allow all hosts ([c8f5046](https://github.com/Nebu2k/kubernetes-homelab/commit/c8f50464048015062582185bfda942372616ad35))
* update PAPERLESS_FILENAME_FORMAT to use correct templating syntax ([ac2efe3](https://github.com/Nebu2k/kubernetes-homelab/commit/ac2efe31114f79738e309f398f36aa8b11442636))

## [2.31.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.30.0...v2.31.0) (2026-01-16)


### ✨ Features

* add certificates for Unifi Controller, Unifi NAS, Proxmox, and Portainer ([d42ee45](https://github.com/Nebu2k/kubernetes-homelab/commit/d42ee4500415ca37a496d51b69609732c37058ed))

## [2.30.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.29.3...v2.30.0) (2026-01-16)


### ✨ Features

* add unifi-nas service and IngressRoute configuration ([8a4ac4c](https://github.com/Nebu2k/kubernetes-homelab/commit/8a4ac4c46d950dc2342759cc39b63e5311f40403))

## [2.29.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.29.2...v2.29.3) (2026-01-16)


### 🐛 Bug Fixes

* add dnsConfig options to homepage deployment ([bbac5d2](https://github.com/Nebu2k/kubernetes-homelab/commit/bbac5d2ebb2064142aed26cfbc3b618ec85c1ecb))

## [2.29.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.29.1...v2.29.2) (2026-01-15)


### 🐛 Bug Fixes

* remove N8N_RUNNERS_ENABLED environment variable from deployment configuration ([83879d7](https://github.com/Nebu2k/kubernetes-homelab/commit/83879d7dee72c89f5f4dec3b27150121b9f85acf))

## [2.29.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.29.0...v2.29.1) (2026-01-15)


### 🐛 Bug Fixes

* update N8N_RUNNERS_ENABLED environment variable in deployment configuration ([6ba789b](https://github.com/Nebu2k/kubernetes-homelab/commit/6ba789b7a9b4a6ed312ebd74b670933e5c5abd09))

## [2.29.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.28.0...v2.29.0) (2026-01-15)


### ✨ Features

* add additional environment variables for n8n configuration ([dc0a30e](https://github.com/Nebu2k/kubernetes-homelab/commit/dc0a30e942fe76e49c8e348f5444100fae198bbd))

## [2.28.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.27.4...v2.28.0) (2026-01-15)


### ✨ Features

* add example unsealed PostgreSQL secret for n8n deployment ([c060912](https://github.com/Nebu2k/kubernetes-homelab/commit/c0609129dd4ac7882358f1f1bc48147fa76c785c))

## [2.27.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.27.3...v2.27.4) (2026-01-15)


### 🐛 Bug Fixes

* add N8N_PROXY_HOPS environment variable to n8n deployment ([a67807c](https://github.com/Nebu2k/kubernetes-homelab/commit/a67807c8c2b00c6ce04d3abbdfafdf681a4de250))

## [2.27.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.27.2...v2.27.3) (2026-01-15)


### 🐛 Bug Fixes

* update beszel and n8n images to latest versions ([1b8f94d](https://github.com/Nebu2k/kubernetes-homelab/commit/1b8f94dac9a0d4ab56c4b87e5f82e72c8c4d5130))

## [2.27.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.27.1...v2.27.2) (2026-01-15)


### 🐛 Bug Fixes

* update fr24 ingress configuration and remove deprecated resources ([9320258](https://github.com/Nebu2k/kubernetes-homelab/commit/9320258ccb9c50d81d9f169772b8dbea77e191f2))

## [2.27.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.27.0...v2.27.1) (2026-01-15)


### 🐛 Bug Fixes

* update repoURL in fr24 application configuration ([1903978](https://github.com/Nebu2k/kubernetes-homelab/commit/1903978709a28a99e356ffa7a50504a461c97ce3))

## [2.27.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.26.0...v2.27.0) (2026-01-15)


### ✨ Features

* add fr24 application resources including deployment, service, ingress, and secrets ([6b98df4](https://github.com/Nebu2k/kubernetes-homelab/commit/6b98df4f1abcbdc406714d78805d4cecfc3d53ab))

## [2.26.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.25.7...v2.26.0) (2026-01-14)


### ✨ Features

* update minio ingress configuration and remove obsolete minio-ingress.yaml ([2679e30](https://github.com/Nebu2k/kubernetes-homelab/commit/2679e309584f6b0350cc814a25504631cf128fc7))

## [2.25.7](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.25.6...v2.25.7) (2026-01-14)


### 🐛 Bug Fixes

* add annotation to Longhorn volumeClaimTemplate for recurring job ([0d85900](https://github.com/Nebu2k/kubernetes-homelab/commit/0d8590054886e5b37b5d162508db5b6b7e9b4016))

## [2.25.6](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.25.5...v2.25.6) (2026-01-14)


### 🐛 Bug Fixes

* update Beszel references in configmap and ingress to use the correct host ([9f30aac](https://github.com/Nebu2k/kubernetes-homelab/commit/9f30aacaf12c457a215ef70ec2b05cc314ed6a60))

## [2.25.5](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.25.4...v2.25.5) (2026-01-14)


### 🐛 Bug Fixes

* update Beszel (Kubernetes) entry in configmap with new weight and remove duplicate ([210add7](https://github.com/Nebu2k/kubernetes-homelab/commit/210add7936237dfbc83100fd7876724eb33f137f))

## [2.25.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.25.3...v2.25.4) (2026-01-14)


### 🐛 Bug Fixes

* change imagePullPolicy to IfNotPresent for beszel-agent, beszel, and adguardhome-sync deployments ([9dfa33a](https://github.com/Nebu2k/kubernetes-homelab/commit/9dfa33a1ee881a96ad671fece9e3573bf275d096))

## [2.25.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.25.2...v2.25.3) (2026-01-14)


### 🐛 Bug Fixes

* **homepage:** update Beszel widget configuration in configmap ([30ea5f4](https://github.com/Nebu2k/kubernetes-homelab/commit/30ea5f43b8d1aabeb2581484b65fea39840eafa7))

## [2.25.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.25.1...v2.25.2) (2026-01-14)


### 🐛 Bug Fixes

* **ingress:** add pod-selector annotation to beszel-hub metadata ([f1b9a46](https://github.com/Nebu2k/kubernetes-homelab/commit/f1b9a46f56fe22d9d286c2afb926002d4e7a693b))
* **ingress:** remove pod-selector annotation from beszel-hub metadata ([43d117b](https://github.com/Nebu2k/kubernetes-homelab/commit/43d117b6cdb1787f5a6ef0167a57f0ab90d5c5e2))

## [2.25.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.25.0...v2.25.1) (2026-01-14)


### 🐛 Bug Fixes

* **kustomization:** add beszel-secret-sealed.yaml to resources ([f07a880](https://github.com/Nebu2k/kubernetes-homelab/commit/f07a8805ead6511884f23d26b739d8ae8c88df21))

## [2.25.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.24.2...v2.25.0) (2026-01-14)


### ✨ Features

* **beszel:** add SealedSecret for homepage-beszel and update ingress annotations ([e79a33e](https://github.com/Nebu2k/kubernetes-homelab/commit/e79a33e3863581cf315e8d4595f3f87f9b7493c7))

## [2.24.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.24.1...v2.24.2) (2026-01-14)


### ♻️ Code Refactoring

* **beszel:** remove SMTP configuration from deployment and secrets ([674e408](https://github.com/Nebu2k/kubernetes-homelab/commit/674e408366f3eb868bc0d4407daf9fb522b435b5))

## [2.24.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.24.0...v2.24.1) (2026-01-14)


### 🐛 Bug Fixes

* **deployment:** add missing annotations for reloader ([d34e152](https://github.com/Nebu2k/kubernetes-homelab/commit/d34e15263fd579611456e0a691ee544b9161d943))

## [2.24.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.23.4...v2.24.0) (2026-01-14)


### ✨ Features

* **beszel:** add SMTP configuration for email notifications ([f665daa](https://github.com/Nebu2k/kubernetes-homelab/commit/f665daad1706e2e5e968f5de2f277924e8198af0))

## [2.23.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.23.3...v2.23.4) (2026-01-14)


### 🐛 Bug Fixes

* **beszel:** add dnsPolicy to agent daemonset for cluster DNS resolution ([e239761](https://github.com/Nebu2k/kubernetes-homelab/commit/e2397618e8255a51582f468ade5251253ccc0d65))

## [2.23.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.23.2...v2.23.3) (2026-01-14)


### 🐛 Bug Fixes

* **beszel:** update HUB_URL environment variable to use internal service address ([04c56fd](https://github.com/Nebu2k/kubernetes-homelab/commit/04c56fdcb5861209637126146c66aadf4473592d))

## [2.23.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.23.1...v2.23.2) (2026-01-14)


### 🐛 Bug Fixes

* **beszel:** add TOKEN environment variable and update SealedSecret with TOKEN ([9721c68](https://github.com/Nebu2k/kubernetes-homelab/commit/9721c684ca857dec678a1865d1c02a628c594425))

## [2.23.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.23.0...v2.23.1) (2026-01-14)


### 🐛 Bug Fixes

* **beszel:** add HUB_URL environment variable to agent daemonset ([08d461a](https://github.com/Nebu2k/kubernetes-homelab/commit/08d461aac50ef5febd217e05f534703d59058e9f))

## [2.23.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.22.1...v2.23.0) (2026-01-14)


### ✨ Features

* **beszel:** add SealedSecret for SSH public key and update kustomization ([27676d7](https://github.com/Nebu2k/kubernetes-homelab/commit/27676d7d91b4326a43ac2cd33f77a585a2119184))

## [2.22.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.22.0...v2.22.1) (2026-01-14)


### 🐛 Bug Fixes

* **kustomization:** remove Beszel ingress from kustomization.yaml ([a346743](https://github.com/Nebu2k/kubernetes-homelab/commit/a3467437d29ae4ece9b398647bacd093609fdb6f))

## [2.22.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.21.0...v2.22.0) (2026-01-14)


### ✨ Features

* **kustomization:** add Beszel resource to kustomization.yaml ([c452a2f](https://github.com/Nebu2k/kubernetes-homelab/commit/c452a2f6247f696d76366b69864656a8cec7469f))

## [2.21.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.20.1...v2.21.0) (2026-01-14)


### ✨ Features

* **argocd:** add finalizers and retry configuration to application manifests ([7ce2042](https://github.com/Nebu2k/kubernetes-homelab/commit/7ce20425c2262dc84ac9bdf91301a6aea5fe26c5))
* **beszel:** add Beszel monitoring system with deployment manifests and configuration ([55815f0](https://github.com/Nebu2k/kubernetes-homelab/commit/55815f0bb88738d4eca197db22df0f4aa50e6576))
* **beszel:** add Beszel monitoring system with deployment manifests and configuration ([55293b0](https://github.com/Nebu2k/kubernetes-homelab/commit/55293b0b6c54d54a49f0742ac578a1578c66eaef))
* **beszel:** remove Beszel ingress and service definitions from manifests ([3a0777d](https://github.com/Nebu2k/kubernetes-homelab/commit/3a0777d880141cdd31fef5a8ada3be47746eb75e))
* **beszel:** update Beszel deployment manifests and configuration, including version pinning and SSH key management ([6c74c51](https://github.com/Nebu2k/kubernetes-homelab/commit/6c74c51bc121d9477b383c200253d5d0c0523b55))

## [2.20.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.20.0...v2.20.1) (2026-01-14)


### 🐛 Bug Fixes

* **adguard:** update AdGuard URL in configmap ([503cc5b](https://github.com/Nebu2k/kubernetes-homelab/commit/503cc5b91cb76bb017cb1609ae4570fecd00a89e))

## [2.20.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.19.0...v2.20.0) (2026-01-13)


### ✨ Features

* **teslamate:** add nodeSelector to deployments for worker nodes ([033df71](https://github.com/Nebu2k/kubernetes-homelab/commit/033df71d57e44c91a0a80014540d6e23980b6aa3))

## [2.19.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.18.0...v2.19.0) (2026-01-13)


### ✨ Features

* **adguard:** update weights and add pod selector for AdGuard services ([6ce7e47](https://github.com/Nebu2k/kubernetes-homelab/commit/6ce7e4767ddc7d7e51752dcad1118895a1694b3c))

## [2.18.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.17.3...v2.18.0) (2026-01-13)


### ✨ Features

* **sealed-secrets:** Update all + script to automate ([f358ff9](https://github.com/Nebu2k/kubernetes-homelab/commit/f358ff9a654387c8aa2ae10de72a94bd1019f6ff))

## [2.17.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.17.2...v2.17.3) (2026-01-13)


### 🐛 Bug Fixes

* **adguard:** update credentials in adguard-credentials-sealed.yaml ([bb58521](https://github.com/Nebu2k/kubernetes-homelab/commit/bb58521bacf8cc177b2979555a98196d956fcfef))

## [2.17.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.17.1...v2.17.2) (2026-01-13)


### 🐛 Bug Fixes

* **adguard:** update ADGUARD_HOST IP address in dns sync job ([2592ee0](https://github.com/Nebu2k/kubernetes-homelab/commit/2592ee013e77ae3af3eed4fd54684cb2aa438d3a))

## [2.17.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.17.0...v2.17.1) (2026-01-13)


### 🐛 Bug Fixes

* **coredns:** update forward addresses in coredns-custom.yaml ([d849d6c](https://github.com/Nebu2k/kubernetes-homelab/commit/d849d6c0f5a346ba6be6fe22b225ff82a434eb3b))

## [2.17.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.16.8...v2.17.0) (2026-01-13)


### ✨ Features

* **adguard:** add ingress configurations for adguard-pi5 and adguard-pve services ([6926764](https://github.com/Nebu2k/kubernetes-homelab/commit/69267643944b229fbe4066c6bcaaeba42b448996))

## [2.16.8](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.16.7...v2.16.8) (2026-01-13)


### 🐛 Bug Fixes

* **kustomization:** remove adguard-sync-ingress.yaml from resources ([54e70fd](https://github.com/Nebu2k/kubernetes-homelab/commit/54e70fd655a42e88eb220b4904254c351b7e5bd4))

## [2.16.7](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.16.6...v2.16.7) (2026-01-13)


### 🐛 Bug Fixes

* **adguard:** update origin instance details and add additional replica configuration in adguardhome-sync ([b5dfbde](https://github.com/Nebu2k/kubernetes-homelab/commit/b5dfbde70fdf94d8b1849dd5814b79cc3597a713))

## [2.16.6](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.16.5...v2.16.6) (2026-01-13)


### 🐛 Bug Fixes

* **adguard:** refactor initContainers and update volume mounts in adguardhome-sync deployment ([e0c874a](https://github.com/Nebu2k/kubernetes-homelab/commit/e0c874ad4a9afda76a9f8c4b0b082d792b1fcbb6))

## [2.16.5](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.16.4...v2.16.5) (2026-01-13)


### 🐛 Bug Fixes

* **adguard:** update credentials in sealed secret for adguardhome-sync ([697e51d](https://github.com/Nebu2k/kubernetes-homelab/commit/697e51d88077cc933f3a20b0025631d55f5fb1fa))

## [2.16.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.16.3...v2.16.4) (2026-01-13)


### 🐛 Bug Fixes

* **adguard:** update credentials in sealed secret for adguardhome-sync ([3440ccf](https://github.com/Nebu2k/kubernetes-homelab/commit/3440ccf84bf25623d76e5ffb872d81ecaa8e4d23))

## [2.16.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.16.2...v2.16.3) (2026-01-13)


### 🐛 Bug Fixes

* **adguard:** update credentials in sealed secret for adguardhome-sync ([c2f6a81](https://github.com/Nebu2k/kubernetes-homelab/commit/c2f6a81370b5e8fe8d4f2cd76d983e255574c97a))

## [2.16.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.16.1...v2.16.2) (2026-01-13)


### 🐛 Bug Fixes

* **adguard:** update ADGUARD_HOST to new IP address for DNS sync ([be2fd29](https://github.com/Nebu2k/kubernetes-homelab/commit/be2fd29c83ecc47f2ee5d3e450a885b54203cbf2))

## [2.16.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.16.0...v2.16.1) (2026-01-13)


### 🐛 Bug Fixes

* **adguard:** update command to use args for adguardhome-sync ([bf27e85](https://github.com/Nebu2k/kubernetes-homelab/commit/bf27e859d79878d857035f89759a9f967aaa098a))

## [2.16.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.15.10...v2.16.0) (2026-01-13)


### ✨ Features

* **adguard:** add AdGuard Home sync configuration and deployment resources ([957fcab](https://github.com/Nebu2k/kubernetes-homelab/commit/957fcabcd93b1d5854243680702963854bc9b94d))

## [2.15.10](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.15.9...v2.15.10) (2026-01-13)


### 🐛 Bug Fixes

* **kuma:** DNS resolver ([346c335](https://github.com/Nebu2k/kubernetes-homelab/commit/346c3351848230000f659a67aac09020dcc49629))

## [2.15.9](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.15.8...v2.15.9) (2026-01-12)


### 🐛 Bug Fixes

* **ingress:** update cluster-issuer annotation for minio-console to internal-ca-issuer ([496b13b](https://github.com/Nebu2k/kubernetes-homelab/commit/496b13b19c827c362ea40c146f9a3a71e6f2d450))

## [2.15.8](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.15.7...v2.15.8) (2026-01-12)


### 🐛 Bug Fixes

* **kustomization:** remove newt.yaml from resources ([7894f6b](https://github.com/Nebu2k/kubernetes-homelab/commit/7894f6bf690e7296da81bc0c9940a05867714ced))

## [2.15.7](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.15.6...v2.15.7) (2026-01-12)


### 🐛 Bug Fixes

* **readme:** add ArgoCD version to the documentation ([a64fb3a](https://github.com/Nebu2k/kubernetes-homelab/commit/a64fb3a2f372787058d1c92e7d6f2a696fa64fc3))

## [2.15.6](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.15.5...v2.15.6) (2026-01-12)


### 🐛 Bug Fixes

* **minio:** update MinIO image to a specific release version ([a079e31](https://github.com/Nebu2k/kubernetes-homelab/commit/a079e319eeeb796eb7b621ad007ce08112996365))

## [2.15.5](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.15.4...v2.15.5) (2026-01-12)


### 🐛 Bug Fixes

* **generate_readme:** enhance component version extraction for Helm charts and direct manifests ([b90af73](https://github.com/Nebu2k/kubernetes-homelab/commit/b90af731d571425f4842f1a6ecdabc6b3ec05341))

## [2.15.4](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.15.3...v2.15.4) (2026-01-08)


### 🐛 Bug Fixes

* **minio:** add missing label for MinIO deployment ([8bb3ab4](https://github.com/Nebu2k/kubernetes-homelab/commit/8bb3ab481856e72e20fb2cb17445d0848999fb0d))

## [2.15.3](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.15.2...v2.15.3) (2026-01-08)


### 🐛 Bug Fixes

* **minio:** update name annotation for MinIO Console to include 'K8s' ([67e287c](https://github.com/Nebu2k/kubernetes-homelab/commit/67e287c9747f74a151b2c74159254f6a754ae807))

## [2.15.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.15.1...v2.15.2) (2026-01-08)


### 🐛 Bug Fixes

* **minio:** remove minio-middleware.yaml from repository ([6103ea4](https://github.com/Nebu2k/kubernetes-homelab/commit/6103ea476d93db2053450de9991a88adb7f33d7c))

## [2.15.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.15.0...v2.15.1) (2026-01-08)


### 🐛 Bug Fixes

* **minio:** remove minio-middleware.yaml from kustomization resources ([ab7c450](https://github.com/Nebu2k/kubernetes-homelab/commit/ab7c450d183ee0f6962ded1d9a5d0374b074eb0d))

## [2.15.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.14.0...v2.15.0) (2026-01-08)


### ✨ Features

* **minio:** add pod selector annotation for MinIO console ([c11e65d](https://github.com/Nebu2k/kubernetes-homelab/commit/c11e65dd3d3c223af625c1e016e235e29953ada9))

## [2.14.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.13.1...v2.14.0) (2026-01-08)


### ✨ Features

* **longhorn:** update S3 backup target to use aws ([fe491da](https://github.com/Nebu2k/kubernetes-homelab/commit/fe491daabbfa59c6fb69f38a4f1c73ea43e71fa5))

## [2.13.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.13.0...v2.13.1) (2026-01-08)


### 🐛 Bug Fixes

* **minio:** add minio-middleware configuration and update resource references ([4941cdf](https://github.com/Nebu2k/kubernetes-homelab/commit/4941cdf6155ad852883bbbd322494ced7b029de9))

## [2.13.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.12.0...v2.13.0) (2026-01-08)


### ✨ Features

* **minio:** add MinIO application with necessary resources and configurations ([3b9667b](https://github.com/Nebu2k/kubernetes-homelab/commit/3b9667b73e6f909588e63e6e164224f0c737d297))

## [2.12.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.11.2...v2.12.0) (2026-01-08)


### ✨ Features

* **check-versions:** enhance GHCR tag retrieval with OAuth support and improve version comparison logic ([ec2a108](https://github.com/Nebu2k/kubernetes-homelab/commit/ec2a108b1d6bbd2175b363868dc6e26a4b0e252d))

## [2.11.2](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.11.1...v2.11.2) (2026-01-08)


### 🐛 Bug Fixes

* **deployment:** revert pve-exporter image tag to 1.0.8 ([0634b8d](https://github.com/Nebu2k/kubernetes-homelab/commit/0634b8dab580cdc5e903207adc43b16a8c073631))

## [2.11.1](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.11.0...v2.11.1) (2026-01-08)


### 🐛 Bug Fixes

* **deployment:** correct image tag format for proxmox-exporter ([0767b75](https://github.com/Nebu2k/kubernetes-homelab/commit/0767b75d04f203020fb3d0f3733e00cfc810a7dd))

## [2.11.0](https://github.com/Nebu2k/kubernetes-homelab/compare/v2.10.0...v2.11.0) (2026-01-08)


### ✨ Features

* **deployment:** update image tags for n8n and proxmox-exporter ([d156981](https://github.com/Nebu2k/kubernetes-homelab/commit/d156981cd7f60d8ac4387877331522cc6c2e35eb))

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
