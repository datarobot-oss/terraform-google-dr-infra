variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "domain_name" {
  description = "Name of the domain to use for the DataRobot application. If create_dns_zones is true then zones will be created for this domain. It is also used by the cert-manager helm chart for DNS validation and as a domain filter by the external-dns helm chart."
  type        = string
  default     = ""
}

variable "google_project_id" {
  description = "The ID of the Google Project where these resources will be created"
  type        = string
}

variable "region" {
  description = "Google region to create the resources in"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all created resources"
  type        = map(string)
  default = {
    managed-by = "terraform"
  }
}


################################################################################
# Network
################################################################################

variable "existing_vpc_name" {
  description = "Name of an existing Google VPC to use. When specified, other network variables are ignored."
  type        = string
  default     = null
}

variable "create_network" {
  description = "Create a new Google VPC. Ignored if an existing existing_vpc_id is specified."
  type        = bool
  default     = true
}

variable "network_address_space" {
  description = "The CIDR to use for the VPC and subnets created by this module"
  type        = string
  default     = "10.0.0.0/20"
}

variable "kubernetes_nodes_cidr" {
  description = "The CIDR to use for Kubernetes nodes IP addresses. This is used as the primary IP range for the Kubernetes nodes subnet."
  type        = string
  default     = null
}

variable "kubernetes_master_ipv4_cidr" {
  description = "The IP range in CIDR notation to use for the hosted master network including the Kubernetes control plane. If you use this flag, GKE creates a new subnet that uses the values you defined in master-ipv4-cidr and uses the new subnet to provision the internal IP address for the control plane."
  type        = string
  default     = null
}

variable "kubernetes_pod_cidr" {
  description = "The CIDR to use for Kubernetes pod IP addresses. This is used as a secondary IP range within the Kubernetes nodes subnet."
  type        = string
  default     = "172.16.0.0/15"
}

variable "postgres_cidr" {
  description = "CIDR range to use for PostgreSQL private IP"
  type        = string
  default     = null
}

variable "redis_cidr" {
  description = "CIDR range to use for Redis private IP"
  type        = string
  default     = null
}

variable "mongodb_subnet_cidr" {
  description = "CIDR range to use for MongoDB Atlas VPC Peering. Only used when `create_network` is `true` and an `existing_vpc_name` is not specified."
  type        = string
  default     = null
}


################################################################################
# DNS
################################################################################

variable "existing_public_dns_zone_name" {
  description = "ID of existing public hosted zone to use for public DNS records created by external-dns and public LetsEncrypt certificate validation by cert-manager. This is required when create_dns_zones is false and ingress_nginx and internet_facing_ingress_lb are true or when cert_manager and cert_manager_letsencrypt_clusterissuers are true."
  type        = string
  default     = null
}

variable "existing_private_dns_zone_name" {
  description = "ID of existing private hosted zone to use for private DNS records created by external-dns. This is required when create_dns_zones is false and ingress_nginx is true with internet_facing_ingress_lb false."
  type        = string
  default     = null
}

variable "create_dns_zones" {
  description = "Create DNS zones for domain_name. Ignored if existing_public_dns_zone_id and existing_private_dns_zone_id are specified."
  type        = bool
  default     = true
}

variable "dns_zones_force_destroy" {
  description = "Force destroy for the public and private Cloud DNS zones when terminating"
  type        = bool
  default     = false
}


################################################################################
# Storage
################################################################################

variable "existing_gcs_bucket_name" {
  description = "ID of existing Google Storage Bucket to use for DataRobot file storage. When specified, all other storage variables will be ignored."
  type        = string
  default     = null
}

variable "create_storage" {
  description = "Create a new Google Storage Bucket to use for DataRobot file storage. Ignored if an existing_gcs_bucket_name is specified."
  type        = bool
  default     = true
}

variable "storage_force_destroy" {
  description = "Force destroy for the public and private Cloud DNS zones when terminating"
  type        = bool
  default     = false
}


################################################################################
# Container Registry
################################################################################

variable "existing_artifact_registry_repo_id" {
  description = "ID of existing artifact registry repository to use"
  type        = string
  default     = null
}


variable "create_container_registry" {
  description = "Create a new Google Container Registry. Ignored if an existing existing_artifact_registry_repo_id is specified."
  type        = bool
  default     = true
}


################################################################################
# Kubernetes
################################################################################

variable "existing_gke_cluster_name" {
  description = "Name of existing GKE cluster to use. When specified, all other kubernetes variables will be ignored."
  type        = string
  default     = null
}


variable "existing_kubernetes_nodes_subnet" {
  description = "Name of an existing subnet to use for the GKE node pools and control plane private endpoint. Required when `create_kubernetes_cluster` is `true` and an `existing_vpc_name` is specified. Ignored if no `existing_vpc_name` is specified."
  type        = string
  default     = null
}

variable "existing_kubernetes_pods_range_name" {
  description = "Name of an secondary IP range within subnet defined by existing_kubernetes_nodes_subnet_name to use for the Kubernetes pods. Required when an existing_vpc_name is specified. Ignored if no existing_vpc_name is specified."
  type        = string
  default     = null
}

variable "create_kubernetes_cluster" {
  description = "Create a new Google Kubernetes Engine cluster. All kubernetes and helm chart variables are ignored if this variable is false."
  type        = bool
  default     = true
}

variable "kubernetes_cluster_version" {
  description = "GKE cluster version"
  type        = string
  default     = "latest"
}

variable "release_channel" {
  type        = string
  description = "The release channel of this cluster. Accepted values are `UNSPECIFIED`, `RAPID`, `REGULAR` and `STABLE`. Defaults to `STABLE`."
  default     = "STABLE"
}

variable "kubernetes_cluster_deletion_protection" {
  description = "Enable deletion protection on the GKE cluster"
  type        = bool
  default     = true
}

variable "kubernetes_cluster_grant_registry_access" {
  description = "Grants created cluster-specific service account storage.objectViewer and artifactregistry.reader roles"
  type        = bool
  default     = true
}

variable "kubernetes_cluster_endpoint_public_access" {
  description = "Whether the Kubernetes cluster API endpoint can be accessed via an external IP address"
  type        = bool
  default     = true
}

variable "kubernetes_cluster_endpoint_access_list" {
  description = "List of CIDRs allowed to access the Kubernetes cluster API endpoint. When kubernetes_cluster_endpoint_public_access is true, these CIDRs specify which public IP addresses are allowed to access the Kubernetes cluster API external endpoint. When kubernetes_cluster_endpoint_public_access is false, these CIDRs specify which private IP addresses are allowed to access the Kubernetes cluster API internal endpoint. By default, only hosts within the kubernetes nodes subnet are allowed to access the Kubernetes cluster API internal endpoint."
  type        = list(string)
  default     = []
}

variable "kubernetes_node_pools" {
  description = "Map of GKE node pools"
  type        = any
  default = {
    drcpu = {
      name         = "drcpu"
      machine_type = "e2-standard-32"
      disk_size_gb = 200
      node_count   = 1
      min_count    = 1
      max_count    = 10
      node_labels = {
        "datarobot.com/node-capability" = "cpu"
      }
      node_taints = []
    }
    drgpu = {
      name       = "drgpu"
      vm_size    = "n1-highmem-4"
      node_count = 0
      min_count  = 0
      max_count  = 10
      node_labels = {
        "datarobot.com/node-capability" = "gpu"
      }
      node_taints = [{
        key    = "nvidia.com/gpu"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }
}


################################################################################
# App Identity
################################################################################

variable "create_app_identity" {
  description = "Create a new user assigned identity for the DataRobot application"
  type        = bool
  default     = true
}

variable "datarobot_namespace" {
  description = "Kubernetes namespace in which the DataRobot application will be installed"
  type        = string
  default     = "dr-app"
}

variable "datarobot_service_accounts" {
  description = "Kubernetes service accounts in the datarobot_namespace to provide with Storage Blob Data Contributor and AcrPush access"
  type        = set(string)
  default = [
    "datarobot-storage-sa",
    "dynamic-worker",
    "kubeworker-sa",
    "prediction-server-sa",
    "internal-api-sa",
    "build-service",
    "tileservergl-sa",
    "nbx-notebook-revisions-account",
    "buzok-account",
    "exec-manager-qw",
    "exec-manager-wrangling",
    "lrs-job-manager",
    "blob-view-service",
  ]
}


################################################################################
# PostgreSQL
################################################################################

variable "create_postgres" {
  description = "Whether to create a CloudSQL for PostgreSQL instance"
  type        = bool
  default     = false
}

variable "postgres_database_version" {
  description = "The PostgreSQL version to use"
  type        = string
  default     = "POSTGRES_13"
}

variable "postgres_availability_type" {
  description = "The availability type of the Cloud SQL instance, high availability (REGIONAL) or single zone (ZONAL)"
  type        = string
  default     = "REGIONAL"
}

variable "postgres_tier" {
  description = "The machine type to use. See tiers for more details and supported versions. Postgres supports only shared-core machine types, and custom machine types such as db-custom-2-13312."
  type        = string
  default     = "db-custom-4-16384"
}

variable "postgres_disk_type" {
  description = "The type of data disk: PD_SSD, PD_HDD, or HYPERDISK_BALANCED"
  type        = string
  default     = "PD_SSD"
}

variable "postgres_disk_size" {
  description = "The size of data disk, in GB. Size of a running instance cannot be reduced but can be increased"
  type        = number
  default     = 20
}

variable "postgres_disk_autoresize_limit" {
  description = "The maximum size to which storage capacity can be automatically increased. The default value is 0, which specifies that there is no limit."
  type        = number
  default     = 0
}

variable "postgres_deletion_protection" {
  description = "Whether Terraform will be prevented from destroying the instance. When the field is set to true or unset in Terraform state, a terraform apply or terraform destroy that would delete the instance will fail. When the field is set to false, deleting the instance is allowed"
  type        = bool
  default     = false
}

variable "postgres_database_flags" {
  description = "The database flags for the Cloud SQL instance."
  type = list(object({
    name  = string
    value = string
  }))
  default = [{ name = "password_encryption", value = "scram-sha-256" }]
}
################################################################################
# Redis
################################################################################

variable "create_redis" {
  description = "Whether to create a Google Memorystore Redis instance"
  type        = bool
  default     = false
}

variable "redis_tier" {
  description = "The service tier of the instance: BASIC or STANDARD_HA"
  type        = string
  default     = "STANDARD_HA"
}

variable "redis_transit_encryption_mode" {
  description = "The TLS mode of the Redis instance, If not provided, TLS is enabled for the instance. Possible values are: SERVER_AUTHENTICATION, DISABLED."
  type        = string
  default     = "SERVER_AUTHENTICATION"
}

variable "redis_memory_size_gb" {
  description = "Redis memory size in GiB. Defaulted to 1 GiB"
  type        = number
  default     = 8
}


################################################################################
# MongoDB
################################################################################

variable "create_mongodb" {
  description = "Whether to create a MongoDB Atlas instance"
  type        = bool
  default     = false
}

variable "existing_mongodb_subnet_name" {
  description = "Name of an existing subnet to use for MongoDB Atlas VPC Peering. Required when an existing_vpc_name is specified. Ignored if no existing_vpc_name is specified."
  type        = string
  default     = null
}

variable "mongodb_version" {
  description = "MongoDB version"
  type        = string
  default     = "7.0"
}

variable "mongodb_atlas_org_id" {
  description = "Atlas organization ID"
  type        = string
  default     = null
}

variable "mongodb_atlas_public_key" {
  description = "Public API key for Mongo Atlas"
  type        = string
  default     = ""
}

variable "mongodb_atlas_private_key" {
  description = "Private API key for Mongo Atlas"
  type        = string
  default     = ""
}

variable "mongodb_termination_protection_enabled" {
  description = "Enable protection to avoid accidental production cluster termination"
  type        = bool
  default     = false
}

variable "mongodb_audit_enable" {
  type        = bool
  description = "Enable database auditing for production instances only(cost incurred 10%)"
  default     = false
}

variable "mongodb_atlas_auto_scaling_disk_gb_enabled" {
  description = "Enable Atlas disk size autoscaling"
  type        = bool
  default     = true
}

variable "mongodb_atlas_disk_size" {
  description = "Starting atlas disk size"
  type        = string
  default     = "20"
}

variable "mongodb_atlas_instance_type" {
  description = "atlas instance type"
  type        = string
  default     = "M30"
}

variable "mongodb_admin_username" {
  description = "MongoDB admin username"
  type        = string
  default     = "pcs-mongodb"
}

variable "mongodb_enable_slack_alerts" {
  description = "Enable alert notifications to a Slack channel. When `true`, `slack_api_token` and `slack_notification_channel` must be set."
  type        = string
  default     = false
}

variable "mongodb_slack_api_token" {
  description = "Slack API token to use for alert notifications. Required when `enable_slack_alerts` is `true`."
  type        = string
  default     = null
}

variable "mongodb_slack_notification_channel" {
  description = "Slack channel to send alert notifications to. Required when `enable_slack_alerts` is `true`."
  type        = string
  default     = null
}

variable "mongodb_network_reservation_ip_offset" {
  type        = number
  default     = 2
  description = "Value to offset the network reservation IP"
}

################################################################################
# Helm Charts
################################################################################

variable "install_helm_charts" {
  description = "Whether to install helm charts into the target EKS cluster. All other helm chart variables are ignored if this is `false`."
  type        = bool
  default     = true
}

variable "internet_facing_ingress_lb" {
  description = "Determines the type of Load Balancer created for GKE ingress. If true, an external Load Balancer will be created. If false, an internal Load Balancer will be created."
  type        = bool
  default     = true
}

variable "ingress_nginx" {
  description = "Install the ingress-nginx helm chart to use as the ingress controller for the GKE cluster. All other ingress_nginx variables are ignored if this variable is false."
  type        = bool
  default     = true
}

variable "ingress_nginx_namespace" {
  description = "Namespace to install the helm chart into"
  type        = string
  default     = "ingress-nginx"
}

variable "ingress_nginx_values" {
  description = "Path to templatefile containing custom values for the ingress-nginx helm chart"
  type        = string
  default     = ""
}

variable "ingress_nginx_variables" {
  description = "Variables passed to the ingress_nginx_values templatefile"
  type        = any
  default     = {}
}

variable "existing_ingress_pcs_subnet_name" {
  description = "Name of an existing subnet to use for the Private Service Connection used by the ingress-nginx controller. Required when an existing_vpc_name is specified and create_ingress_psc is true. Ignored if no existing_vpc_name is specified or create_ingress_psc is false."
  type        = string
  default     = null
}

variable "ingress_psc_subnet_cidr" {
  description = "CIDR range to use for the Private Service Connection used by the ingress-nginx controller. Only used when `create_network` is `true` and an `existing_vpc_name` is not specified."
  type        = string
  default     = null
}

variable "cert_manager" {
  description = "Install the cert-manager helm chart. All other cert_manager variables are ignored if this variable is false."
  type        = bool
  default     = true
}

variable "cert_manager_namespace" {
  description = "Namespace to install the helm chart into"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_letsencrypt_clusterissuers" {
  description = "Whether to create letsencrypt-prod and letsencrypt-staging ClusterIssuers"
  type        = bool
  default     = true
}

variable "cert_manager_letsencrypt_email_address" {
  description = "Email address for the certificate owner. Let's Encrypt will use this to contact you about expiring certificates, and issues related to your account. Only required if cert_manager_letsencrypt_clusterissuers is true."
  type        = string
  default     = "user@example.com"
}

variable "cert_manager_values" {
  description = "Path to templatefile containing custom values for the cert-manager helm chart"
  type        = string
  default     = ""
}

variable "cert_manager_variables" {
  description = "Variables passed to the cert_manager_values templatefile"
  type        = any
  default     = {}
}

variable "external_dns" {
  description = "Install the external_dns helm chart to create DNS records for ingress resources matching the domain_name variable. All other external_dns variables are ignored if this variable is false."
  type        = bool
  default     = true
}

variable "external_dns_namespace" {
  description = "Namespace to install the helm chart into"
  type        = string
  default     = "external-dns"
}

variable "external_dns_values" {
  description = "Path to templatefile containing custom values for the external-dns helm chart"
  type        = string
  default     = ""
}

variable "external_dns_variables" {
  description = "Variables passed to the external_dns_values templatefile"
  type        = any
  default     = {}
}

variable "nvidia_device_plugin" {
  description = "Install the nvidia-device-plugin helm chart to expose node GPU resources to the GKE cluster. All other nvidia_device_plugin variables are ignored if this variable is false."
  type        = bool
  default     = true
}

variable "nvidia_device_plugin_namespace" {
  description = "Namespace to install the helm chart into"
  type        = string
  default     = "nvidia-device-plugin"
}

variable "nvidia_device_plugin_values" {
  description = "Path to templatefile containing custom values for the nvidia-device-plugin helm chart"
  type        = string
  default     = ""
}

variable "nvidia_device_plugin_variables" {
  description = "Variables passed to the nvidia_device_plugin_values templatefile"
  type        = any
  default     = {}
}

variable "descheduler" {
  description = "Install the descheduler helm chart to enable rescheduling of pods. All other descheduler variables are ignored if this variable is false"
  type        = bool
  default     = true
}

variable "descheduler_namespace" {
  description = "Namespace to install the helm chart into"
  type        = string
  default     = "kube-system"
}

variable "descheduler_values" {
  description = "Path to templatefile containing custom values for the descheduler helm chart"
  type        = string
  default     = ""
}

variable "descheduler_variables" {
  description = "Variables passed to the descheduler templatefile"
  type        = any
  default     = {}
}

################################################################################
# Privaete Link Service
################################################################################
variable "create_ingress_psc" {
  description = "Expose the internal LB created by the ingress-nginx controller as a Google Private Service Connection. Only applies if internet_facing_ingress_lb is false."
  type        = bool
  default     = false
}

variable "ingress_psc_consumer_projects" {
  description = "The list of consumer project IDs that are allowed to connect to the ServiceAttachment. This field can only be used when connectionPreference is ACCEPT_MANUAL."
  type        = list(string)
  default     = []
}

variable "create_ingress_psc_namespace" {
  description = "Whether to create a namespace for the ingress private service connect"
  type        = bool
  default     = false
}
