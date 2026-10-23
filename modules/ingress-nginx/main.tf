locals {
  name      = "ingress-nginx"
  namespace = "ingress-nginx"
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = local.namespace
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = local.name
  version    = var.chart_version

  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml", {
      loadBalancerType = var.internet_facing_ingress_lb ? "External" : "Internal"
    }),
    var.values_overrides
  ]
}
