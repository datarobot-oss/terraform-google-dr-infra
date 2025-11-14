locals {
  name            = "cert-manager"
  namespace       = "cert-manager"
  service_account = "cert-manager"
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
  repository = "https://charts.jetstack.io"
  chart      = local.name
  version    = "1.16.1"

  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml", {
      serviceAccount = module.workload_identity.gcp_service_account_email
    }),
    var.values_overrides
  ]

  depends_on = [google_dns_managed_zone_iam_member.dns_admin]
}

resource "helm_release" "letsencrypt_clusterissuers" {
  count = var.letsencrypt_clusterissuers ? 1 : 0

  name       = "letsencrypt-clusterissuers"
  namespace  = local.namespace
  repository = "https://dysnix.github.io/charts"
  chart      = "raw"
  version    = "0.3.2"

  create_namespace = true

  values = [
    <<-EOF
    resources:
      - apiVersion: cert-manager.io/v1
        kind: ClusterIssuer
        metadata:
          name: letsencrypt-staging
        spec:
          acme:
            server: https://acme-staging-v02.api.letsencrypt.org/directory
            email: ${var.email_address}
            privateKeySecretRef:
              name: letsencrypt-staging
            solvers:
              - dns01:
                  cloudDNS:
                    project: ${var.google_project_id}
      - |
          apiVersion: cert-manager.io/v1
          kind: ClusterIssuer
          metadata:
            name: letsencrypt-prod
          spec:
            acme:
              server: https://acme-v02.api.letsencrypt.org/directory
              email: ${var.email_address}
              privateKeySecretRef:
                name: letsencrypt-prod
              solvers:
                - dns01:
                    cloudDNS:
                      project: ${var.google_project_id}
    EOF
  ]

  depends_on = [helm_release.this]
}
