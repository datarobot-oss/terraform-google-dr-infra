module "cert_manager_wid" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "~> 33.0"

  project_id = var.google_project_id

  name                = "${var.name}-cert-manager"
  namespace           = "cert-manager"
  use_existing_k8s_sa = true
  k8s_sa_name         = "cert-manager"
  annotate_k8s_sa     = false
}

resource "google_dns_managed_zone_iam_member" "cert_manager" {
  project      = var.google_project_id
  managed_zone = var.dns_zone_name
  role         = "roles/dns.admin"
  member       = module.cert_manager_wid.gcp_service_account_email
}

module "cert_manager" {
  source  = "terraform-module/release/helm"
  version = "~> 2.0"

  namespace  = "cert-manager"
  repository = "https://charts.jetstack.io"

  app = {
    name             = "cert-manager"
    version          = "1.15.2"
    chart            = "cert-manager"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  values = [
    templatefile("${path.module}/values.tftpl", {
      serviceAccount = module.cert_manager_wid.gcp_service_account_email
    }),
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]

  depends_on = [google_dns_managed_zone_iam_member.cert_manager]
}

resource "kubectl_manifest" "letsencrypt_staging_clusterissuer" {
  count = var.letsencrypt_clusterissuers ? 1 : 0

  yaml_body = templatefile("${path.module}/letsencrypt_staging.tftpl", {
    email     = var.email_address,
    projectId = var.google_project_id
  })

  depends_on = [module.cert_manager]
}

resource "kubectl_manifest" "letsencrypt_prod_clusterissuer" {
  count = var.letsencrypt_clusterissuers ? 1 : 0

  yaml_body = templatefile("${path.module}/letsencrypt_prod.tftpl", {
    email     = var.email_address
    projectId = var.google_project_id
  })

  depends_on = [module.cert_manager]
}
