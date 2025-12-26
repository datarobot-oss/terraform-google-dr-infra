variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "google_project_id" {
  description = "The ID of the Google Project where these resources will be created"
  type        = string
}

variable "region" {
  description = "The GCP region where the MongoDB Atlas private endpoint should exist"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "subnet" {
  description = "subnet which will host the private endpoint ip"
  type        = string
}

variable "labels" {
  description = "A map of tags to add to all created resources"
  type        = map(string)
}

variable "allow_psc_global_access" {
  description = "Whether to allow global access for Private Service Connect"
  type        = bool
}

variable "endpoint_config" {
  description = "Configuration for the specific endpoint"
  type = object({
    service_name     = string
    private_dns_zone = optional(string, "")
    private_dns_name = optional(string, "")
  })
}
