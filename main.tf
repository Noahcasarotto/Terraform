# main.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"    # Use a recent version of the Google provider
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"    # Kubernetes provider for deploying to cluster
    }
  }
  required_version = ">= 1.0"
}

provider "google" {
  project = "sublime-flux-414616"
  region  = "us-central1"              # or set "zone" if using a specific zone
}

# Kubernetes provider will connect to the GKE cluster (to be created below)
# It uses an OAuth token from the Google provider and cluster info.
data "google_client_config" "default" {}
data "google_container_cluster" "primary" {
  name = "terraform-gke-demo"
  location = "us-central1-a"          # if you used a zone for your cluster
  # If you used a regional cluster, use region instead of zone in location.
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.primary.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "terraform-gke-demo"
  location = "us-central1-a"    # zone for a zonal cluster; use a region for regional cluster
  initial_node_count = 2        # start with 2 nodes in the default node pool

  # (Optional) Specify node machine type or other settings as needed.
  # By default, GKE will choose a default machine type (e.g., e2-medium) if not specified.

  # Enable basic API authentication and endpoint access (defaults are usually fine for demo)
  remove_default_node_pool = false    # using the default node pool with initial_node_count
  # master_auth {} is not specified to use default (which disables basic auth in newer GKE versions).
}
# (Optional) Outputs
output "cluster_name" {
  value = google_container_cluster.primary.name
}
output "cluster_region" {
  value = google_container_cluster.primary.location
}

# Kubernetes Deployment to run the web app on the cluster
resource "kubernetes_deployment" "web_app" {
  metadata {
    name = "hello-web-app"
    labels = {
      app = "hello-web-app"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "hello-web-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "hello-web-app"
        }
      }
      spec {
        container {                    # define the single container in this Pod
          name  = "hello-web-app"
          image = "gcr.io/sublime-flux-414616/hello-gke:v1"
          # The container image that we built and pushed earlier.
          port {
            container_port = 8080      # the app listens on 8080 inside the container
          }
        }
      }
    }
  }
}

# Kubernetes Service to expose the Deployment
resource "kubernetes_service" "web_service" {
  metadata {
    name = "hello-web-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment.web_app.metadata[0].labels["app"]
    }
    type = "LoadBalancer"   # to get an external IP
    port {
      port        = 80      # expose on port 80 externally
      target_port = 8080    # target the container’s port 8080
    }
  }
  wait_for_load_balancer = true  # wait until an IP is allocated
}
