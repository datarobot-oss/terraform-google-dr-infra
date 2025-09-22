locals {
  cloud_provider = "GCP"
  region         = lookup(local.atlas_regions, var.region)
}

resource "mongodbatlas_project" "this" {
  org_id = var.atlas_org_id
  name   = var.name
}

resource "mongodbatlas_project_ip_access_list" "this" {
  project_id = mongodbatlas_project.this.id
  cidr_block = var.project_ip_access_list
}

resource "mongodbatlas_privatelink_endpoint" "this" {
  project_id               = mongodbatlas_project.this.id
  provider_name            = local.cloud_provider
  region                   = local.region
  delete_on_create_timeout = true
  timeouts {
    create = "30m"
    delete = "30m"
  }
}

resource "google_compute_subnetwork" "this" {
  project       = var.google_project_id
  region        = var.region
  name          = "${var.name}-vpc-snet-mongodb"
  description   = "MongoDB Atlas Subnet"
  ip_cidr_range = var.subnet_cidr
  network       = var.vpc_name
}

# https://github.com/mongodb/terraform-provider-mongodbatlas/tree/v2.0.0/examples/mongodbatlas_privatelink_endpoint/gcp
# Create Google 50 Addresses
resource "google_compute_address" "this" {
  count        = 50
  project      = var.google_project_id
  name         = "${var.name}-mongodb-address-${count.index}"
  subnetwork   = google_compute_subnetwork.this.id
  address_type = "INTERNAL"
  address      = cidrhost(var.subnet_cidr, count.index + 2) # GCP reserves first 2 addresses in subnet
  region       = var.region
  labels       = var.tags
}

# Create 50 Forwarding rules
resource "google_compute_forwarding_rule" "this" {
  count                 = 50
  target                = mongodbatlas_privatelink_endpoint.this.service_attachment_names[count.index]
  project               = var.google_project_id
  region                = var.region
  name                  = google_compute_address.this[count.index].name
  ip_address            = google_compute_address.this[count.index].id
  network               = var.vpc_name
  load_balancing_scheme = ""
  labels                = var.tags
}

resource "mongodbatlas_privatelink_endpoint_service" "this" {
  project_id               = mongodbatlas_project.this.id
  private_link_id          = mongodbatlas_privatelink_endpoint.this.private_link_id
  provider_name            = local.cloud_provider
  endpoint_service_id      = var.vpc_name
  gcp_project_id           = var.google_project_id
  delete_on_create_timeout = true
  timeouts {
    create = "30m"
    delete = "30m"
  }
  dynamic "endpoints" {
    for_each = google_compute_address.this

    content {
      ip_address    = endpoints.value["address"]
      endpoint_name = google_compute_forwarding_rule.this[endpoints.key].name
    }
  }
}

resource "mongodbatlas_advanced_cluster" "this" {
  project_id   = mongodbatlas_project.this.id
  name         = var.name
  cluster_type = "REPLICASET"

  mongo_db_major_version         = var.mongodb_version
  backup_enabled                 = true
  pit_enabled                    = true
  termination_protection_enabled = var.termination_protection_enabled

  replication_specs = [{
    region_configs = [{
      provider_name = local.cloud_provider
      region_name   = local.region
      priority      = 7

      electable_specs = {
        instance_size = var.atlas_instance_type
        disk_size_gb  = var.atlas_disk_size
        node_count    = 3
      }

      auto_scaling = {
        disk_gb_enabled = var.atlas_auto_scaling_disk_gb_enabled
      }
    }]
  }]

  advanced_configuration = {
    javascript_enabled           = true
    minimum_enabled_tls_protocol = "TLS1_2"
  }

  lifecycle {
    ignore_changes = [replication_specs[0].region_configs[0].electable_specs[0].disk_size_gb]
  }

  depends_on = [mongodbatlas_privatelink_endpoint_service.this]
}

resource "mongodbatlas_cloud_backup_schedule" "this" {
  project_id   = mongodbatlas_project.this.id
  cluster_name = mongodbatlas_advanced_cluster.this.name

  policy_item_hourly {
    frequency_interval = 6 #accepted values = 1, 2, 4, 6, 8, 12 -> every n hours
    retention_unit     = "days"
    retention_value    = 7
  }
  policy_item_daily {
    frequency_interval = 1 #accepted values = 1 -> every 1 day
    retention_unit     = "days"
    retention_value    = 30
  }
  policy_item_weekly {
    frequency_interval = 6 # accepted values = 1 to 7 -> every 1=Monday,2=Tuesday,3=Wednesday,4=Thursday,5=Friday,6=Saturday,7=Sunday day of the week
    retention_unit     = "days"
    retention_value    = 30
  }
  policy_item_monthly {
    frequency_interval = 1 # accepted values = 1 to 28 -> 1 to 28 every nth day of the month
    # accepted values = 40 -> every last day of the month
    retention_unit  = "months"
    retention_value = 1
  }
  copy_settings {
    cloud_provider = local.cloud_provider
    frequencies = [
      "HOURLY",
      "DAILY",
      "WEEKLY",
      "MONTHLY",
      "ON_DEMAND"
    ]
    region_name        = lookup(local.atlas_copy_regions, local.region)
    zone_id            = mongodbatlas_advanced_cluster.this.replication_specs[0].zone_id
    should_copy_oplogs = true
  }
}
