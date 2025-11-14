locals {
  name            = "external-dns"
  namespace       = "external-dns"
  service_account = "external-dns"
}

module "workload_identity" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "~> 33.0"

  project_id = var.google_project_id

  name                = "${var.name}-${local.name}"
  namespace           = local.namespace
  use_existing_k8s_sa = true
  k8s_sa_name         = local.service_account
  annotate_k8s_sa     = false
  roles               = ["roles/dns.reader"]
}

resource "google_dns_managed_zone_iam_member" "dns_admin" {
  project      = var.google_project_id
  managed_zone = var.dns_zone_name
  role         = "roles/dns.admin"
  member       = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = local.namespace
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = local.name
  version    = "1.19.0"

  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml", {
      domain         = var.domain_name
      clusterName    = var.gke_cluster_name
      projectId      = var.google_project_id
      zoneVisibility = var.zone_visibility
      serviceAccount = module.workload_identity.gcp_service_account_email
    }),
    var.values_overrides
  ]

  depends_on = [google_dns_managed_zone_iam_member.dns_admin]
}
