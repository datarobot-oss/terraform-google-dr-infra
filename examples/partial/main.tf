provider "google" {}

locals {
  name           = "datarobot"
  project_id     = "your-google-project-id"
  region         = "us-west1"
  provisioner_ip = "10.0.0.99"
}


module "datarobot_infra" {
  source = "../.."

  name              = local.name
  google_project_id = local.project_id
  region            = local.region
  domain_name       = "${local.name}.rd.int.datarobot.com"

  existing_vpc_name                     = "existing-vpc-name"
  existing_kubernetes_nodes_subnet_name = "existing-subnet-name"
  existing_public_dns_zone_name         = "existing-public-dns-zone-name"
  existing_private_dns_zone_name        = "existing-private-dns-zone-name"
  existing_gcs_bucket_name              = "existing-gcs-bucket-name"
  existing_artifact_registry_repo_id    = "projects/${local.project_id}/locations/${local.region}/repositories/existing-repository-name"

  # disable public internet access to the Kubernetes API endpoint
  kubernetes_cluster_endpoint_public_access = false

  # allow a specific host running within a different subnet
  # in the same VPC to access the Kubernetes API endpoint
  kubernetes_cluster_endpoint_access_list = ["${local.provisioner_ip}/32"]

  # create an internal LB for ingress rather than external
  internet_facing_ingress_lb = false

  # bring your own clusterissuer/cert to the DataRobot helm chart
  cert_manager_letsencrypt_clusterissuers = false

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}
