# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
// 7-Kubernetes.tf
resource "google_container_cluster" "primary" {
  name     = "primary"
  location = "us-central1"

  # Networking
  network    = google_compute_network.main.self_link
  subnetwork = google_compute_subnetwork.private.self_link

  # Regional cluster for HA
  remove_default_node_pool = true
  initial_node_count       = 1

  # Security: disable legacy ABAC and client certificates
  enable_legacy_abac = false
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Private cluster config
  private_cluster_config {
    enable_private_nodes   = true
    master_ipv4_cidr_block = "172.16.0.0/28"
  }

  # Release channel
  release_channel {
    channel = "REGULAR"
  }

  # Workload Identity for secure service account mapping
  workload_identity_config {
    workload_pool = "cb-pipeline-demo.svc.id.goog"
  }

  # Logging & Monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # IP allocation
  ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pod-range"
    services_secondary_range_name = "k8s-service-range"
  }

  # Addons
  addons_config {
    http_load_balancing {
      disabled = true
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  # Labels for tracking
  resource_labels = {
    environment = "staging"
    owner       = "devops"
  }
}


  #   Jenkins use case
  #   master_authorized_networks_config {
  #     cidr_blocks {
  #       cidr_block   = "10.0.0.0/18"
  #       display_name = "private-subnet-w-jenkins"
  #     }
  #   }

