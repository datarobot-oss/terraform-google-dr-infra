locals {
  name      = "descheduler"
  namespace = "descheduler"
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = local.namespace
  repository = "https://kubernetes-sigs.github.io/descheduler"
  chart      = local.name
  version    = "0.31.0"

  create_namespace = true

  values = [
    file("${path.module}/values.yaml"),
    var.values_overrides
  ]
}
