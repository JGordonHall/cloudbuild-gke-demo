terraform {
  backend "gcs" {
    bucket = "bme-cb-gke"
    prefix = "terraform/state/gke"
  }
}