# Changelog

All notable changes are documented in this file.



## v1.2.2

### Added
- `mongodb` module to create a Mongodb Atlas project and cluster


## v1.2.1

### Added
- `redis` module to create a Memorystore Redis instance


## v1.2.0

### Added
- `postgres` module to create a CloudSQL for PostgreSQL instance


## v1.1.7

### Added
- `kubeworker-sa` to `datarobot_service_accounts` default value


## v1.1.6

### Updated
- `helm` provider to `3.0`


## v1.1.5

### Added
- `install_helm_charts` variable to be able to enable/disable installation of all helm charts


## v1.1.4

### Updated
- use helm_release instead of terraform-module/release/helm


## v1.1.3

### Updated

- README for DataRobot version description


## v1.1.2

### Updated

- update datarobot_service_accounts defaults for 11.0


## v1.1.1

### Updated
- ingress-nginx helm chart version to 4.11.5


## v1.1.0

### Added
- Allow specifying existing GKE cluster via the existing_gke_cluster_name variable
- descheduler amenity
- customizable namespaces for amenities
- grant project registry access to the GKE cluster by default

### Updated
- Autoscaling behavior to use OPTIMIZE_UTILIZATION autoscaling profile


## v1.0.0

### Added

- Initial module release
