variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "google_project_id" {
  description = "The ID of the Google Project where these resources will be created"
  type        = string
}

variable "domain_name" {
  description = "Name of the domain to filter for"
  type        = string
}

variable "dns_zone_name" {
  description = "Name of the DNS zone to create records in"
  type        = string
}

variable "gke_cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "zone_visibility" {
  description = "Filter zones by private or public visibility"
  type        = string
}

variable "namespace" {
  description = "Namespace to install the helm chart into"
  type        = string
}

variable "custom_values_templatefile" {
  description = "Custom values templatefile to pass to the helm chart"
  type        = string
}

variable "custom_values_variables" {
  description = "Variables for the custom values templatefile"
  type        = any
}
