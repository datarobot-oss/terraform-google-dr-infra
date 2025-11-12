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

  # The default IP allotment is as follows:
  # 10.0.0.0/20  VPC
  # 10.0.0.0/23  Kubernetes nodes subnet supports up to 508 nodes
  # 10.0.6.0/24  Postgres subnet
  # 10.0.7.0/24  Redis subnet
  # 10.0.8.0/24  MongoDB subnet
  # 10.0.9.0/24  Ingress PSC subnet
  # 10.0.15.0/28 Kubernetes master IPv4 CIDR block must be /28
  kubernetes_nodes_subnet_name = "${var.name}-kubernetes-nodes"
  kubernetes_pods_range_name   = coalesce(var.existing_kubernetes_pods_range_name, "kubernetes-pods")
  kubernetes_nodes_subnet_cidr = coalesce(var.kubernetes_nodes_cidr, cidrsubnet(var.network_address_space, 3, 0))
  postgres_cidr                = coalesce(var.postgres_cidr, cidrsubnet(var.network_address_space, 4, 6))
  redis_cidr                   = coalesce(var.redis_cidr, cidrsubnet(var.network_address_space, 4, 7))
  mongodb_subnet_name          = "${var.name}-mongodb"
  mongodb_subnet_cidr          = coalesce(var.mongodb_subnet_cidr, cidrsubnet(var.network_address_space, 4, 8))
  ingress_psc_subnet_name      = "${var.name}-ingress-psc"
  ingress_psc_subnet_cidr      = coalesce(var.ingress_psc_subnet_cidr, cidrsubnet(var.network_address_space, 4, 9))
  kubernetes_master_ipv4_cidr  = coalesce(var.kubernetes_master_ipv4_cidr, cidrsubnet(var.network_address_space, 8, 240))
}

module "network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.0"
  count   = var.create_network && var.existing_vpc_name == null ? 1 : 0

  project_id = var.google_project_id

  network_name = "${var.name}-vpc"
  subnets = [
    {
      subnet_name           = local.kubernetes_nodes_subnet_name
      subnet_ip             = local.kubernetes_nodes_subnet_cidr
      subnet_region         = var.region
      subnet_private_access = true
    },
    {
      subnet_name           = local.mongodb_subnet_name
      subnet_ip             = local.mongodb_subnet_cidr
      subnet_region         = var.region
      subnet_private_access = true
    },
    {
      subnet_name           = local.ingress_psc_subnet_name
      subnet_ip             = local.ingress_psc_subnet_cidr
      subnet_region         = var.region
      subnet_private_access = true
      purpose               = "PRIVATE_SERVICE_CONNECT"
    }
  ]
  secondary_ranges = {
    (local.kubernetes_nodes_subnet_name) = [
      {
        range_name    = local.kubernetes_pods_range_name
        ip_cidr_range = var.kubernetes_pod_cidr
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
        name                     = module.network[0].subnets["${var.region}/${local.kubernetes_nodes_subnet_name}"].id
        source_ip_ranges_to_nat  = ["PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"]
        secondary_ip_range_names = [module.network[0].subnets["${var.region}/${local.kubernetes_nodes_subnet_name}"].secondary_ip_range[0].range_name]
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
  storage_bucket_name = var.existing_gcs_bucket_name != null ? var.existing_gcs_bucket_name : try(module.storage[0].name, null)
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
  artifact_registry_repo = var.existing_artifact_registry_repo_id != null ? var.existing_artifact_registry_repo_id : try(google_artifact_registry_repository.this[0].id, null)
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

data "google_compute_subnetwork" "existing_kubernetes_nodes" {
  count = var.existing_kubernetes_nodes_subnet != null ? 1 : 0

  project = var.google_project_id
  name    = var.existing_kubernetes_nodes_subnet
  region  = var.region
}

locals {
  gke_cluster_name           = try(data.google_container_cluster.existing[0].name, module.kubernetes[0].name, null)
  gke_cluster_ca_certificate = try(data.google_container_cluster.existing[0].master_auth[0].cluster_ca_certificate, module.kubernetes[0].ca_certificate, "")
  gke_cluster_endpoint       = try(data.google_container_cluster.existing[0].endpoint, module.kubernetes[0].endpoint, "")

  kubernetes_nodes_subnet = try(data.google_compute_subnetwork.existing_kubernetes_nodes[0], module.network[0].subnets["${var.region}/${local.kubernetes_nodes_subnet_name}"], null)

  # strip taints and labels from kubernetes_node_pools map
  kubernetes_node_pools = [for np in var.kubernetes_node_pools : { for k, v in np : k => v if k != "node_taints" && k != "node_labels" }]
}

module "kubernetes" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 39.0"
  count   = var.existing_gke_cluster_name == null && var.create_kubernetes_cluster ? 1 : 0

  project_id = var.google_project_id
  region     = var.region

  name                          = "${var.name}-gke"
  deletion_protection           = var.kubernetes_cluster_deletion_protection
  grant_registry_access         = var.kubernetes_cluster_grant_registry_access
  kubernetes_version            = var.kubernetes_cluster_version
  release_channel               = var.release_channel
  datapath_provider             = "ADVANCED_DATAPATH"
  network                       = local.vpc_name
  subnetwork                    = local.kubernetes_nodes_subnet.name
  ip_range_pods                 = local.kubernetes_pods_range_name
  enable_private_endpoint       = !var.kubernetes_cluster_endpoint_public_access
  deploy_using_private_endpoint = !var.kubernetes_cluster_endpoint_public_access
  master_ipv4_cidr_block        = local.kubernetes_master_ipv4_cidr
  master_authorized_networks = [for ip in var.kubernetes_cluster_endpoint_access_list : {
    cidr_block   = ip
    display_name = ip
  }]

  remove_default_node_pool = true

  # all values are ignored except for autoscaling_profile
  cluster_autoscaling = {
    enabled             = false ## disable node auto-provisioning
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
    max_cpu_cores       = 0
    min_cpu_cores       = 0
    max_memory_gb       = 0
    min_memory_gb       = 0
    gpu_resources       = []
    auto_repair         = true
    auto_upgrade        = true
  }

  node_pools        = local.kubernetes_node_pools
  node_pools_labels = { for k, v in var.kubernetes_node_pools : k => v.node_labels }
  node_pools_taints = { for k, v in var.kubernetes_node_pools : k => v.node_taints }

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
  count = var.create_app_identity && var.existing_gcs_bucket_name == null ? 1 : 0

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
# PostgreSQL
################################################################################

resource "google_compute_global_address" "postgres" {
  count = var.create_postgres ? 1 : 0

  project       = var.google_project_id
  name          = "${var.name}-postgres-address"
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  address       = split("/", local.postgres_cidr)[0]
  prefix_length = split("/", local.postgres_cidr)[1]
  network       = local.vpc_name
}

module "postgres" {
  source  = "terraform-google-modules/sql-db/google//modules/postgresql"
  version = "~> 26.0"
  count   = var.create_postgres ? 1 : 0

  name              = "${var.name}-postgres"
  project_id        = var.google_project_id
  availability_type = var.postgres_availability_type
  ip_configuration = {
    private_network    = local.vpc_self_link
    allocated_ip_range = google_compute_global_address.postgres[0].name
    ssl_mode           = "ENCRYPTED_ONLY"
  }

  database_version      = var.postgres_database_version
  tier                  = var.postgres_tier
  disk_type             = var.postgres_disk_type
  disk_size             = var.postgres_disk_size
  disk_autoresize_limit = var.postgres_disk_autoresize_limit

  enable_default_user = true
  user_name           = "postgres"

  maintenance_window_update_track = "stable"
  deletion_protection             = var.postgres_deletion_protection
  backup_configuration = {
    enabled                        = true
    point_in_time_recovery_enabled = true
    retained_backups               = 365
    retention_unit                 = "COUNT"
  }

  database_flags = var.postgres_database_flags

  user_labels = var.tags

  depends_on = [google_service_networking_connection.this[0]]
}


################################################################################
# Redis
################################################################################

resource "google_compute_global_address" "redis" {
  count = var.create_redis ? 1 : 0

  project       = var.google_project_id
  name          = "${var.name}-redis-address"
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  address       = split("/", local.redis_cidr)[0]
  prefix_length = split("/", local.redis_cidr)[1]
  network       = local.vpc_name
}

module "redis" {
  source  = "terraform-google-modules/memorystore/google"
  version = "~> 15.0"
  count   = var.create_redis ? 1 : 0

  name                    = "${var.name}-redis"
  project_id              = var.google_project_id
  region                  = var.region
  authorized_network      = local.vpc_name
  tier                    = var.redis_tier
  connect_mode            = "PRIVATE_SERVICE_ACCESS"
  reserved_ip_range       = google_compute_global_address.redis[0].name
  auth_enabled            = true
  transit_encryption_mode = var.redis_transit_encryption_mode
  memory_size_gb          = var.redis_memory_size_gb

  labels = var.tags

  depends_on = [google_service_networking_connection.this[0]]
}


################################################################################
# Service Networking
################################################################################

resource "google_service_networking_connection" "this" {
  count = var.create_postgres || var.create_redis ? 1 : 0

  network = local.vpc_self_link
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = flatten([
    try(google_compute_global_address.postgres[0].name, ""),
    try(google_compute_global_address.redis[0].name, "")
  ])
  deletion_policy         = "ABANDON"
  update_on_creation_fail = true
}


################################################################################
# MongoDB
################################################################################

provider "mongodbatlas" {
  public_key  = var.mongodb_atlas_public_key
  private_key = var.mongodb_atlas_private_key
}

data "google_compute_subnetwork" "existing_mongodb" {
  count = var.existing_mongodb_subnet_name != null ? 1 : 0

  project = var.google_project_id
  name    = var.existing_mongodb_subnet_name
  region  = var.region
}

locals {
  mongodb_subnet = try(data.google_compute_subnetwork.existing_mongodb[0], module.network[0].subnets["${var.region}/${local.mongodb_subnet_name}"], null)
}

module "mongodb" {
  source = "./modules/mongodb"
  count  = var.create_mongodb ? 1 : 0

  name                   = var.name
  google_project_id      = var.google_project_id
  region                 = var.region
  vpc_name               = local.vpc_name
  subnet                 = local.mongodb_subnet.name
  subnet_cidr            = local.mongodb_subnet.ip_cidr_range
  project_ip_access_list = local.kubernetes_nodes_subnet.ip_cidr_range

  mongodb_version                    = var.mongodb_version
  atlas_org_id                       = var.mongodb_atlas_org_id
  termination_protection_enabled     = var.mongodb_termination_protection_enabled
  db_audit_enable                    = var.mongodb_audit_enable
  atlas_auto_scaling_disk_gb_enabled = var.mongodb_atlas_auto_scaling_disk_gb_enabled
  atlas_disk_size                    = var.mongodb_atlas_disk_size
  atlas_instance_type                = var.mongodb_atlas_instance_type
  mongodb_admin_username             = var.mongodb_admin_username
  enable_slack_alerts                = var.mongodb_enable_slack_alerts
  slack_api_token                    = var.mongodb_slack_api_token
  slack_notification_channel         = var.mongodb_slack_notification_channel
  network_reservation_ip_offset      = var.mongodb_network_reservation_ip_offset
  tags                               = var.tags
}

################################################################################
# Private Link Service
################################################################################

data "google_compute_subnetwork" "existing_ingress_psc" {
  count = var.existing_ingress_pcs_subnet_name != null ? 1 : 0

  project = var.google_project_id
  name    = var.existing_ingress_pcs_subnet_name
  region  = var.region
}

locals {
  ingress_psc_subnet = try(data.google_compute_subnetwork.existing_ingress_psc[0], module.network[0].subnets["${var.region}/${local.ingress_psc_subnet_name}"], null)
}

module "private_link_service" {
  source = "./modules/private-link-service"
  count  = var.create_ingress_psc ? 1 : 0

  namespace        = var.ingress_nginx_namespace
  create_namespace = var.create_ingress_psc_namespace

  ingress_psc_connection_preference        = length(var.ingress_psc_consumer_projects) > 0 ? "ACCEPT_MANUAL" : "ACCEPT_AUTOMATIC"
  ingress_psc_consumer_allow_list_projects = var.ingress_psc_consumer_projects
  psc_nat_subnets                          = [local.ingress_psc_subnet.name]

  depends_on = [local.gke_cluster_name, module.ingress_nginx]
}

################################################################################
# Helm Charts
################################################################################

provider "helm" {
  kubernetes = {
    host                   = "https://${local.gke_cluster_endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(local.gke_cluster_ca_certificate)
  }
}

provider "kubectl" {
  host                   = "https://${local.gke_cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(local.gke_cluster_ca_certificate)
  load_config_file       = false
}

module "ingress_nginx" {
  source = "./modules/ingress-nginx"
  count  = var.install_helm_charts && var.ingress_nginx ? 1 : 0

  internet_facing_ingress_lb = var.internet_facing_ingress_lb

  namespace                  = var.ingress_nginx_namespace
  custom_values_templatefile = var.ingress_nginx_values
  custom_values_variables    = var.ingress_nginx_variables

  depends_on = [local.gke_cluster_name]
}


module "cert_manager" {
  source = "./modules/cert-manager"
  count  = var.install_helm_charts && var.cert_manager ? 1 : 0

  google_project_id = var.google_project_id

  name                       = var.name
  dns_zone_name              = local.public_dns_zone_name
  letsencrypt_clusterissuers = var.cert_manager_letsencrypt_clusterissuers
  email_address              = var.cert_manager_letsencrypt_email_address

  namespace                  = var.cert_manager_namespace
  custom_values_templatefile = var.cert_manager_values
  custom_values_variables    = var.cert_manager_variables

  depends_on = [local.gke_cluster_name]
}


module "external_dns" {
  source = "./modules/external-dns"
  count  = var.install_helm_charts && var.external_dns ? 1 : 0

  google_project_id = var.google_project_id

  name             = var.name
  domain_name      = var.domain_name
  dns_zone_name    = var.internet_facing_ingress_lb ? local.public_dns_zone_name : local.private_dns_zone_name
  gke_cluster_name = local.gke_cluster_name
  zone_visibility  = var.internet_facing_ingress_lb ? "public" : "private"

  namespace                  = var.external_dns_namespace
  custom_values_templatefile = var.external_dns_values
  custom_values_variables    = var.external_dns_variables
}


module "nvidia_device_plugin" {
  source = "./modules/nvidia-device-plugin"
  count  = var.install_helm_charts && var.nvidia_device_plugin ? 1 : 0

  namespace                  = var.nvidia_device_plugin_namespace
  custom_values_templatefile = var.nvidia_device_plugin_values
  custom_values_variables    = var.nvidia_device_plugin_variables

  depends_on = [local.gke_cluster_name]
}

module "descheduler" {
  source = "./modules/descheduler"
  count  = var.install_helm_charts && var.descheduler ? 1 : 0

  namespace                  = var.descheduler_namespace
  custom_values_templatefile = var.descheduler_values
  custom_values_variables    = var.descheduler_variables

  depends_on = [local.gke_cluster_name]
}
