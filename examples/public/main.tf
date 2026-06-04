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

  dns_zone_force_destroy                 = !local.is_prod
  storage_force_destroy                  = !local.is_prod
  kubernetes_cluster_deletion_protection = local.is_prod
  postgres_deletion_protection           = local.is_prod

  tags = merge(
    {
      app         = var.name
      environment = var.environment
    },
    var.tags
  )
}
