locals {
  name      = "ingress-nginx"
  namespace = "ingress-nginx"
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = local.namespace
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = local.name
  version    = "4.11.5"

  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml", {
      loadBalancerType = var.internet_facing_ingress_lb ? "External" : "Internal"
    }),
    var.values_overrides
  ]
}

resource "kubectl_manifest" "internal_ingress_psc" {
  count = var.create_psc && !var.internet_facing_ingress_lb ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "networking.gke.io/v1"
    kind       = "ServiceAttachment"
    metadata = {
      name      = "datarobot-internal-ingress-psc"
      namespace = local.namespace
    }
    spec = {
      connectionPreference = var.psc_connection_preference
      consumerAllowList    = [for project_id in var.psc_consumer_allow_list_projects : { project = project_id }]
      natSubnets           = var.psc_nat_subnets
      proxyProtocol        = false
      resourceRef = {
        kind = "Service"
        name = "ingress-nginx-controller"
      }
    }
  })

  depends_on = [helm_release.this]
}
