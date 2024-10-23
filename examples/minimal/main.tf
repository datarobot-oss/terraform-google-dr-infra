provider "google" {}

locals {
  name   = "datarobot"
  region = "us-west1"
}


module "datarobot_infra" {
  source = "../.."

  google_project_id                      = "your-google-project-id"
  region                                 = local.region
  name                                   = local.name
  domain_name                            = "${local.name}.yourdomain.com"
  cert_manager_letsencrypt_email_address = "youremail@yourdomain.com"

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}
