resource "google_compute_network" "network" {
  count                   = var.deploy ? 1 : 0
  name                    = "gitops-infra-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  count         = var.deploy ? 1 : 0
  name          = "gitops-infra-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.network[0].id
}

resource "google_compute_firewall" "allow_ssh" {
  count   = var.deploy ? 1 : 0
  name    = "gitops-infra-allow-ssh"
  network = google_compute_network.network[0].name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gitops-infra"]
}