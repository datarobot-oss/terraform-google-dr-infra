terraform {
  required_version = ">= 1.5.7"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.19"
    }
  }
}
