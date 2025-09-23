variable "internet_facing_ingress_lb" {
  description = "Connect to the DataRobot application via an complete load balancer"
  type        = bool
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

variable "create_psc" {
  description = "Expose the internal LB created by the ingress-nginx controller as a Google Private Service Connection. Only applies if internet_facing_ingress_lb is false."
  type        = bool
  default     = false
}

variable "psc_connection_preference" {
  description = "The connection preference that determines how customers connect to the service. You can either use automatic project approval using ACCEPT_AUTOMATIC or explicit project approval using ACCEPT_MANUAL"
  type        = string
  default     = "ACCEPT_MANUAL"

  validation {
    condition     = var.psc_connection_preference == "ACCEPT_MANUAL" || var.psc_connection_preference == "ACCEPT_AUTOMATIC"
    error_message = "psc_connection_preference must be either ACCEPT_MANUAL or ACCEPT_AUTOMATIC"
  }
}

variable "psc_consumer_allow_list_projects" {
  description = "The list of consumer project IDs that are allowed to connect to the ServiceAttachment. This field can only be used when connectionPreference is ACCEPT_MANUAL."
  type        = list(string)
  default     = []
}

variable "psc_nat_subnets" {
  description = "A list of subnetwork resource names to use for the service attachment."
  type        = list(string)
  default     = []
}
