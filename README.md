# terraform-google-dr-infra
Terraform module to create Google Cloud infrastructure resources required to run DataRobot.

## Usage
```
module "datarobot_infra" {
  source = "datarobot-oss/dr-infra/google"

  name              = "datarobot"
  google_project_id = "your-google-project-id"
  region            = "us-west1"
  domain_name       = "datarobot.example.com"

  cert_manager_letsencrypt_email_address = "you@example.com"

  tags = {
    environment = "dev"
    managed-by  = "terraform"
  }
}
```

## Examples
- [Complete](examples/complete) - Demonstrates all available input variables.
- [Public](examples/public) - Minimal configuration for a publicly accessible deployment (internet-facing load balancer, public GKE API endpoint).
- [Private](examples/private) - Minimal configuration for a private deployment (internal load balancer, private-only GKE API endpoint, existing VPC).

### Using an example directly from source
1. Clone the repo
```bash
git clone https://github.com/datarobot-oss/terraform-google-dr-infra.git
```
2. Change directories into the example that best aligns with your use-case.
```bash
cd terraform-google-dr-infra/examples/public
```
3. Modify `main.tf` to suit your specific use-case.
4. Run terraform.
```bash
terraform init
terraform apply
```

## Module Descriptions

### Network
#### Toggle
- `create_network` to create a new Google VPC
- `existing_vpc_name`, `existing_kubernetes_nodes_subnet`, and `existing_kubernetes_pods_range_name` to use an existing VPC and subnet

#### Description
Create a new Google VPC with one subnet using a `/20` slice of `network_address_space` and a NAT gateway attached.

`kubernetes_pod_cidr` and `kubernetes_service_cidr` are secondary ranges within the subnet which will be used for the Kubernetes pod and service IPs, respectively.

Only the priamry the `kubernetes_pod_cidr` IPs are attached to the Cloud NAT gateway.

#### Permissions
TBD


### DNS
#### Toggle
- `create_dns_zone` to create a new Google Cloud DNS managed zone
- `existing_dns_zone_name` to use an existing Google Cloud DNS managed zone

#### Description
Creates a new Cloud DNS managed zone for `domain_name`. When `dns_zone_public` is `true` (the default) a public zone is created; when `false` a private zone is created for the given VPC.

The Cloud DNS zone is used by `external_dns` to manage DNS records for the resources created by the DataRobot application. When the zone is public it is also used for DNS validation when using `cert_manager` and `cert_manager_letsencrypt_clusterissuers`.

#### Permissions
TBD


### Storage
#### Toggle
- `create_storage` to create a new Google Cloud Storage Bucket
- `existing_gcs_bucket_name` to use an existing Google Cloud Storage Bucket

#### Description
Create a new GCS Bucket with prefix `name` and name `datarobot`.

The DataRobot application will use this storage account for persistent file storage.

#### Permissions
TBD


### Container Registry
#### Toggle
- `create_container_registry` to create a new Google Artifact Registry Repository
- `existing_artifact_registry_repo_id` to use an existing Google Artifact Registry Repository

#### Description
Create a new GAR repository with name `name`.

The DataRobot application will use this registry to host custom images created by various services.

#### Permissions
TBD


### Kubernetes
#### Toggle
- `create_kubernetes_cluster` to create a new Google Kubernetes Engine Cluster
- `existing_gke_cluster_name` to use an existing GKE cluster

#### Description
Create a new GKE cluster to host the DataRobot application and any other helm charts installed by this module.

By default, the Kubernetes cluster API endpoint is accessible both via a private endpoint created within the same VPC as well as publicly over the internet. GKE nodes always communicate with the control plane using the private IP address. Public endpoint access can be restricted using the `kubernetes_cluster_endpoint_access_list` variable or disabled completely by setting `kubernetes_cluster_endpoint_public_access` to `false`.

When `kubernetes_cluster_endpoint_public_access` is `false`, Kubernetes management operations such as `kubectl` and `helm` commands (including the Helm chart installs performed by this Terraform module) must be run from a host which can access the Kubernetes cluster API private endpoint. By default, any host within the GKE nodes subnet has access but this can be extended using the `kubernetes_cluster_endpoint_access_list` variable. This can be helpful when running this Terraform module from a host that resides within the same VPC as the GKE cluster but in a different subnet than the GKE nodes.

Two node groups are created:
- A `drcpu` node group intended to host the majority of the DataRobot pods
- A `drgpu` node group intended to host GPU workload pods containing the label `datarobot.com/node-capability: gpu` and taint `nvidia.com/gpu:NoSchedule`

By default, slices of `network_address_space` will be used for the cluster nodes and control plane private endpoint IPs. It is best to use a separate address space for `kubernetes_pod_cidr` as it is a secondary (aliased) range.

#### Permissions
TBD


### App Identity
#### Toggle
- `create_app_identity` to create a new Google Service account to represent the DataRobot application

#### Description
Create a new GKE Service Account with `roles/storage.admin` access to the Google Cloud Storage bucket and `roles/artifactregistry.writer` access to the Google Artifact Registry Repository.

Workload identities are created for each `datarobot_service_accounts` within the `datarobot_namespace` and attached to this Service Account. This allows those pods running with those service accounts to access file storage and the artifact registry.

#### Permissions
TBD


### Postgres
#### Toggle
- `create_postgres` to create a new Cloud SQL for PostgreSQL instance

#### Description
Create an Cloud SQL for PostgreSQL connected to via service networking.

#### Permissions
TBD


### Redis
#### Toggle
- `create_redis` to create a new Memorystore Redis instance

#### Description
Create a Memorystore Redis instance connected to via service networking.

#### Permissions
TBD


### MongoDB
#### Toggle
- `create_mongodb` to create a new MongoDB Atlas cluster

#### Description
Create a MongoDB Atlas project and cluster for use by the DataRobot application.

#### Permissions
TBD


### Helm Chart - ingress-nginx
#### Toggle
- `ingress_nginx` to install the `ingress-nginx` helm chart

#### Description
Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `https://kubernetes.github.io/ingress-nginx/ingress-nginx` helm chart into the `ingress-nginx` namespace.

The `ingress-nginx` helm chart will trigger the deployment of an Google Network Load Balancer directing traffic to the `ingress-nginx-controller` Kubernetes services.

Values passed to the helm chart can be overridden by passing a custom values file via the `ingress_nginx_values` variable as demonstrated in the [complete example](examples/complete/main.tf).


#### Permissions
Not required


### Helm Chart - cert-manager
#### Toggle
- `cert_manager` to install the `cert-manager` helm chart

#### Description
Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `https://charts.jetstack.io/cert-manager` helm chart into the `cert-manager` namespace.

A Google Service Account is created for the `cert-manager` Kubernetes service account running in the `cert-manager` namespace that allows the creation of DNS resources within the specified DNS zone.

`cert-manager` can be used by the DataRobot application to create and manage various certificates including the application.

When `cert_manager_letsencrypt_clusterissuers` is enabled, `letsencrypt-staging` and `letsencrypt-prod` ClusterIssuers will be created which can be used by the `datarobot-google` umbrella chart to issue certificates used by the DataRobot application. The default values in that helm chart (as of version 10.2) have `global.ingress.tls.enabled`, `global.ingress.tls.certmanager`, and `global.ingress.tls.issuer` as `letsencrypt-prod` which will use the `letsencrypt-prod` ClusterIssuer to issue a public ACME certificate as the TLS certificate used by the Kubernetes ingress resources.

Values passed to the helm chart can be overridden by passing a custom values file via the `cert_manager_values` variable as demonstrated in the [complete example](examples/complete/main.tf).

#### Permissions
TBD


### Helm Chart - external-dns
#### Toggle
- `external_dns` to install the `external-dns` helm chart

#### Description
Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `https://charts.bitnami.com/bitnami/external-dns` helm chart into the `external-dns` namespace.

A Google Service Account is created for the `external-dns` Kubernetes service account running in the `external-dns` namespace that allows the creation of DNS resources within the specified DNS zone.

`external-dns` is used to automatically create DNS records for ingress resources in the Kubernetes cluster. When the DataRobot application is installed and the ingress resources are created, `external-dns` will automatically create a DNS record pointing at the ingress resource.

Values passed to the helm chart can be overridden by passing a custom values file via the `external_dns_values` variable as demonstrated in the [complete example](examples/complete/main.tf).

#### Permissions
TBD


### Helm Chart - nvidia-device-plugin
#### Toggle
- `nvidia_device_plugin` to install the `nvidia-device-plugin` helm chart

#### Description
Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `https://nvidia.github.io/k8s-device-plugin/nvidia-device-plugin` helm chart into the `nvidia-device-plugin` namespace.

Values passed to the helm chart can be overridden by passing a custom values file via the `nvidia_device_plugin_values` variable as demonstrated in the [complete example](examples/complete/main.tf).

#### Permissions
Not required


### Helm Chart - descheduler
#### Toggle
- `descheduler` to install the `descheduler` helm chart

#### Description
Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `descheduler` helm chart from the `https://kubernetes-sigs.github.io/descheduler/` helm repo into the `kube-system` namespace.

This helm chart allows for automatic rescheduling of pods for optimizing resource consumption.

#### Permissions
Not required


### Comprehensive Required Permissions
TBD


## DataRobot versions
Currently the only thing coupling a release of this module to a DataRobot Enterprise Release is the default list of datarobot_service_accounts. Technically, this module can be used with any DataRobot version if the user specifies the correct list of datarobot_service_accounts for that version.

The default installation supports DataRobot versions >= 10.0.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.6.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.0.2 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.19 |
| <a name="requirement_mongodbatlas"></a> [mongodbatlas](#requirement\_mongodbatlas) | ~> 2.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_app_identity"></a> [app\_identity](#module\_app\_identity) | terraform-google-modules/service-accounts/google | ~> 4.0 |
| <a name="module_cert_manager"></a> [cert\_manager](#module\_cert\_manager) | ./modules/cert-manager | n/a |
| <a name="module_cloud_router"></a> [cloud\_router](#module\_cloud\_router) | terraform-google-modules/cloud-router/google | ~> 6.1 |
| <a name="module_custom_endpoints"></a> [custom\_endpoints](#module\_custom\_endpoints) | ./modules/custom-private-endpoints | n/a |
| <a name="module_descheduler"></a> [descheduler](#module\_descheduler) | ./modules/descheduler | n/a |
| <a name="module_dns"></a> [dns](#module\_dns) | terraform-google-modules/cloud-dns/google | ~> 5.0 |
| <a name="module_external_dns"></a> [external\_dns](#module\_external\_dns) | ./modules/external-dns | n/a |
| <a name="module_ingress_nginx"></a> [ingress\_nginx](#module\_ingress\_nginx) | ./modules/ingress-nginx | n/a |
| <a name="module_kubernetes"></a> [kubernetes](#module\_kubernetes) | terraform-google-modules/kubernetes-engine/google//modules/private-cluster | ~> 39.0 |
| <a name="module_mongodb"></a> [mongodb](#module\_mongodb) | ./modules/mongodb | n/a |
| <a name="module_network"></a> [network](#module\_network) | terraform-google-modules/network/google | ~> 9.0 |
| <a name="module_nvidia_device_plugin"></a> [nvidia\_device\_plugin](#module\_nvidia\_device\_plugin) | ./modules/nvidia-device-plugin | n/a |
| <a name="module_observability"></a> [observability](#module\_observability) | ./modules/observability | n/a |
| <a name="module_postgres"></a> [postgres](#module\_postgres) | terraform-google-modules/sql-db/google//modules/postgresql | ~> 26.0 |
| <a name="module_private_link_service"></a> [private\_link\_service](#module\_private\_link\_service) | ./modules/private-link-service | n/a |
| <a name="module_redis"></a> [redis](#module\_redis) | terraform-google-modules/memorystore/google | ~> 15.0 |
| <a name="module_storage"></a> [storage](#module\_storage) | terraform-google-modules/cloud-storage/google | ~> 8.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_artifact_registry_repository.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository) | resource |
| [google_artifact_registry_repository_iam_member.datarobot](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_member) | resource |
| [google_compute_global_address.postgres](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_compute_global_address.redis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_service_account_iam_member.datarobot](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_service_networking_connection.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_networking_connection) | resource |
| [google_storage_bucket_iam_member.datarobot](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_client_config.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_compute_network.existing](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network) | data source |
| [google_compute_subnetwork.existing_ingress_psc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork) | data source |
| [google_compute_subnetwork.existing_kubernetes_nodes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork) | data source |
| [google_compute_subnetwork.existing_mongodb](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork) | data source |
| [google_container_cluster.existing](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/container_cluster) | data source |
| [google_dns_managed_zone.existing](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/dns_managed_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allow_psc_global_access"></a> [allow\_psc\_global\_access](#input\_allow\_psc\_global\_access) | Whether to allow global access for Private Service Connect | `bool` | `false` | no |
| <a name="input_cert_manager"></a> [cert\_manager](#input\_cert\_manager) | Install the cert-manager helm chart. All other cert\_manager variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_cert_manager_letsencrypt_clusterissuers"></a> [cert\_manager\_letsencrypt\_clusterissuers](#input\_cert\_manager\_letsencrypt\_clusterissuers) | Whether to create letsencrypt-prod and letsencrypt-staging ClusterIssuers. This will only work if the DNS zone is public. | `bool` | `true` | no |
| <a name="input_cert_manager_letsencrypt_email_address"></a> [cert\_manager\_letsencrypt\_email\_address](#input\_cert\_manager\_letsencrypt\_email\_address) | Email address for the certificate owner. Let's Encrypt will use this to contact you about expiring certificates, and issues related to your account. Only required if cert\_manager\_letsencrypt\_clusterissuers is true. | `string` | `"user@example.com"` | no |
| <a name="input_cert_manager_values_overrides"></a> [cert\_manager\_values\_overrides](#input\_cert\_manager\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_create_app_identity"></a> [create\_app\_identity](#input\_create\_app\_identity) | Create a new user assigned identity for the DataRobot application | `bool` | `true` | no |
| <a name="input_create_container_registry"></a> [create\_container\_registry](#input\_create\_container\_registry) | Create a new Google Container Registry. Ignored if an existing existing\_artifact\_registry\_repo\_id is specified. | `bool` | `true` | no |
| <a name="input_create_dns_zone"></a> [create\_dns\_zone](#input\_create\_dns\_zone) | Create a Cloud DNS managed zone for domain\_name. Ignored if existing\_dns\_zone\_name is specified. | `bool` | `true` | no |
| <a name="input_create_ingress_psc"></a> [create\_ingress\_psc](#input\_create\_ingress\_psc) | Expose the internal LB created by the ingress-nginx controller as a Google Private Service Connection. Only applies if internet\_facing\_ingress\_lb is false. | `bool` | `false` | no |
| <a name="input_create_ingress_psc_namespace"></a> [create\_ingress\_psc\_namespace](#input\_create\_ingress\_psc\_namespace) | Whether to create a namespace for the ingress private service connect | `bool` | `false` | no |
| <a name="input_create_kubernetes_cluster"></a> [create\_kubernetes\_cluster](#input\_create\_kubernetes\_cluster) | Create a new Google Kubernetes Engine cluster. All kubernetes and helm chart variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_create_mongodb"></a> [create\_mongodb](#input\_create\_mongodb) | Whether to create a MongoDB Atlas instance | `bool` | `false` | no |
| <a name="input_create_network"></a> [create\_network](#input\_create\_network) | Create a new Google VPC. Ignored if an existing existing\_vpc\_id is specified. | `bool` | `true` | no |
| <a name="input_create_observability"></a> [create\_observability](#input\_create\_observability) | Whether to provision observability resources | `bool` | `false` | no |
| <a name="input_create_postgres"></a> [create\_postgres](#input\_create\_postgres) | Whether to create a CloudSQL for PostgreSQL instance | `bool` | `false` | no |
| <a name="input_create_redis"></a> [create\_redis](#input\_create\_redis) | Whether to create a Google Memorystore Redis instance | `bool` | `false` | no |
| <a name="input_create_storage"></a> [create\_storage](#input\_create\_storage) | Create a new Google Storage Bucket to use for DataRobot file storage. Ignored if an existing\_gcs\_bucket\_name is specified. | `bool` | `true` | no |
| <a name="input_custom_private_endpoints"></a> [custom\_private\_endpoints](#input\_custom\_private\_endpoints) | Configuration for the specific endpoint | <pre>list(object({<br/>    service_name     = string<br/>    private_dns_zone = optional(string, "")<br/>    private_dns_name = optional(string, "")<br/>  }))</pre> | `[]` | no |
| <a name="input_datarobot_namespace"></a> [datarobot\_namespace](#input\_datarobot\_namespace) | Kubernetes namespace in which the DataRobot application will be installed | `string` | `"dr-app"` | no |
| <a name="input_datarobot_service_accounts"></a> [datarobot\_service\_accounts](#input\_datarobot\_service\_accounts) | Kubernetes service accounts in the datarobot\_namespace to provide with Storage Blob Data Contributor and AcrPush access | `set(string)` | <pre>[<br/>  "datarobot-storage-sa",<br/>  "dynamic-worker",<br/>  "kubeworker-sa",<br/>  "prediction-server-sa",<br/>  "internal-api-sa",<br/>  "build-service",<br/>  "tileservergl-sa",<br/>  "nbx-notebook-revisions-account",<br/>  "buzok-account",<br/>  "exec-manager-qw",<br/>  "exec-manager-wrangling",<br/>  "lrs-job-manager",<br/>  "blob-view-service"<br/>]</pre> | no |
| <a name="input_descheduler"></a> [descheduler](#input\_descheduler) | Install the descheduler helm chart to enable rescheduling of pods. All other descheduler variables are ignored if this variable is false | `bool` | `true` | no |
| <a name="input_descheduler_values_overrides"></a> [descheduler\_values\_overrides](#input\_descheduler\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_dns_zone_force_destroy"></a> [dns\_zone\_force\_destroy](#input\_dns\_zone\_force\_destroy) | Force destroy the Cloud DNS managed zone. Ignored if an existing\_dns\_zone\_name is specified or create\_dns\_zone is false. | `bool` | `false` | no |
| <a name="input_dns_zone_public"></a> [dns\_zone\_public](#input\_dns\_zone\_public) | Create a public Cloud DNS managed zone. When `false`, a private zone will be created for the given VPC. | `bool` | `true` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Name of the domain to use for the DataRobot application. If create\_dns\_zone is true then a zone will be created for this domain. It is also used by the cert-manager helm chart for DNS validation and as a domain filter by the external-dns helm chart. | `string` | `""` | no |
| <a name="input_existing_artifact_registry_repo_id"></a> [existing\_artifact\_registry\_repo\_id](#input\_existing\_artifact\_registry\_repo\_id) | ID of existing artifact registry repository to use | `string` | `null` | no |
| <a name="input_existing_dns_zone_name"></a> [existing\_dns\_zone\_name](#input\_existing\_dns\_zone\_name) | Name of an existing Cloud DNS managed zone to use. When specified, all other DNS variables will be ignored. | `string` | `null` | no |
| <a name="input_existing_gcs_bucket_name"></a> [existing\_gcs\_bucket\_name](#input\_existing\_gcs\_bucket\_name) | ID of existing Google Storage Bucket to use for DataRobot file storage. When specified, all other storage variables will be ignored. | `string` | `null` | no |
| <a name="input_existing_gke_cluster_name"></a> [existing\_gke\_cluster\_name](#input\_existing\_gke\_cluster\_name) | Name of existing GKE cluster to use. When specified, all other kubernetes variables will be ignored. | `string` | `null` | no |
| <a name="input_existing_ingress_pcs_subnet_name"></a> [existing\_ingress\_pcs\_subnet\_name](#input\_existing\_ingress\_pcs\_subnet\_name) | Name of an existing subnet to use for the Private Service Connection used by the ingress-nginx controller. Required when an existing\_vpc\_name is specified and create\_ingress\_psc is true. Ignored if no existing\_vpc\_name is specified or create\_ingress\_psc is false. | `string` | `null` | no |
| <a name="input_existing_kubernetes_nodes_subnet"></a> [existing\_kubernetes\_nodes\_subnet](#input\_existing\_kubernetes\_nodes\_subnet) | Name of an existing subnet to use for the GKE node pools and control plane private endpoint. Required when `create_kubernetes_cluster` is `true` and an `existing_vpc_name` is specified. Ignored if no `existing_vpc_name` is specified. | `string` | `null` | no |
| <a name="input_existing_kubernetes_pods_range_name"></a> [existing\_kubernetes\_pods\_range\_name](#input\_existing\_kubernetes\_pods\_range\_name) | Name of an secondary IP range within subnet defined by existing\_kubernetes\_nodes\_subnet\_name to use for the Kubernetes pods. Required when an existing\_vpc\_name is specified. Ignored if no existing\_vpc\_name is specified. | `string` | `null` | no |
| <a name="input_existing_mongodb_subnet_name"></a> [existing\_mongodb\_subnet\_name](#input\_existing\_mongodb\_subnet\_name) | Name of an existing subnet to use for MongoDB Atlas VPC Peering. Required when an existing\_vpc\_name is specified. Ignored if no existing\_vpc\_name is specified. | `string` | `null` | no |
| <a name="input_existing_vpc_name"></a> [existing\_vpc\_name](#input\_existing\_vpc\_name) | Name of an existing Google VPC to use. When specified, other network variables are ignored. | `string` | `null` | no |
| <a name="input_external_dns"></a> [external\_dns](#input\_external\_dns) | Install the external\_dns helm chart to manage DNS records for resources created by the application. All other external\_dns variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_external_dns_values_overrides"></a> [external\_dns\_values\_overrides](#input\_external\_dns\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_gcr_registry_name"></a> [gcr\_registry\_name](#input\_gcr\_registry\_name) | Name of the Artifact Registry repository. Defaults to the name if not specified. | `string` | `null` | no |
| <a name="input_google_project_id"></a> [google\_project\_id](#input\_google\_project\_id) | The ID of the Google Project where these resources will be created | `string` | n/a | yes |
| <a name="input_ingress_nginx"></a> [ingress\_nginx](#input\_ingress\_nginx) | Install the ingress-nginx helm chart to use as the ingress controller for the GKE cluster. All other ingress\_nginx variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_ingress_nginx_values_overrides"></a> [ingress\_nginx\_values\_overrides](#input\_ingress\_nginx\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_ingress_psc_consumer_projects"></a> [ingress\_psc\_consumer\_projects](#input\_ingress\_psc\_consumer\_projects) | The list of consumer project IDs that are allowed to connect to the ServiceAttachment. This field can only be used when connectionPreference is ACCEPT\_MANUAL. | `list(string)` | `[]` | no |
| <a name="input_ingress_psc_subnet_cidr"></a> [ingress\_psc\_subnet\_cidr](#input\_ingress\_psc\_subnet\_cidr) | CIDR range to use for the Private Service Connection used by the ingress-nginx controller. Only used when `create_network` is `true` and an `existing_vpc_name` is not specified. | `string` | `null` | no |
| <a name="input_ingress_service_name"></a> [ingress\_service\_name](#input\_ingress\_service\_name) | The name of the ingress service to attach the private link to. | `string` | `"ingress-nginx-controller"` | no |
| <a name="input_install_helm_charts"></a> [install\_helm\_charts](#input\_install\_helm\_charts) | Whether to install helm charts into the target EKS cluster. All other helm chart variables are ignored if this is `false`. | `bool` | `true` | no |
| <a name="input_internet_facing_ingress_lb"></a> [internet\_facing\_ingress\_lb](#input\_internet\_facing\_ingress\_lb) | Determines the type of Load Balancer created for GKE ingress. If true, an external Load Balancer will be created. If false, an internal Load Balancer will be created. | `bool` | `true` | no |
| <a name="input_kubernetes_cluster_deletion_protection"></a> [kubernetes\_cluster\_deletion\_protection](#input\_kubernetes\_cluster\_deletion\_protection) | Enable deletion protection on the GKE cluster | `bool` | `true` | no |
| <a name="input_kubernetes_cluster_endpoint_access_list"></a> [kubernetes\_cluster\_endpoint\_access\_list](#input\_kubernetes\_cluster\_endpoint\_access\_list) | List of CIDRs allowed to access the Kubernetes cluster API endpoint. When kubernetes\_cluster\_endpoint\_public\_access is true, these CIDRs specify which public IP addresses are allowed to access the Kubernetes cluster API external endpoint. When kubernetes\_cluster\_endpoint\_public\_access is false, these CIDRs specify which private IP addresses are allowed to access the Kubernetes cluster API internal endpoint. By default, only hosts within the kubernetes nodes subnet are allowed to access the Kubernetes cluster API internal endpoint. | `list(string)` | `[]` | no |
| <a name="input_kubernetes_cluster_endpoint_public_access"></a> [kubernetes\_cluster\_endpoint\_public\_access](#input\_kubernetes\_cluster\_endpoint\_public\_access) | Whether the Kubernetes cluster API endpoint can be accessed via an external IP address | `bool` | `true` | no |
| <a name="input_kubernetes_cluster_grant_registry_access"></a> [kubernetes\_cluster\_grant\_registry\_access](#input\_kubernetes\_cluster\_grant\_registry\_access) | Grants created cluster-specific service account storage.objectViewer and artifactregistry.reader roles | `bool` | `true` | no |
| <a name="input_kubernetes_cluster_version"></a> [kubernetes\_cluster\_version](#input\_kubernetes\_cluster\_version) | GKE cluster version | `string` | `"latest"` | no |
| <a name="input_kubernetes_master_ipv4_cidr"></a> [kubernetes\_master\_ipv4\_cidr](#input\_kubernetes\_master\_ipv4\_cidr) | The IP range in CIDR notation to use for the hosted master network including the Kubernetes control plane. If you use this flag, GKE creates a new subnet that uses the values you defined in master-ipv4-cidr and uses the new subnet to provision the internal IP address for the control plane. | `string` | `null` | no |
| <a name="input_kubernetes_node_pools"></a> [kubernetes\_node\_pools](#input\_kubernetes\_node\_pools) | Map of GKE node pools | `any` | <pre>{<br/>  "drcpu": {<br/>    "disk_size_gb": 200,<br/>    "machine_type": "e2-standard-32",<br/>    "max_count": 10,<br/>    "min_count": 1,<br/>    "name": "drcpu",<br/>    "node_count": 1,<br/>    "node_labels": {<br/>      "datarobot.com/node-capability": "cpu"<br/>    },<br/>    "node_taints": []<br/>  },<br/>  "drgpu": {<br/>    "max_count": 10,<br/>    "min_count": 0,<br/>    "name": "drgpu",<br/>    "node_count": 0,<br/>    "node_labels": {<br/>      "datarobot.com/node-capability": "gpu"<br/>    },<br/>    "node_taints": [<br/>      {<br/>        "effect": "NO_SCHEDULE",<br/>        "key": "nvidia.com/gpu",<br/>        "value": "true"<br/>      }<br/>    ],<br/>    "vm_size": "n1-highmem-4"<br/>  }<br/>}</pre> | no |
| <a name="input_kubernetes_nodes_cidr"></a> [kubernetes\_nodes\_cidr](#input\_kubernetes\_nodes\_cidr) | The CIDR to use for Kubernetes nodes IP addresses. This is used as the primary IP range for the Kubernetes nodes subnet. | `string` | `null` | no |
| <a name="input_kubernetes_pod_cidr"></a> [kubernetes\_pod\_cidr](#input\_kubernetes\_pod\_cidr) | The CIDR to use for Kubernetes pod IP addresses. This is used as a secondary IP range within the Kubernetes nodes subnet. | `string` | `"172.16.0.0/15"` | no |
| <a name="input_mongodb_admin_username"></a> [mongodb\_admin\_username](#input\_mongodb\_admin\_username) | MongoDB admin username | `string` | `"pcs-mongodb"` | no |
| <a name="input_mongodb_atlas_auto_scaling_disk_gb_enabled"></a> [mongodb\_atlas\_auto\_scaling\_disk\_gb\_enabled](#input\_mongodb\_atlas\_auto\_scaling\_disk\_gb\_enabled) | Enable Atlas disk size autoscaling | `bool` | `true` | no |
| <a name="input_mongodb_atlas_disk_size"></a> [mongodb\_atlas\_disk\_size](#input\_mongodb\_atlas\_disk\_size) | Starting atlas disk size | `string` | `"20"` | no |
| <a name="input_mongodb_atlas_instance_type"></a> [mongodb\_atlas\_instance\_type](#input\_mongodb\_atlas\_instance\_type) | atlas instance type | `string` | `"M30"` | no |
| <a name="input_mongodb_atlas_org_id"></a> [mongodb\_atlas\_org\_id](#input\_mongodb\_atlas\_org\_id) | Atlas organization ID | `string` | `null` | no |
| <a name="input_mongodb_atlas_private_key"></a> [mongodb\_atlas\_private\_key](#input\_mongodb\_atlas\_private\_key) | Private API key for Mongo Atlas | `string` | `""` | no |
| <a name="input_mongodb_atlas_public_key"></a> [mongodb\_atlas\_public\_key](#input\_mongodb\_atlas\_public\_key) | Public API key for Mongo Atlas | `string` | `""` | no |
| <a name="input_mongodb_audit_enable"></a> [mongodb\_audit\_enable](#input\_mongodb\_audit\_enable) | Enable database auditing for production instances only(cost incurred 10%) | `bool` | `false` | no |
| <a name="input_mongodb_enable_slack_alerts"></a> [mongodb\_enable\_slack\_alerts](#input\_mongodb\_enable\_slack\_alerts) | Enable alert notifications to a Slack channel. When `true`, `slack_api_token` and `slack_notification_channel` must be set. | `string` | `false` | no |
| <a name="input_mongodb_network_reservation_ip_offset"></a> [mongodb\_network\_reservation\_ip\_offset](#input\_mongodb\_network\_reservation\_ip\_offset) | Value to offset the network reservation IP | `number` | `2` | no |
| <a name="input_mongodb_slack_api_token"></a> [mongodb\_slack\_api\_token](#input\_mongodb\_slack\_api\_token) | Slack API token to use for alert notifications. Required when `enable_slack_alerts` is `true`. | `string` | `null` | no |
| <a name="input_mongodb_slack_notification_channel"></a> [mongodb\_slack\_notification\_channel](#input\_mongodb\_slack\_notification\_channel) | Slack channel to send alert notifications to. Required when `enable_slack_alerts` is `true`. | `string` | `null` | no |
| <a name="input_mongodb_subnet_cidr"></a> [mongodb\_subnet\_cidr](#input\_mongodb\_subnet\_cidr) | CIDR range to use for MongoDB Atlas VPC Peering. Only used when `create_network` is `true` and an `existing_vpc_name` is not specified. | `string` | `null` | no |
| <a name="input_mongodb_termination_protection_enabled"></a> [mongodb\_termination\_protection\_enabled](#input\_mongodb\_termination\_protection\_enabled) | Enable protection to avoid accidental production cluster termination | `bool` | `false` | no |
| <a name="input_mongodb_version"></a> [mongodb\_version](#input\_mongodb\_version) | MongoDB version | `string` | `"7.0"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use as a prefix for created resources | `string` | n/a | yes |
| <a name="input_network_address_space"></a> [network\_address\_space](#input\_network\_address\_space) | The CIDR to use for the VPC and subnets created by this module | `string` | `"10.0.0.0/20"` | no |
| <a name="input_nvidia_device_plugin"></a> [nvidia\_device\_plugin](#input\_nvidia\_device\_plugin) | Install the nvidia-device-plugin helm chart to expose node GPU resources to the GKE cluster. All other nvidia\_device\_plugin variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_nvidia_device_plugin_values_overrides"></a> [nvidia\_device\_plugin\_values\_overrides](#input\_nvidia\_device\_plugin\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_postgres_availability_type"></a> [postgres\_availability\_type](#input\_postgres\_availability\_type) | The availability type of the Cloud SQL instance, high availability (REGIONAL) or single zone (ZONAL) | `string` | `"REGIONAL"` | no |
| <a name="input_postgres_cidr"></a> [postgres\_cidr](#input\_postgres\_cidr) | CIDR range to use for PostgreSQL private IP | `string` | `null` | no |
| <a name="input_postgres_database_flags"></a> [postgres\_database\_flags](#input\_postgres\_database\_flags) | The database flags for the Cloud SQL instance. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "password_encryption",<br/>    "value": "scram-sha-256"<br/>  }<br/>]</pre> | no |
| <a name="input_postgres_database_version"></a> [postgres\_database\_version](#input\_postgres\_database\_version) | The PostgreSQL version to use | `string` | `"POSTGRES_13"` | no |
| <a name="input_postgres_deletion_protection"></a> [postgres\_deletion\_protection](#input\_postgres\_deletion\_protection) | Whether Terraform will be prevented from destroying the instance. When the field is set to true or unset in Terraform state, a terraform apply or terraform destroy that would delete the instance will fail. When the field is set to false, deleting the instance is allowed | `bool` | `false` | no |
| <a name="input_postgres_disk_autoresize_limit"></a> [postgres\_disk\_autoresize\_limit](#input\_postgres\_disk\_autoresize\_limit) | The maximum size to which storage capacity can be automatically increased. The default value is 0, which specifies that there is no limit. | `number` | `0` | no |
| <a name="input_postgres_disk_size"></a> [postgres\_disk\_size](#input\_postgres\_disk\_size) | The size of data disk, in GB. Size of a running instance cannot be reduced but can be increased | `number` | `20` | no |
| <a name="input_postgres_disk_type"></a> [postgres\_disk\_type](#input\_postgres\_disk\_type) | The type of data disk: PD\_SSD, PD\_HDD, or HYPERDISK\_BALANCED | `string` | `"PD_SSD"` | no |
| <a name="input_postgres_tier"></a> [postgres\_tier](#input\_postgres\_tier) | The machine type to use. See tiers for more details and supported versions. Postgres supports only shared-core machine types, and custom machine types such as db-custom-2-13312. | `string` | `"db-custom-4-16384"` | no |
| <a name="input_redis_cidr"></a> [redis\_cidr](#input\_redis\_cidr) | CIDR range to use for Redis private IP | `string` | `null` | no |
| <a name="input_redis_memory_size_gb"></a> [redis\_memory\_size\_gb](#input\_redis\_memory\_size\_gb) | Redis memory size in GiB. Defaulted to 1 GiB | `number` | `8` | no |
| <a name="input_redis_tier"></a> [redis\_tier](#input\_redis\_tier) | The service tier of the instance: BASIC or STANDARD\_HA | `string` | `"STANDARD_HA"` | no |
| <a name="input_redis_transit_encryption_mode"></a> [redis\_transit\_encryption\_mode](#input\_redis\_transit\_encryption\_mode) | The TLS mode of the Redis instance, If not provided, TLS is enabled for the instance. Possible values are: SERVER\_AUTHENTICATION, DISABLED. | `string` | `"SERVER_AUTHENTICATION"` | no |
| <a name="input_region"></a> [region](#input\_region) | Google region to create the resources in | `string` | n/a | yes |
| <a name="input_release_channel"></a> [release\_channel](#input\_release\_channel) | The release channel of this cluster. Accepted values are `UNSPECIFIED`, `RAPID`, `REGULAR` and `STABLE`. Defaults to `STABLE`. | `string` | `"STABLE"` | no |
| <a name="input_storage_force_destroy"></a> [storage\_force\_destroy](#input\_storage\_force\_destroy) | Force destroy the Google Storage Bucket when terminating, deleting all objects it contains. Ignored if an existing\_gcs\_bucket\_name is specified or create\_storage is false. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all created resources | `map(string)` | <pre>{<br/>  "managed-by": "terraform"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_artifact_registry_repo_id"></a> [artifact\_registry\_repo\_id](#output\_artifact\_registry\_repo\_id) | ID of the Artifact Registry repository |
| <a name="output_artifact_registry_repo_path"></a> [artifact\_registry\_repo\_path](#output\_artifact\_registry\_repo\_path) | Path to the Artifact Registry repository |
| <a name="output_datarobot_service_account_email"></a> [datarobot\_service\_account\_email](#output\_datarobot\_service\_account\_email) | Email of the DataRobot service account |
| <a name="output_datarobot_service_account_key"></a> [datarobot\_service\_account\_key](#output\_datarobot\_service\_account\_key) | DataRobot service account key |
| <a name="output_dns_zone_name"></a> [dns\_zone\_name](#output\_dns\_zone\_name) | Name of the DNS zone |
| <a name="output_dns_zone_name_servers"></a> [dns\_zone\_name\_servers](#output\_dns\_zone\_name\_servers) | Name servers of the DNS zone |
| <a name="output_gke_cluster_name"></a> [gke\_cluster\_name](#output\_gke\_cluster\_name) | Name of the GKE cluster |
| <a name="output_mongodb_endpoint"></a> [mongodb\_endpoint](#output\_mongodb\_endpoint) | MongoDB endpoint |
| <a name="output_mongodb_password"></a> [mongodb\_password](#output\_mongodb\_password) | MongoDB admin password |
| <a name="output_postgres_endpoint"></a> [postgres\_endpoint](#output\_postgres\_endpoint) | PostgreSQL endpoint |
| <a name="output_postgres_password"></a> [postgres\_password](#output\_postgres\_password) | PostgreSQL admin password |
| <a name="output_redis_endpoint"></a> [redis\_endpoint](#output\_redis\_endpoint) | Google Memorystore Redis endpoint |
| <a name="output_redis_password"></a> [redis\_password](#output\_redis\_password) | Google Memorystore Redis instance primary access key |
| <a name="output_redis_port"></a> [redis\_port](#output\_redis\_port) | Google Memorystore Redis port |
| <a name="output_storage_bucket_name"></a> [storage\_bucket\_name](#output\_storage\_bucket\_name) | Name of the storage bucket |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | Name of the VPC |
<!-- END_TF_DOCS -->
