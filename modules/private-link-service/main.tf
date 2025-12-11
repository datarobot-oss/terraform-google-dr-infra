locals {
  namespace = "ingress-nginx"
}

resource "kubectl_manifest" "internal_ingress_psc" {
  yaml_body = yamlencode({
    apiVersion = "networking.gke.io/v1"
    kind       = "ServiceAttachment"
    metadata = {
      name      = "datarobot-internal-ingress-psc"
      namespace = local.namespace
    }
    spec = {
      connectionPreference = var.ingress_psc_connection_preference
      consumerAllowList    = [for project_id in var.ingress_psc_consumer_allow_list_projects : { project = project_id }]
      natSubnets           = var.psc_nat_subnets
      proxyProtocol        = false
      resourceRef = {
        kind = "Service"
        name = var.ingress_service_name
      }
    }
  })

  depends_on = [kubectl_manifest.namespace]
}

resource "kubectl_manifest" "namespace" {
  count = var.create_namespace ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = local.namespace
    }
  })
}
