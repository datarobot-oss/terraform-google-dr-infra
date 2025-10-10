module "external_dns_wid" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "~> 33.0"

  project_id = var.google_project_id

  name                = "${var.name}-external-dns"
  namespace           = var.namespace
  use_existing_k8s_sa = true
  k8s_sa_name         = "external-dns"
  annotate_k8s_sa     = false
  roles               = ["roles/dns.reader"]
}

resource "google_dns_managed_zone_iam_member" "external_dns" {
  project      = var.google_project_id
  managed_zone = var.dns_zone_name
  role         = "roles/dns.admin"
  member       = "serviceAccount:${module.external_dns_wid.gcp_service_account_email}"
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = var.namespace
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.19.0"

  create_namespace = true

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
