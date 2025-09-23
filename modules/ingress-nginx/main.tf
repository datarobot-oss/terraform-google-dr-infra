resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = var.namespace
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.5"

  create_namespace = true

  values = [
    templatefile("${path.module}/common.yaml", {}),
    templatefile(var.internet_facing_ingress_lb ? "${path.module}/internet_facing.yaml" : "${path.module}/internal.yaml", {}),
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]
}

resource "kubectl_manifest" "internal_ingress_psc" {
  count = var.create_psc && !var.internet_facing_ingress_lb ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "networking.gke.io/v1"
    kind       = "ServiceAttachment"
    metadata = {
      name      = "datarobot-internal-ingress-psc"
      namespace = "ingress-nginx"
    }
    spec = {
      connectionPreference = var.psc_connection_preference
      consumerAllowList    = [for project_id in var.psc_consumer_allow_list_projects : { project = project_id }]
      natSubnets           = var.psc_nat_subnets
      proxyProtocol        = false
      resourceRef = {
        kind = "Service"
        name = "ingress-nginx-controller-internal"
      }
    }
  })

  depends_on = [helm_release.ingress_nginx]
}
