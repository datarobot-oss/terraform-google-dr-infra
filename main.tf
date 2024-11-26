data "google_client_config" "default" {}


################################################################################
# Network
################################################################################

data "google_compute_network" "existing" {
  count = var.existing_vpc_name != null ? 1 : 0

  project = var.google_project_id
  name    = var.existing_vpc_name
}

locals {
  vpc_name      = try(data.google_compute_network.existing[0].name, module.network[0].network_name, null)
  vpc_self_link = try(data.google_compute_network.existing[0].self_link, module.network[0].network_self_link, null)

  default_kubernetes_nodes_subnet_name = "${var.name}-vpc-snet"
  kubernetes_nodes_subnet_name         = var.create_network && var.existing_vpc_name == null ? module.network[0].subnets["${var.region}/${local.default_kubernetes_nodes_subnet_name}"].name : var.existing_kubernetes_nodes_subnet_name

  default_kubernetes_pods_range_name = "kubernetes-pods"
  kubernetes_pods_range_name         = var.create_network && var.existing_vpc_name == null ? local.default_kubernetes_pods_range_name : var.existing_kubernetes_pods_range_name

  default_kubernetes_services_range_name = "kubernetes-services"
  kubernetes_services_range_name         = var.create_network && var.existing_vpc_name == null ? local.default_kubernetes_services_range_name : var.existing_kubernetes_services_range_name
}

module "network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.0"
  count   = var.create_network && var.existing_vpc_name == null ? 1 : 0

  project_id = var.google_project_id

  network_name = "${var.name}-vpc"
  subnets = [
    {
      subnet_name           = local.default_kubernetes_nodes_subnet_name
      subnet_ip             = cidrsubnet(var.network_address_space, 4, 0) #/20
      subnet_region         = var.region
      subnet_private_access = true
    }
  ]
  secondary_ranges = {
    (local.default_kubernetes_nodes_subnet_name) = [
      {
        range_name    = local.default_kubernetes_pods_range_name
        ip_cidr_range = var.kubernetes_pod_cidr
      },
      {
        range_name    = local.default_kubernetes_services_range_name
        ip_cidr_range = var.kubernetes_service_cidr
      }
    ]
  }
}

module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 6.1"
  count   = var.create_network && var.existing_vpc_name == null ? 1 : 0

  project = var.google_project_id

  name    = "${var.name}-cloud-router"
  network = module.network[0].network_name
  region  = var.region

  nats = [{
    name                               = "${var.name}-ng"
    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
    subnetworks = [
      {
        name                     = module.network[0].subnets["${var.region}/${local.default_kubernetes_nodes_subnet_name}"].id
        source_ip_ranges_to_nat  = ["PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"]
        secondary_ip_range_names = [module.network[0].subnets["${var.region}/${local.default_kubernetes_nodes_subnet_name}"].secondary_ip_range[0].range_name]
      }
    ]
  }]
}


################################################################################
# DNS
################################################################################

locals {
  # create a public zone if we're using external_dns with internet_facing LB
  # or we're using cert_manager with letsencrypt clusterissuers
  create_public_dns_zone = var.create_dns_zones && var.existing_public_dns_zone_name == null && ((var.external_dns && var.internet_facing_ingress_lb) || (var.cert_manager && var.cert_manager_letsencrypt_clusterissuers))
  public_dns_zone_name   = local.create_public_dns_zone ? module.public_dns[0].name : var.existing_public_dns_zone_name

  # create a private zone if we're using external_dns with an internal LB
  create_private_dns_zone = var.create_dns_zones && var.existing_private_dns_zone_name == null && (var.external_dns && !var.internet_facing_ingress_lb)
  private_dns_zone_name   = local.create_private_dns_zone ? module.private_dns[0].name : var.existing_private_dns_zone_name
}

module "public_dns" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "~> 5.0"
  count   = local.create_public_dns_zone ? 1 : 0

  project_id    = var.google_project_id
  type          = "public"
  name          = "${var.name}-dns-public"
  domain        = "${var.domain_name}."
  force_destroy = var.dns_zones_force_destroy

  labels = var.tags
}

module "private_dns" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "~> 5.0"
  count   = local.create_private_dns_zone ? 1 : 0

  project_id                         = var.google_project_id
  type                               = "private"
  name                               = "${var.name}-dns-private"
  domain                             = "${var.domain_name}."
  private_visibility_config_networks = [local.vpc_self_link]
  force_destroy                      = var.dns_zones_force_destroy

  labels = var.tags
}


################################################################################
# Storage
################################################################################

locals {
  storage_bucket_name = var.create_storage && var.existing_gcs_bucket_name == null ? module.storage[0].name : var.existing_gcs_bucket_name
}

module "storage" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 8.0"
  count   = var.create_storage && var.existing_gcs_bucket_name == null ? 1 : 0

  project_id = var.google_project_id
  location   = var.region

  names  = ["datarobot"]
  prefix = var.name
  force_destroy = {
    datarobot = var.storage_force_destroy
  }

  labels = var.tags
}


################################################################################
# Container Registry
################################################################################

locals {
  artifact_registry_repo = var.create_container_registry && var.existing_artifact_registry_repo_id == null ? google_artifact_registry_repository.this[0].id : var.existing_artifact_registry_repo_id
}

resource "google_artifact_registry_repository" "this" {
  count = var.create_container_registry && var.existing_artifact_registry_repo_id == null ? 1 : 0

  project  = var.google_project_id
  location = var.region

  repository_id = var.name
  description   = "${var.name} container registry"
  format        = "DOCKER"

  labels = var.tags
}


################################################################################
# Kubernetes
################################################################################

data "google_container_cluster" "existing" {
  count = var.existing_gke_cluster_name != null ? 1 : 0

  project  = var.google_project_id
  location = var.region
  name     = var.existing_gke_cluster_name
}

locals {
  gke_cluster_name           = try(data.google_container_cluster.existing[0].name, module.kubernetes[0].name, null)
  gke_cluster_ca_certificate = try(data.google_container_cluster.existing[0].master_auth[0].cluster_ca_certificate, module.kubernetes[0].ca_certificate, null)
  gke_cluster_endpoint       = try(data.google_container_cluster.existing[0].endpoint, module.kubernetes[0].endpoint, null)
}

module "kubernetes" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 33.0"
  count   = var.existing_gke_cluster_name == null && var.create_kubernetes_cluster ? 1 : 0

  project_id = var.google_project_id
  region     = var.region

  name                          = "${var.name}-gke"
  deletion_protection           = var.kubernetes_cluster_deletion_protection
  grant_registry_access         = var.kubernetes_cluster_grant_registry_access
  kubernetes_version            = var.kubernetes_cluster_version
  release_channel               = var.release_channel
  datapath_provider             = "ADVANCED_DATAPATH"
  http_load_balancing           = false
  network                       = local.vpc_name
  subnetwork                    = local.kubernetes_nodes_subnet_name
  ip_range_pods                 = local.kubernetes_pods_range_name
  ip_range_services             = local.kubernetes_services_range_name
  enable_private_endpoint       = !var.kubernetes_cluster_endpoint_public_access
  deploy_using_private_endpoint = !var.kubernetes_cluster_endpoint_public_access
  master_ipv4_cidr_block        = coalesce(var.kubernetes_master_ipv4_cidr_block, cidrsubnet(var.network_address_space, 12, 256))
  master_authorized_networks = [for ip in var.kubernetes_cluster_endpoint_access_list : {
    cidr_block   = ip
    display_name = ip
  }]

  node_pools = [
    {
      name         = var.kubernetes_primary_nodepool_name
      machine_type = var.kubernetes_primary_nodepool_vm_size
      disk_size_gb = 200
      node_count   = var.kubernetes_primary_nodepool_node_count
      min_count    = var.kubernetes_primary_nodepool_min_count
      max_count    = var.kubernetes_primary_nodepool_max_count
    },
    {
      name         = var.kubernetes_gpu_nodepool_name
      machine_type = var.kubernetes_gpu_nodepool_vm_size
      disk_size_gb = 200
      node_count   = var.kubernetes_gpu_nodepool_node_count
      min_count    = var.kubernetes_gpu_nodepool_min_count
      max_count    = var.kubernetes_gpu_nodepool_max_count
    }
  ]

  node_pools_labels = {
    (var.kubernetes_primary_nodepool_name) = var.kubernetes_primary_nodepool_labels
    (var.kubernetes_gpu_nodepool_name)     = var.kubernetes_gpu_nodepool_labels
  }

  node_pools_taints = {
    (var.kubernetes_primary_nodepool_name) = var.kubernetes_primary_nodepool_taints
    (var.kubernetes_gpu_nodepool_name)     = var.kubernetes_gpu_nodegroup_taints
  }

  cluster_resource_labels = var.tags
}


################################################################################
# App Identity
################################################################################

module "app_identity" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "~> 4.0"
  count   = var.create_app_identity ? 1 : 0

  project_id = var.google_project_id

  names         = [var.name]
  generate_keys = true
}

resource "google_storage_bucket_iam_member" "datarobot" {
  count = var.create_app_identity ? 1 : 0

  bucket = local.storage_bucket_name
  role   = "roles/storage.admin"
  member = module.app_identity[0].iam_email
}

resource "google_artifact_registry_repository_iam_member" "datarobot" {
  count = var.create_app_identity ? 1 : 0

  repository = local.artifact_registry_repo
  role       = "roles/artifactregistry.writer"
  member     = module.app_identity[0].iam_email
}

resource "google_service_account_iam_member" "datarobot" {
  for_each = var.create_app_identity ? var.datarobot_service_accounts : []

  service_account_id = module.app_identity[0].service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.google_project_id}.svc.id.goog[${var.datarobot_namespace}/${each.value}]"
}


################################################################################
# Helm Charts
################################################################################

provider "helm" {
  kubernetes {
    host                   = try("https://${local.gke_cluster_endpoint}", "")
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(try(local.gke_cluster_ca_certificate, ""))
  }
}



module "ingress_nginx" {
  source = "./modules/ingress-nginx"
  count  = var.ingress_nginx ? 1 : 0

  internet_facing_ingress_lb = var.internet_facing_ingress_lb

  custom_values_templatefile = var.ingress_nginx_values
  custom_values_variables    = var.ingress_nginx_variables

  depends_on = [local.gke_cluster_name]
}


module "cert_manager" {
  source = "./modules/cert-manager"
  count  = var.cert_manager ? 1 : 0

  google_project_id = var.google_project_id

  name                       = var.name
  dns_zone_name              = local.public_dns_zone_name
  letsencrypt_clusterissuers = var.cert_manager_letsencrypt_clusterissuers
  email_address              = var.cert_manager_letsencrypt_email_address

  custom_values_templatefile = var.cert_manager_values
  custom_values_variables    = var.cert_manager_variables

  depends_on = [local.gke_cluster_name]
}


module "external_dns" {
  source = "./modules/external-dns"
  count  = var.external_dns ? 1 : 0

  google_project_id = var.google_project_id

  name             = var.name
  domain_name      = var.domain_name
  dns_zone_name    = var.internet_facing_ingress_lb ? local.public_dns_zone_name : local.private_dns_zone_name
  gke_cluster_name = local.gke_cluster_name
  zone_visibility  = var.internet_facing_ingress_lb ? "public" : "private"

  custom_values_templatefile = var.external_dns_values
  custom_values_variables    = var.external_dns_variables
}


module "nvidia_device_plugin" {
  source = "./modules/nvidia-device-plugin"
  count  = var.nvidia_device_plugin ? 1 : 0

  custom_values_templatefile = var.nvidia_device_plugin_values
  custom_values_variables    = var.nvidia_device_plugin_variables

  depends_on = [local.gke_cluster_name]
}
