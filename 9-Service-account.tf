# Single GCP Service Account for node pool
resource "google_service_account" "gke_nodes" {
  account_id   = "gke-nodes"
  display_name = "Service Account for GKE Nodes"

  lifecycle {
    create_before_destroy = true
  }
}

# IAM roles required by GKE nodes
resource "google_project_iam_member" "gke_nodes_logging" {
  project = "cb-pipeline-demo"
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring" {
  project = "cb-pipeline-demo"
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  project = "cb-pipeline-demo"
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Optional, if pulling images from Artifact Registry
resource "google_project_iam_member" "gke_nodes_artifactregistry" {
  project = "cb-pipeline-demo"
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Workload Identity binding (KSA → GSA)
resource "google_service_account_iam_member" "gke_nodes_wi_binding" {
  service_account_id = google_service_account.gke_nodes.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:cb-pipeline-demo.svc.id.goog[staging/service-a]"

  lifecycle {
    create_before_destroy = true
  }
}
