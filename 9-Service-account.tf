# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account
resource "google_service_account" "service-a" {
  account_id = "service-a"

  lifecycle {
    create_before_destroy = true
  }
}
# GCP Service Account for node pool
resource "google_service_account" "service_a" {
  account_id   = "service-a"
  display_name = "Service Account for GKE Nodes"
}

# IAM roles required by GKE nodes
resource "google_project_iam_member" "service_a_logging" {
  project = "cb-pipeline-demo"
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.service_a.email}"
}

resource "google_project_iam_member" "service_a_monitoring" {
  project = "cb-pipeline-demo"
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.service_a.email}"
}

resource "google_project_iam_member" "service_a_monitoring_viewer" {
  project = "cb-pipeline-demo"
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.service_a.email}"
}

# Optional, if pulling images from Artifact Registry
resource "google_project_iam_member" "service_a_artifactregistry" {
  project = "cb-pipeline-demo"
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.service_a.email}"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam
resource "google_project_iam_member" "service-a" {
  project = "cb-pipeline-demo"
  role    = "roles/storage.admin"
  member             = "serviceAccount:cb-pipeline-demo.svc.id.goog[staging/service-a]"
 #member  = "serviceAccount:${google_service_account.service-a.email}"

  lifecycle {
    create_before_destroy = true
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_iam
resource "google_service_account_iam_member" "service-a" {
  service_account_id = google_service_account.service-a.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:cb-pipeline-demo.svc.id.goog[staging/service-a]"

  lifecycle {
    create_before_destroy = true
  }
}
