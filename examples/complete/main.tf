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
  create_network          = true
  network_address_space   = "10.7.0.0/16"
  kubernetes_pod_cidr     = "192.168.0.0/18"
  kubernetes_service_cidr = "192.168.64.0/18"

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
  kubernetes_cluster_version                = "1.30"
  release_channel                           = "REGULAR"
  kubernetes_cluster_deletion_protection    = false
  kubernetes_cluster_endpoint_public_access = true
  kubernetes_cluster_endpoint_access_list   = ["${local.provisioner_public_ip}/32"]
  kubernetes_master_ipv4_cidr_block         = "10.7.16.0/28"
  kubernetes_primary_nodepool_name          = "primary"
  kubernetes_primary_nodepool_vm_size       = "e2-standard-32"
  kubernetes_primary_nodepool_node_count    = 1
  kubernetes_primary_nodepool_min_count     = 1
  kubernetes_primary_nodepool_max_count     = 10
  kubernetes_primary_nodepool_labels = {
    "datarobot.com/node-capability" = "cpu"
  }
  kubernetes_primary_nodepool_taints = []

  kubernetes_gpu_nodepool_name       = "gpu"
  kubernetes_gpu_nodepool_vm_size    = "n1-highmem-4"
  kubernetes_gpu_nodepool_node_count = 0
  kubernetes_gpu_nodepool_min_count  = 0
  kubernetes_gpu_nodepool_max_count  = 10
  kubernetes_gpu_nodepool_labels = {
    "datarobot.com/node-capability" = "gpu"
  }
  kubernetes_gpu_nodegroup_taints = [
    {
      key    = "nvidia.com/gpu"
      value  = ""
      effect = "NO_SCHEDULE"
    }
  ]

  ################################################################################
  # App Identity
  ################################################################################
  create_app_identity = true
  datarobot_namespace = "dr-app"
  datarobot_service_accounts = [
    "dr",
    "build-service",
    "build-service-image-builder",
    "buzok-account",
    "dr-lrs-operator",
    "dynamic-worker",
    "internal-api-sa",
    "nbx-notebook-revisions-account",
    "prediction-server-sa",
    "tileservergl-sa"
  ]

  ################################################################################
  # Helm Charts
  ################################################################################
  install_helm_charts = true

  ################################################################################
  # ingress-nginx
  ################################################################################
  ingress_nginx              = true
  ingress_nginx_namespace    = "ingress-nginx"
  internet_facing_ingress_lb = true

  # in this case our custom values file override is formatted as a templatefile
  # so we can pass variables like our provisioner_public_ip to it.
  # https://developer.hashicorp.com/terraform/language/functions/templatefile
  ingress_nginx_values = "${path.module}/templates/custom_ingress_nginx_values.tftpl"
  ingress_nginx_variables = {
    lb_source_ranges = ["${local.provisioner_public_ip}/32"]
  }

  ################################################################################
  # cert-manager
  ################################################################################
  cert_manager                            = true
  cert_manager_namespace                  = "cert-manager"
  cert_manager_letsencrypt_clusterissuers = true
  cert_manager_letsencrypt_email_address  = "youremail@yourdomain.com"
  cert_manager_values                     = "${path.module}/templates/custom_cert_manager_values.yaml"
  cert_manager_variables                  = {}

  ################################################################################
  # external-dns
  ################################################################################
  external_dns           = true
  external_dns_namespace = "external-dns"
  external_dns_values    = "${path.module}/templates/custom_external_dns_values.yaml"
  external_dns_variables = {}

  ################################################################################
  # nvidia-device-plugin
  ################################################################################
  nvidia_device_plugin           = true
  nvidia_device_plugin_namespace = "nvidia-device-plugin"
  nvidia_device_plugin_values    = "${path.module}/templates/custom_nvidia_device_plugin_values.yaml"
  nvidia_device_plugin_variables = {}

  ################################################################################
  # descheduler
  ################################################################################
  descheduler           = true
  descheduler_namespace = "kube-system"
  descheduler_values    = "${path.module}/templates/custom_descheduler_values.yaml"
  descheduler_variables = {}
}
