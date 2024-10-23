module "external_dns_wid" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "~> 33.0"

  project_id = var.google_project_id

  name                = "${var.name}-external-dns"
  namespace           = "external-dns"
  use_existing_k8s_sa = true
  k8s_sa_name         = "external-dns"
  annotate_k8s_sa     = false
}

resource "google_dns_managed_zone_iam_member" "external_dns" {
  project      = var.google_project_id
  managed_zone = var.dns_zone_name
  role         = "roles/dns.admin"
  member       = module.external_dns_wid.gcp_service_account_email
}

module "external_dns" {
  source  = "terraform-module/release/helm"
  version = "~> 2.0"

  namespace  = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"

  app = {
    name             = "external-dns"
    version          = "8.3.5"
    chart            = "external-dns"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  values = [
    templatefile("${path.module}/values.tftpl", {
      domain         = var.domain_name
      clusterName    = var.gke_cluster_name
      projectId      = var.google_project_id
      zoneVisibility = var.zone_visibility
      serviceAccount = module.external_dns_wid.gcp_service_account_email
    }),
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]

  depends_on = [google_dns_managed_zone_iam_member.external_dns]
}
