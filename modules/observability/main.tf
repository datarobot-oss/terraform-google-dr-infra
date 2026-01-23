locals {
  name = "${var.name}-observability"

  ksa_names = [
    "observability-v2-otel-deployment",
    "observability-v2-otel-daemonset",
    "observability-v2-otel-statsd",
    "observability-v2-otel-scraper",
    "observability-v2-otel-scraper-static",
  ]
}

resource "google_service_account" "observability_service_account" {
  account_id   = "${local.name}-service-account"
  display_name = "Service Account for Observability"
}

resource "google_project_iam_member" "observability_logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.observability_service_account.email}"
}

resource "google_project_iam_member" "observability_monitoring_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.observability_service_account.email}"
}

resource "google_project_iam_member" "observability_cloud_trace_agent" {
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.observability_service_account.email}"
}

resource "google_service_account_iam_member" "observability_wi_binding" {
  for_each = toset(local.ksa_names)

  service_account_id = google_service_account.observability_service_account.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${each.value}]"
}
