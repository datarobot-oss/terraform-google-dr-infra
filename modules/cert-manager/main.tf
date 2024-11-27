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

module "cert_manager" {
  source  = "terraform-module/release/helm"
  version = "~> 2.0"

  namespace  = var.namespace
  repository = "https://charts.jetstack.io"

  app = {
    name             = "cert-manager"
    version          = "1.16.1"
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

module "letsencrypt_clusterissuers" {
  source  = "terraform-module/release/helm"
  version = "~> 2.0"
  count   = var.letsencrypt_clusterissuers ? 1 : 0

  namespace  = "cert-manager"
  repository = "https://dysnix.github.io/charts"

  app = {
    name             = "letsencrypt-clusterissuers"
    version          = "0.3.2"
    chart            = "raw"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }
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

  depends_on = [module.cert_manager]
}
