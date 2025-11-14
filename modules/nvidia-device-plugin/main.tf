locals {
  name      = "nvidia-device-plugin"
  namespace = "nvidia-device-plugin"
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = local.namespace
  repository = "https://nvidia.github.io/k8s-device-plugin"
  chart      = local.name
  version    = "v0.17.0"

  create_namespace = true

  values = [
    file("${path.module}/values.yaml"),
    var.values_overrides
  ]
}
