locals {
  raw_short_name = (
    var.endpoint_config.private_dns_name != ""
    ? var.endpoint_config.private_dns_name
    : element(split("/", var.endpoint_config.service_name), length(split("/", var.endpoint_config.service_name)) - 1)
  )

  short_name = lower(replace(local.raw_short_name, "[^a-zA-Z0-9-]", "-"))
}

resource "google_compute_address" "this" {
  name         = "${var.name}-${local.short_name}-ip"
  project      = var.google_project_id
  region       = var.region
  subnetwork   = var.subnet
  address_type = "INTERNAL"
}

resource "google_compute_forwarding_rule" "this" {
  name                    = "${var.name}-${local.short_name}-psc"
  project                 = var.google_project_id
  region                  = var.region
  network                 = var.vpc_name
  ip_address              = google_compute_address.this.id
  target                  = var.endpoint_config.service_name
  load_balancing_scheme   = ""
  allow_psc_global_access = var.allow_psc_global_access
  labels                  = var.labels
}

resource "google_dns_managed_zone" "this" {
  count       = var.endpoint_config.private_dns_zone != "" ? 1 : 0
  name        = replace(var.endpoint_config.private_dns_zone, ".", "-")
  dns_name    = "${var.endpoint_config.private_dns_zone}."
  project     = var.google_project_id
  description = "Private DNS zone for PSC endpoint ${var.endpoint_config.private_dns_name}"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = var.vpc_name
    }
  }

  labels = var.labels
}

resource "google_dns_record_set" "this" {
  count = var.endpoint_config.private_dns_name != "" && var.endpoint_config.private_dns_zone != "" ? 1 : 0

  name = "${var.endpoint_config.private_dns_name}.${var.endpoint_config.private_dns_zone}."
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.this[0].name
  project      = var.google_project_id

  rrdatas = [google_compute_address.this.address]
}
