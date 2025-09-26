resource "google_compute_disk" "grafana_disk" {
  name = "grafana-disk"
  type = "pd-ssd"
  zone = "us-central1-a"
  size = 10
}