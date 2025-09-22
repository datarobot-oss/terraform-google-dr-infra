terraform {
  required_version = ">=1.2.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.6.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
  }
}
