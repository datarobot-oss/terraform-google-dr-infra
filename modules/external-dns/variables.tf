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

variable "values_overrides" {
  description = "Values in raw yaml format to pass to helm."
  type        = string
  default     = null
}
