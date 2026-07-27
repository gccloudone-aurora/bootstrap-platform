resource "google_compute_network" "this" {
  name                    = local.name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name          = local.name
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.this.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/20"
  }
}

resource "google_service_account" "argocd_repo_server" {
  account_id   = "argocd-repo-server"
  display_name = "Argo CD repo-server (AVP / Secret Manager)"
}

resource "google_container_cluster" "this" {
  name     = local.name
  location = var.region

  network    = google_compute_network.this.name
  subnetwork = google_compute_subnetwork.this.name

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  resource_labels = local.labels
}

resource "google_container_node_pool" "system" {
  name     = "system"
  location = var.region
  cluster  = google_container_cluster.this.name

  node_count = 2

  node_config {
    machine_type = "e2-standard-2"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = local.labels
    tags   = ["bootstrap-gcp-example"]
  }
}
