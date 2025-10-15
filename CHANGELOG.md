# Changelog

All notable changes are documented in this file.

## v1.3.2
### Added
- `mongodb_network_reservation_ip_offset` to allow set offset in mongo IP reservation

## v1.3.1
### Updated
- `external-dns` from bitnami to kubernetes-sigs `1.19.0`

## v1.3.0
### Added
- customizable node pools via the `kubernetes_node_pools` variable
### Updated
- `network_address_space` to `10.0.0.0/20`
- `terraform-google-modules/kubernetes-engine/google//modules/private-cluster` to `~> 39.0`
- allow specification of existing network resources for PCS components

## v1.2.3
### Added
- `create_ingress_psc` to expose the Kubernetes ingress via Private Service Connect

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
