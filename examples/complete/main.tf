provider "google" {}

locals {
  name                  = "datarobot"
  region                = "us-west1"
  provisioner_public_ip = "123.123.123.123"
}


module "datarobot_infra" {
  source = "../.."

  ################################################################################
  # General
  ################################################################################
  google_project_id = "your-google-project-id"
  region            = local.region
  name              = local.name
  domain_name       = "${local.name}.yourdomain.com"
  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }

  ################################################################################
  # Network
  ################################################################################
  create_network        = true
  network_address_space = "10.0.0.0/20"
  kubernetes_pod_cidr   = "172.16.0.0/15"

  ################################################################################
  # DNS
  ################################################################################
  create_dns_zones        = true
  dns_zones_force_destroy = true

  ################################################################################
  # Storage
  ################################################################################
  create_storage        = true
  storage_force_destroy = true

  ################################################################################
  # Container Registry
  ################################################################################
  create_container_registry = true

  ################################################################################
  # Kubernetes
  ################################################################################
  create_kubernetes_cluster                 = true
  kubernetes_cluster_version                = "1.33"
  release_channel                           = "REGULAR"
  kubernetes_cluster_deletion_protection    = false
  kubernetes_cluster_endpoint_public_access = true
  kubernetes_cluster_endpoint_access_list   = ["${local.provisioner_public_ip}/32"]
  kubernetes_master_ipv4_cidr               = "10.0.15.0/28"
  kubernetes_node_pools = {
    drcpu = {
      name         = "drcpu"
      machine_type = "e2-standard-32"
      disk_size_gb = 200
      node_count   = 1
      min_count    = 1
      max_count    = 10
      node_labels = {
        "datarobot.com/node-capability" = "cpu"
      }
      node_taints = []
    }
    drgpu = {
      name       = "drgpu"
      vm_size    = "n1-highmem-4"
      node_count = 0
      min_count  = 0
      max_count  = 10
      node_labels = {
        "datarobot.com/node-capability" = "gpu"
      }
      node_taints = [{
        key    = "nvidia.com/gpu"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  ################################################################################
  # App Identity
  ################################################################################
  create_app_identity = true
  datarobot_namespace = "dr-app"
  datarobot_service_accounts = [
    "datarobot-storage-sa",
    "dynamic-worker",
    "kubeworker-sa",
    "prediction-server-sa",
    "internal-api-sa",
    "build-service",
    "tileservergl-sa",
    "nbx-notebook-revisions-account",
    "buzok-account",
    "exec-manager-qw",
    "exec-manager-wrangling",
    "lrs-job-manager",
    "blob-view-service",
  ]

  ################################################################################
  # PostgreSQL
  ################################################################################
  create_postgres                = true
  postgres_database_version      = "POSTGRES_13"
  postgres_availability_type     = "ZONAL"
  postgres_tier                  = "db-custom-4-16384"
  postgres_disk_type             = "PD_SSD"
  postgres_disk_size             = 20
  postgres_disk_autoresize_limit = 0
  postgres_deletion_protection   = false

  ################################################################################
  # Redis
  ################################################################################
  create_redis                  = true
  redis_tier                    = "STANDARD_HA"
  redis_transit_encryption_mode = "SERVER_AUTHENTICATION"
  redis_memory_size_gb          = 8

  ################################################################################
  # MongoDB
  ################################################################################
  create_mongodb                             = true
  mongodb_version                            = "7.0"
  mongodb_atlas_org_id                       = "1a2b3c4d5e6f7g8h9i10j"
  mongodb_atlas_public_key                   = "atlas-public-key"
  mongodb_atlas_private_key                  = "atlas-private-key"
  mongodb_termination_protection_enabled     = false
  mongodb_audit_enable                       = true
  mongodb_admin_username                     = "pcs-mongodb"
  mongodb_atlas_auto_scaling_disk_gb_enabled = true
  mongodb_atlas_disk_size                    = 20
  mongodb_atlas_instance_type                = "M30"
  mongodb_enable_slack_alerts                = true
  mongodb_slack_api_token                    = "slack-api-token"
  mongodb_slack_notification_channel         = "mongodb-atlas-notifications"

  ################################################################################
  # Helm Charts
  ################################################################################
  install_helm_charts = true

  ################################################################################
  # ingress-nginx
  ################################################################################
  ingress_nginx                 = true
  internet_facing_ingress_lb    = true
  create_ingress_psc            = true
  ingress_psc_consumer_projects = ["your-google-project-id"]

  # in this case our custom values file override is formatted as a templatefile
  # so we can pass variables like our provisioner_public_ip to it.
  # https://developer.hashicorp.com/terraform/language/functions/templatefile
  ingress_nginx_values_overrides = templatefile("${path.module}/templates/custom_ingress_nginx_values.tftpl", {
    lb_source_ranges = ["${local.provisioner_public_ip}/32"]
  })

  ################################################################################
  # cert-manager
  ################################################################################
  cert_manager                            = true
  cert_manager_letsencrypt_clusterissuers = true
  cert_manager_letsencrypt_email_address  = "youremail@yourdomain.com"
  cert_manager_values_overrides           = file("${path.module}/templates/custom_cert_manager_values.yaml")

  ################################################################################
  # external-dns
  ################################################################################
  external_dns                  = true
  external_dns_values_overrides = file("${path.module}/templates/custom_external_dns_values.yaml")

  ################################################################################
  # nvidia-device-plugin
  ################################################################################
  nvidia_device_plugin                  = true
  nvidia_device_plugin_values_overrides = file("${path.module}/templates/custom_nvidia_device_plugin_values.yaml")

  ################################################################################
  # descheduler
  ################################################################################
  descheduler                  = true
  descheduler_values_overrides = file("${path.module}/templates/custom_descheduler_values.yaml")
}
