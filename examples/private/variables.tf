variable "name" {
  description = "Name to apply to created resources."
  type        = string
}

variable "environment" {
  description = "Type of environment. Must be one of 'dev', 'staging', or 'prod'."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of 'dev', 'staging', or 'prod'."
  }
}

variable "google_project_id" {
  description = "ID of the Google project to deploy resources in."
  type        = string
}

variable "region" {
  description = "Google region to deploy resources in."
  type        = string
}

variable "domain_name" {
  description = "Domain name to use for the application."
  type        = string
}

variable "email_address" {
  description = "Email address for the LetsEncrypt ACME certificate owner. Let's Encrypt will use this to contact you about expiring certificates, and issues related to your account."
  type        = string
}

variable "existing_vpc_name" {
  description = "Name of an existing VPC to deploy resources into."
  type        = string
}

variable "existing_kubernetes_nodes_subnet" {
  description = "Name of an existing subnet within the VPC to use for the GKE node pools and control plane private endpoint."
  type        = string
}

variable "existing_kubernetes_pods_range_name" {
  description = "Name of the secondary IP range within the node subnet to use for the Kubernetes pods."
  type        = string
}

variable "provisioner_ip" {
  description = "IP address of the host running `terraform apply`. This IP is granted access to the private GKE cluster API endpoint."
  type        = string
}

variable "ingress_allowed_cidr" {
  description = "CIDR block allowed to access the internal ingress load balancer."
  type        = string
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default = {
    managed-by = "terraform"
  }
}
