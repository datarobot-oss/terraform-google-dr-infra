variable "create_namespace" {
  description = "Whether to create the namespace for the ServiceAttachment"
  type        = bool
  default     = false
}

variable "ingress_psc_connection_preference" {
  description = "The connection preference that determines how customers connect to the service. You can either use automatic project approval using ACCEPT_AUTOMATIC or explicit project approval using ACCEPT_MANUAL"
  type        = string
  default     = "ACCEPT_MANUAL"

  validation {
    condition     = var.ingress_psc_connection_preference == "ACCEPT_MANUAL" || var.ingress_psc_connection_preference == "ACCEPT_AUTOMATIC"
    error_message = "ingress_psc_connection_preference must be either ACCEPT_MANUAL or ACCEPT_AUTOMATIC"
  }
}

variable "ingress_psc_consumer_allow_list_projects" {
  description = "The list of consumer project IDs that are allowed to connect to the ServiceAttachment. This field can only be used when connectionPreference is ACCEPT_MANUAL."
  type        = list(string)
  default     = []
}

variable "psc_nat_subnets" {
  description = "A list of subnetwork resource names to use for the service attachment."
  type        = list(string)
  default     = []
}

variable "ingress_service_name" {
  description = "The name of the ingress service to attach the private link to."
  type        = string
}
