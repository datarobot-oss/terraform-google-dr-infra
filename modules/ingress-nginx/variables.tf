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
