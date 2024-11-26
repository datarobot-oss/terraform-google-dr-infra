provider "google" {}

locals {
  name       = "datarobot"
  project_id = "your-google-project-id"
  region     = "us-west1"
}


module "datarobot_infra" {
  source = "../.."

  name              = local.name
  google_project_id = local.project_id
  region            = local.region
  domain_name       = "${local.name}.yourdomain.com"

  existing_vpc_name                     = "existing-vpc-name"
  existing_kubernetes_nodes_subnet_name = "existing-subnet-name"
  existing_public_dns_zone_name         = "existing-public-dns-zone-name"
  existing_private_dns_zone_name        = "existing-private-dns-zone-name"
  existing_gcs_bucket_name              = "existing-gcs-bucket-name"
  existing_artifact_registry_repo_id    = "projects/${local.project_id}/locations/${local.region}/repositories/existing-repository-name"
  existing_gke_cluster_name             = "existing-gke-cluster-name"

  cert_manager_letsencrypt_email_address = "youremail@yourdomain.com"

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}
