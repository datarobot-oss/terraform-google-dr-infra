provider "google" {
  project = var.google_project_id
  region  = var.region
}

locals {
  is_prod = var.environment == "prod"
}

module "datarobot_infra" {
  source = "../.."

  name                                   = var.name
  google_project_id                      = var.google_project_id
  region                                 = var.region
  domain_name                            = var.domain_name
  cert_manager_letsencrypt_email_address = var.email_address

  # Deploy into an existing VPC. When an existing VPC is used, the node subnet
  # and the secondary IP range used for pods must be provided as well.
  existing_vpc_name                   = var.existing_vpc_name
  existing_kubernetes_nodes_subnet    = var.existing_kubernetes_nodes_subnet
  existing_kubernetes_pods_range_name = var.existing_kubernetes_pods_range_name

  dns_zone_force_destroy                 = !local.is_prod
  storage_force_destroy                  = !local.is_prod
  kubernetes_cluster_deletion_protection = local.is_prod
  postgres_deletion_protection           = local.is_prod

  # When kubernetes_cluster_endpoint_public_access is false, the host running "terraform apply"
  # must be granted access to the cluster private API endpoint in order to install helm charts.
  kubernetes_cluster_endpoint_public_access = false
  kubernetes_cluster_endpoint_access_list   = ["${var.provisioner_ip}/32"]

  internet_facing_ingress_lb = false
  # Allow a CIDR to access the internal ingress load balancer
  ingress_nginx_values_overrides = <<-EOT
    controller:
      service:
        loadBalancerSourceRanges:
          - "${var.ingress_allowed_cidr}"
  EOT

  tags = merge(
    {
      app         = var.name
      environment = var.environment
    },
    var.tags
  )
}
