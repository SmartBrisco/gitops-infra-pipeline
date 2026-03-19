resource "google_compute_instance" "vm" {
  count        = var.deploy ? 1 : 0
  name         = "gitops-infra-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["gitops-infra"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet[0].id
    access_config {}
  }

  labels = {
    managed-by  = "terraform"
    environment = "dev"
  }
}