module "cert_manager_wid" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "~> 33.0"

  project_id = var.google_project_id

  name                = "${var.name}-cert-manager"
  namespace           = var.namespace
  use_existing_k8s_sa = true
  k8s_sa_name         = "cert-manager"
  annotate_k8s_sa     = false
  roles               = ["roles/dns.reader"]
}

resource "google_dns_managed_zone_iam_member" "cert_manager" {
  project      = var.google_project_id
  managed_zone = var.dns_zone_name
  role         = "roles/dns.admin"
  member       = "serviceAccount:${module.cert_manager_wid.gcp_service_account_email}"
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = var.namespace
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.16.1"

  create_namespace = true

  values = [
    templatefile("${path.module}/values.tftpl", {
      serviceAccount = module.cert_manager_wid.gcp_service_account_email
    }),
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]

  depends_on = [google_dns_managed_zone_iam_member.cert_manager]
}

resource "helm_release" "letsencrypt_clusterissuers" {
  count = var.letsencrypt_clusterissuers ? 1 : 0

  name       = "letsencrypt-clusterissuers"
  namespace  = var.namespace
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

  depends_on = [helm_release.cert_manager]
}
