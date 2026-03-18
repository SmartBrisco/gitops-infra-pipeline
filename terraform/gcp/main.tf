resource "google_compute_network" "vpc" {
  count                   = var.deploy ? 1 : 0
  name                    = "gitops-infra-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  count         = var.deploy ? 1 : 0
  name          = "gitops-infra-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc[0].id
}

resource "google_compute_firewall" "allow_ssh" {
  count   = var.deploy ? 1 : 0
  name    = "gitops-infra-allow-ssh"
  network = google_compute_network.vpc[0].name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gitops-infra"]
}

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