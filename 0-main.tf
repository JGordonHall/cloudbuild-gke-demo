terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.4.0"
    }
  }
}


provider "google" {
  project ="cb-pipeline-demo"
  region ="us-central1"

  # Configuration options
}
