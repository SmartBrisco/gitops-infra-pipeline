# --- GKE Cluster IAM Service Account ---
resource "google_service_account" "gke" {
  count        = var.deploy ? 1 : 0
  account_id   = "gitops-infra-gke-sa"
  display_name = "GKE Node Service Account"
}

resource "google_project_iam_member" "gke_node" {
  count   = var.deploy ? 1 : 0
  project = var.project_id
  role    = "roles/container.nodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke[0].email}"
}

# --- Private Subnet for GKE ---
resource "google_compute_subnetwork" "gke_subnet" {
  count         = var.deploy ? 1 : 0
  name          = "gitops-infra-gke-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.network[0].id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/20"
  }
}

# --- GKE Cluster ---
resource "google_container_cluster" "main" {
  count    = var.deploy ? 1 : 0
  name     = "gitops-infra-gke"
  location = var.region

  network    = google_compute_network.network[0].id
  subnetwork = google_compute_subnetwork.gke_subnet[0].id

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Dev only — enable private nodes in production
  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
  }
}

# --- GKE Node Pool ---
resource "google_container_node_pool" "main" {
  count    = var.deploy ? 1 : 0
  name     = "gitops-infra-node-pool"
  cluster  = google_container_cluster.main[0].name
  location = var.region

  node_count = 1

  node_config {
    machine_type    = "e2-medium" # Dev only — production minimum e2-standard-2
    service_account = google_service_account.gke[0].email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      managed-by  = "terraform"
      environment = "dev"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}