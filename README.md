# terraform-google-dr-infra
Terraform module to create Google Cloud infrastructure resources required to run DataRobot.

## Usage
```
module "datarobot_infra" {
  source = "datarobot-oss/dr-infra/google"

  name              = "datarobot"
  google_project_id = "your-google-project-id"
  region            = "us-west1"
  domain_name       = "yourdomain.com"

  create_network                     = true
  network_address_space              = "10.7.0.0/16"
  create_dns_zones                   = false
  existing_public_dns_zone_name      = "existing-public-dns-zone-name"
  create_storage                     = true
  create_container_registry          = false
  existing_artifact_registry_repo_id = "projects/your-google-project-id/locations/us-west1/repositories/existing-repository-name"
  create_kubernetes_cluster          = true
  create_app_identity                = true

  ingress_nginx                           = true
  internet_facing_ingress_lb              = true
  cert_manager                            = true
  cert_manager_letsencrypt_clusterissuers = true
  cert_manager_letsencrypt_email_address  = youremail@yourdomain.com
  external_dns                            = true
  nvidia_device_plugin                    = true

  tags = {
    application   = "datarobot"
    environment   = "dev"
    managed-by    = "terraform"
  }
}
```

## Examples
- [Complete](examples/complete) - Demonstrates all input variables
- [Partial](examples/partial) - Demonstrates the use of existing resources
- [Minimal](examples/minimal) - Demonstrates the minimum set of input variables needed to deploy all infrastructure

### Using an example directly from source
1. Clone the repo
```bash
git clone https://github.com/datarobot-oss/terraform-google-dr-infra.git
```
2. Change directories into the example that best suits your needs
```bash
cd terraform-google-dr-infra/examples/internal
```
3. Modify `main.tf` as needed
4. Run terraform commands
```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

## Module Descriptions

### Network
#### Toggle
- `create_network` to create a new Google VPC
- `existing_vpc_name`, `existing_kubernetes_nodes_subnet_name`, `existing_kubernetes_pods_range_name`, and `existing_kubernetes_services_range_name` to use an existing VPC and subnet

#### Description
Create a new Google VPC with one subnet using a `/20` slice of `network_address_space` and a NAT gateway attached.

`kubernetes_pod_cidr` and `kubernetes_service_cidr` are secondary ranges within the subnet which will be used for the Kubernetes pod and service IPs, respectively.

Only the priamry the `kubernetes_pod_cidr` IPs are attached to the Cloud NAT gateway.

#### Permissions
TBD


### DNS
#### Toggle
- `create_dns_zones` to create new Google Cloud DNS zones
- `existing_public_dns_zone_name` / `existing_private_dns_zone_name` to use existing Google Cloud DNS zones

#### Description
Create new public and/or private DNS zones with name `domain_name`.

A public Cloud DNS zone is used by `external_dns` to create records for the DataRobot ingress resources when `internet_facing_ingress_lb` is `true`. It is also used for DNS validation when using `cert_manager` and `cert_manager_letsencrypt_clusterissuers`.

A private Cloud DNS zone is used by `external_dns` to create records for the DataRobot ingress resources when `internet_facing_ingress_lb` is `false`.

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
- A `primary` node group intended to host the majority of the DataRobot pods
- A `gpu` node group intended to host GPU workload pods containing the label `datarobot.com/node-capability: gpu` and taint `nvidia.com/gpu:NoSchedule`

By default, slices of `network_address_space` will be used for the cluster nodes and control plane private endpoint IPs. It is best to use a separate address space for `kubernetes_pod_cidr` and `kubernetes_service_cidr` as these are secondary (aliased) ranges.

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


### Comprehensive Required Permissions
TBD


## DataRobot versions
| Release | Supported DR Versions |
|---------|-----------------------|
| >= 1.0 | >= 10.0 |


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.6.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.15.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_app_identity"></a> [app\_identity](#module\_app\_identity) | terraform-google-modules/service-accounts/google | ~> 4.0 |
| <a name="module_cert_manager"></a> [cert\_manager](#module\_cert\_manager) | ./modules/cert-manager | n/a |
| <a name="module_cloud_router"></a> [cloud\_router](#module\_cloud\_router) | terraform-google-modules/cloud-router/google | ~> 6.1 |
| <a name="module_external_dns"></a> [external\_dns](#module\_external\_dns) | ./modules/external-dns | n/a |
| <a name="module_ingress_nginx"></a> [ingress\_nginx](#module\_ingress\_nginx) | ./modules/ingress-nginx | n/a |
| <a name="module_kubernetes"></a> [kubernetes](#module\_kubernetes) | terraform-google-modules/kubernetes-engine/google//modules/private-cluster | ~> 33.0 |
| <a name="module_network"></a> [network](#module\_network) | terraform-google-modules/network/google | ~> 9.0 |
| <a name="module_nvidia_device_plugin"></a> [nvidia\_device\_plugin](#module\_nvidia\_device\_plugin) | ./modules/nvidia-device-plugin | n/a |
| <a name="module_private_dns"></a> [private\_dns](#module\_private\_dns) | terraform-google-modules/cloud-dns/google | ~> 5.0 |
| <a name="module_public_dns"></a> [public\_dns](#module\_public\_dns) | terraform-google-modules/cloud-dns/google | ~> 5.0 |
| <a name="module_storage"></a> [storage](#module\_storage) | terraform-google-modules/cloud-storage/google | ~> 8.0 |

## Resources

| Name | Type |
|------|------|
| [google_artifact_registry_repository.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository) | resource |
| [google_artifact_registry_repository_iam_member.datarobot](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_member) | resource |
| [google_service_account_iam_member.datarobot](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_storage_bucket_iam_member.datarobot](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_client_config.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_compute_network.existing](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network) | data source |
| [google_container_cluster.existing](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/container_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cert_manager"></a> [cert\_manager](#input\_cert\_manager) | Install the cert-manager helm chart. All other cert\_manager variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_cert_manager_letsencrypt_clusterissuers"></a> [cert\_manager\_letsencrypt\_clusterissuers](#input\_cert\_manager\_letsencrypt\_clusterissuers) | Whether to create letsencrypt-prod and letsencrypt-staging ClusterIssuers | `bool` | `true` | no |
| <a name="input_cert_manager_letsencrypt_email_address"></a> [cert\_manager\_letsencrypt\_email\_address](#input\_cert\_manager\_letsencrypt\_email\_address) | Email address for the certificate owner. Let's Encrypt will use this to contact you about expiring certificates, and issues related to your account. Only required if cert\_manager\_letsencrypt\_clusterissuers is true. | `string` | `"user@example.com"` | no |
| <a name="input_cert_manager_values"></a> [cert\_manager\_values](#input\_cert\_manager\_values) | Path to templatefile containing custom values for the cert-manager helm chart | `string` | `""` | no |
| <a name="input_cert_manager_variables"></a> [cert\_manager\_variables](#input\_cert\_manager\_variables) | Variables passed to the cert\_manager\_values templatefile | `any` | `{}` | no |
| <a name="input_create_app_identity"></a> [create\_app\_identity](#input\_create\_app\_identity) | Create a new user assigned identity for the DataRobot application | `bool` | `true` | no |
| <a name="input_create_container_registry"></a> [create\_container\_registry](#input\_create\_container\_registry) | Create a new Google Container Registry. Ignored if an existing existing\_artifact\_registry\_repo\_id is specified. | `bool` | `true` | no |
| <a name="input_create_dns_zones"></a> [create\_dns\_zones](#input\_create\_dns\_zones) | Create DNS zones for domain\_name. Ignored if existing\_public\_dns\_zone\_id and existing\_private\_dns\_zone\_id are specified. | `bool` | `true` | no |
| <a name="input_create_kubernetes_cluster"></a> [create\_kubernetes\_cluster](#input\_create\_kubernetes\_cluster) | Create a new Google Kubernetes Engine cluster. All kubernetes and helm chart variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_create_network"></a> [create\_network](#input\_create\_network) | Create a new Google VPC. Ignored if an existing existing\_vpc\_id is specified. | `bool` | `true` | no |
| <a name="input_create_storage"></a> [create\_storage](#input\_create\_storage) | Create a new Google Storage Bucket to use for DataRobot file storage. Ignored if an existing\_gcs\_bucket\_name is specified. | `bool` | `true` | no |
| <a name="input_datarobot_namespace"></a> [datarobot\_namespace](#input\_datarobot\_namespace) | Kubernetes namespace in which the DataRobot application will be installed | `string` | `"dr-app"` | no |
| <a name="input_datarobot_service_accounts"></a> [datarobot\_service\_accounts](#input\_datarobot\_service\_accounts) | Names of the Kubernetes service accounts used by the DataRobot application | `set(string)` | <pre>[<br>  "dr",<br>  "build-service",<br>  "build-service-image-builder",<br>  "buzok-account",<br>  "dr-lrs-operator",<br>  "dynamic-worker",<br>  "internal-api-sa",<br>  "nbx-notebook-revisions-account",<br>  "prediction-server-sa",<br>  "tileservergl-sa"<br>]</pre> | no |
| <a name="input_dns_zones_force_destroy"></a> [dns\_zones\_force\_destroy](#input\_dns\_zones\_force\_destroy) | Force destroy for the public and private Cloud DNS zones when terminating | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Name of the domain to use for the DataRobot application. If create\_dns\_zones is true then zones will be created for this domain. It is also used by the cert-manager helm chart for DNS validation and as a domain filter by the external-dns helm chart. | `string` | `""` | no |
| <a name="input_existing_artifact_registry_repo_id"></a> [existing\_artifact\_registry\_repo\_id](#input\_existing\_artifact\_registry\_repo\_id) | ID of existing artifact registry repository to use | `string` | `null` | no |
| <a name="input_existing_gcs_bucket_name"></a> [existing\_gcs\_bucket\_name](#input\_existing\_gcs\_bucket\_name) | ID of existing Google Storage Bucket to use for DataRobot file storage. When specified, all other storage variables will be ignored. | `string` | `null` | no |
| <a name="input_existing_gke_cluster_name"></a> [existing\_gke\_cluster\_name](#input\_existing\_gke\_cluster\_name) | Name of existing GKE cluster to use. When specified, all other kubernetes variables will be ignored. | `string` | `null` | no |
| <a name="input_existing_kubernetes_nodes_subnet_name"></a> [existing\_kubernetes\_nodes\_subnet\_name](#input\_existing\_kubernetes\_nodes\_subnet\_name) | Name of an existing subnet to use for the GKE node pools and control plane private endpoint. Required when an existing\_vpc\_name is specified. Ignored if no existing\_vpc\_name is specified. | `string` | `null` | no |
| <a name="input_existing_kubernetes_pods_range_name"></a> [existing\_kubernetes\_pods\_range\_name](#input\_existing\_kubernetes\_pods\_range\_name) | Name of an secondary IP range within subnet defined by existing\_kubernetes\_nodes\_subnet\_name to use for the Kubernetes pods. Required when an existing\_vpc\_name is specified. Ignored if no existing\_vpc\_name is specified. | `string` | `null` | no |
| <a name="input_existing_kubernetes_services_range_name"></a> [existing\_kubernetes\_services\_range\_name](#input\_existing\_kubernetes\_services\_range\_name) | Name of an secondary IP range within subnet defined by existing\_kubernetes\_nodes\_subnet\_name to use for the Kubernetes services. Required when an existing\_vpc\_name is specified. Ignored if no existing\_vpc\_name is specified. | `string` | `null` | no |
| <a name="input_existing_private_dns_zone_name"></a> [existing\_private\_dns\_zone\_name](#input\_existing\_private\_dns\_zone\_name) | ID of existing private hosted zone to use for private DNS records created by external-dns. This is required when create\_dns\_zones is false and ingress\_nginx is true with internet\_facing\_ingress\_lb false. | `string` | `null` | no |
| <a name="input_existing_public_dns_zone_name"></a> [existing\_public\_dns\_zone\_name](#input\_existing\_public\_dns\_zone\_name) | ID of existing public hosted zone to use for public DNS records created by external-dns and public LetsEncrypt certificate validation by cert-manager. This is required when create\_dns\_zones is false and ingress\_nginx and internet\_facing\_ingress\_lb are true or when cert\_manager and cert\_manager\_letsencrypt\_clusterissuers are true. | `string` | `null` | no |
| <a name="input_existing_vpc_name"></a> [existing\_vpc\_name](#input\_existing\_vpc\_name) | Name of an existing Google VPC to use. When specified, other network variables are ignored. | `string` | `null` | no |
| <a name="input_external_dns"></a> [external\_dns](#input\_external\_dns) | Install the external\_dns helm chart to create DNS records for ingress resources matching the domain\_name variable. All other external\_dns variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_external_dns_values"></a> [external\_dns\_values](#input\_external\_dns\_values) | Path to templatefile containing custom values for the external-dns helm chart | `string` | `""` | no |
| <a name="input_external_dns_variables"></a> [external\_dns\_variables](#input\_external\_dns\_variables) | Variables passed to the external\_dns\_values templatefile | `any` | `{}` | no |
| <a name="input_google_project_id"></a> [google\_project\_id](#input\_google\_project\_id) | The ID of the Google Project where these resources will be created | `string` | n/a | yes |
| <a name="input_ingress_nginx"></a> [ingress\_nginx](#input\_ingress\_nginx) | Install the ingress-nginx helm chart to use as the ingress controller for the GKE cluster. All other ingress\_nginx variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_ingress_nginx_values"></a> [ingress\_nginx\_values](#input\_ingress\_nginx\_values) | Path to templatefile containing custom values for the ingress-nginx helm chart | `string` | `""` | no |
| <a name="input_ingress_nginx_variables"></a> [ingress\_nginx\_variables](#input\_ingress\_nginx\_variables) | Variables passed to the ingress\_nginx\_values templatefile | `any` | `{}` | no |
| <a name="input_internet_facing_ingress_lb"></a> [internet\_facing\_ingress\_lb](#input\_internet\_facing\_ingress\_lb) | Determines the type of Load Balancer created for GKE ingress. If true, an external Load Balancer will be created. If false, an internal Load Balancer will be created. | `bool` | `true` | no |
| <a name="input_kubernetes_cluster_deletion_protection"></a> [kubernetes\_cluster\_deletion\_protection](#input\_kubernetes\_cluster\_deletion\_protection) | Enable deletion protection on the GKE cluster | `bool` | `true` | no |
| <a name="input_kubernetes_cluster_endpoint_access_list"></a> [kubernetes\_cluster\_endpoint\_access\_list](#input\_kubernetes\_cluster\_endpoint\_access\_list) | List of CIDRs allowed to access the Kubernetes cluster API endpoint. When kubernetes\_cluster\_endpoint\_public\_access is true, these CIDRs specify which public IP addresses are allowed to access the Kubernetes cluster API external endpoint. When kubernetes\_cluster\_endpoint\_public\_access is false, these CIDRs specify which private IP addresses are allowed to access the Kubernetes cluster API internal endpoint. By default, only hosts within the kubernetes nodes subnet are allowed to access the Kubernetes cluster API internal endpoint. | `list(string)` | `[]` | no |
| <a name="input_kubernetes_cluster_endpoint_public_access"></a> [kubernetes\_cluster\_endpoint\_public\_access](#input\_kubernetes\_cluster\_endpoint\_public\_access) | Whether the Kubernetes cluster API endpoint can be accessed via an external IP address | `bool` | `true` | no |
| <a name="input_kubernetes_cluster_grant_registry_access"></a> [kubernetes\_cluster\_grant\_registry\_access](#input\_kubernetes\_cluster\_grant\_registry\_access) | Grants created cluster-specific service account storage.objectViewer and artifactregistry.reader roles | `bool` | `true` | no |
| <a name="input_kubernetes_cluster_version"></a> [kubernetes\_cluster\_version](#input\_kubernetes\_cluster\_version) | GKE cluster version | `string` | `"latest"` | no |
| <a name="input_kubernetes_gpu_nodegroup_taints"></a> [kubernetes\_gpu\_nodegroup\_taints](#input\_kubernetes\_gpu\_nodegroup\_taints) | The Kubernetes taints to be applied to the nodes in the GPU node group. | `any` | <pre>[<br>  {<br>    "effect": "NO_SCHEDULE",<br>    "key": "nvidia.com/gpu",<br>    "value": "true"<br>  }<br>]</pre> | no |
| <a name="input_kubernetes_gpu_nodepool_labels"></a> [kubernetes\_gpu\_nodepool\_labels](#input\_kubernetes\_gpu\_nodepool\_labels) | A map of Kubernetes labels to apply to the GPU node pool | `map(string)` | <pre>{<br>  "datarobot.com/node-capability": "gpu"<br>}</pre> | no |
| <a name="input_kubernetes_gpu_nodepool_max_count"></a> [kubernetes\_gpu\_nodepool\_max\_count](#input\_kubernetes\_gpu\_nodepool\_max\_count) | Maximum number of nodes in the GPU node pool | `number` | `10` | no |
| <a name="input_kubernetes_gpu_nodepool_min_count"></a> [kubernetes\_gpu\_nodepool\_min\_count](#input\_kubernetes\_gpu\_nodepool\_min\_count) | Minimum number of nodes in the GPU node pool | `number` | `0` | no |
| <a name="input_kubernetes_gpu_nodepool_name"></a> [kubernetes\_gpu\_nodepool\_name](#input\_kubernetes\_gpu\_nodepool\_name) | Name of the GPU node pool | `string` | `"gpu"` | no |
| <a name="input_kubernetes_gpu_nodepool_node_count"></a> [kubernetes\_gpu\_nodepool\_node\_count](#input\_kubernetes\_gpu\_nodepool\_node\_count) | Node count of the GPU node pool | `number` | `0` | no |
| <a name="input_kubernetes_gpu_nodepool_vm_size"></a> [kubernetes\_gpu\_nodepool\_vm\_size](#input\_kubernetes\_gpu\_nodepool\_vm\_size) | VM size used for the GPU node pool | `string` | `"n1-highmem-4"` | no |
| <a name="input_kubernetes_master_ipv4_cidr_block"></a> [kubernetes\_master\_ipv4\_cidr\_block](#input\_kubernetes\_master\_ipv4\_cidr\_block) | The IP range in CIDR notation to use for the hosted master network including the Kubernetes control plane. If you use this flag, GKE creates a new subnet that uses the values you defined in master-ipv4-cidr and uses the new subnet to provision the internal IP address for the control plane. | `string` | `null` | no |
| <a name="input_kubernetes_pod_cidr"></a> [kubernetes\_pod\_cidr](#input\_kubernetes\_pod\_cidr) | The CIDR to use for Kubernetes pod IP addresses. This is used as a secondary IP range within the Kubernetes nodes subnet. | `string` | `"192.168.0.0/18"` | no |
| <a name="input_kubernetes_primary_nodepool_labels"></a> [kubernetes\_primary\_nodepool\_labels](#input\_kubernetes\_primary\_nodepool\_labels) | A map of Kubernetes labels to apply to the primary node pool | `map(string)` | <pre>{<br>  "datarobot.com/node-capability": "cpu"<br>}</pre> | no |
| <a name="input_kubernetes_primary_nodepool_max_count"></a> [kubernetes\_primary\_nodepool\_max\_count](#input\_kubernetes\_primary\_nodepool\_max\_count) | Maximum number of nodes in the primary node pool | `number` | `10` | no |
| <a name="input_kubernetes_primary_nodepool_min_count"></a> [kubernetes\_primary\_nodepool\_min\_count](#input\_kubernetes\_primary\_nodepool\_min\_count) | Minimum number of nodes in the primary node pool | `number` | `1` | no |
| <a name="input_kubernetes_primary_nodepool_name"></a> [kubernetes\_primary\_nodepool\_name](#input\_kubernetes\_primary\_nodepool\_name) | Name of the primary node pool | `string` | `"primary"` | no |
| <a name="input_kubernetes_primary_nodepool_node_count"></a> [kubernetes\_primary\_nodepool\_node\_count](#input\_kubernetes\_primary\_nodepool\_node\_count) | Node count of the primary node pool | `number` | `1` | no |
| <a name="input_kubernetes_primary_nodepool_taints"></a> [kubernetes\_primary\_nodepool\_taints](#input\_kubernetes\_primary\_nodepool\_taints) | A list of Kubernetes taints to apply to the primary node pool | `any` | `[]` | no |
| <a name="input_kubernetes_primary_nodepool_vm_size"></a> [kubernetes\_primary\_nodepool\_vm\_size](#input\_kubernetes\_primary\_nodepool\_vm\_size) | VM size used for the primary node pool | `string` | `"e2-standard-32"` | no |
| <a name="input_kubernetes_service_cidr"></a> [kubernetes\_service\_cidr](#input\_kubernetes\_service\_cidr) | The CIDR to use for Kubernetes service IP addresses. This is used as a secondary IP range within the Kubernetes nodes subnet. | `string` | `"192.168.64.0/18"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use as a prefix for created resources | `string` | n/a | yes |
| <a name="input_network_address_space"></a> [network\_address\_space](#input\_network\_address\_space) | The CIDR to use for the Kubernetes nodes and control plane. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_nvidia_device_plugin"></a> [nvidia\_device\_plugin](#input\_nvidia\_device\_plugin) | Install the nvidia-device-plugin helm chart to expose node GPU resources to the GKE cluster. All other nvidia\_device\_plugin variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_nvidia_device_plugin_values"></a> [nvidia\_device\_plugin\_values](#input\_nvidia\_device\_plugin\_values) | Path to templatefile containing custom values for the nvidia-device-plugin helm chart | `string` | `""` | no |
| <a name="input_nvidia_device_plugin_variables"></a> [nvidia\_device\_plugin\_variables](#input\_nvidia\_device\_plugin\_variables) | Variables passed to the nvidia\_device\_plugin\_values templatefile | `any` | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | Google region to create the resources in | `string` | n/a | yes |
| <a name="input_release_channel"></a> [release\_channel](#input\_release\_channel) | The release channel of this cluster. Accepted values are `UNSPECIFIED`, `RAPID`, `REGULAR` and `STABLE`. Defaults to `STABLE`. | `string` | `"STABLE"` | no |
| <a name="input_storage_force_destroy"></a> [storage\_force\_destroy](#input\_storage\_force\_destroy) | Force destroy for the public and private Cloud DNS zones when terminating | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all created resources | `map(string)` | <pre>{<br>  "managed-by": "terraform"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_artifact_registry_repo_id"></a> [artifact\_registry\_repo\_id](#output\_artifact\_registry\_repo\_id) | ID of the Artifact Registry repository |
| <a name="output_artifact_registry_repo_path"></a> [artifact\_registry\_repo\_path](#output\_artifact\_registry\_repo\_path) | Path to the Artifact Registry repository |
| <a name="output_datarobot_service_account_email"></a> [datarobot\_service\_account\_email](#output\_datarobot\_service\_account\_email) | Email of the DataRobot service account |
| <a name="output_datarobot_service_account_key"></a> [datarobot\_service\_account\_key](#output\_datarobot\_service\_account\_key) | DataRobot service account key |
| <a name="output_gke_cluster_name"></a> [gke\_cluster\_name](#output\_gke\_cluster\_name) | Name of the GKE cluster |
| <a name="output_private_dns_zone_name"></a> [private\_dns\_zone\_name](#output\_private\_dns\_zone\_name) | Name of the private DNS zone |
| <a name="output_public_dns_zone_name"></a> [public\_dns\_zone\_name](#output\_public\_dns\_zone\_name) | Name of the public DNS zone |
| <a name="output_storage_bucket_name"></a> [storage\_bucket\_name](#output\_storage\_bucket\_name) | Name of the storage bucket |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | Name of the VPC |
<!-- END_TF_DOCS -->
