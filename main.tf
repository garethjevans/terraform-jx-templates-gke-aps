terraform {
  required_version = ">= 0.12.0"
}

provider "google" {
  version     = ">= 2.8.0"
  project     = "${var.slm_resource_project_id}"
  region      = "${var.slm_location_id}"
  zone        = "${var.request_zone}"
}

resource "google_project_service" "cloudresourcemanager-api" {
  project = "${var.slm_resource_project_id}"
  service = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute-api" {
  project = "${var.slm_resource_project_id}"
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam-api" {
  project = "${var.slm_resource_project_id}"
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild-api" {
  project = "${var.slm_resource_project_id}"
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "containerregistry-api" {
  project = "${var.slm_resource_project_id}"
  service = "containerregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "containeranalysis-api" {
  project = "${var.slm_resource_project_id}"
  service = "containeranalysis.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "cloudkms-api" {
  project = "${var.slm_resource_project_id}"
  service = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

resource "google_container_node_pool" "jx-node-pool" {
  name       = "default-pool"
  zone       = "${var.request_zone}"
  cluster    = "${google_container_cluster.jx-cluster.name}"
  node_count = "${var.request_min_node_count}"

  node_config {
    preemptible  = "${var.request_node_preemptible}"
    machine_type = "${var.request_node_machine_type}"
    disk_size_gb = "${var.request_node_disk_size}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/compute",
      "${var.request_node_devstorage_role}",
      "https://www.googleapis.com/auth/service.management",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  autoscaling {
    min_node_count = "${var.request_min_node_count}"
    max_node_count = "${var.request_max_node_count}"
  }

  management {
    auto_repair  = "${var.request_auto_repair}"
    auto_upgrade = "${var.request_auto_upgrade}"
  }

}

resource "google_container_cluster" "jx-cluster" {
  name                     = "${var.request_cluster_name}"
  description              = "jx k8s cluster"
  zone                     = "${var.request_zone}"
  enable_kubernetes_alpha  = "${var.request_enable_kubernetes_alpha}"
  enable_legacy_abac       = "${var.request_enable_legacy_abac}"
  initial_node_count       = "${var.request_min_node_count}"
  remove_default_node_pool = "true"
  logging_service          = "${var.request_logging_service}"
  monitoring_service       = "${var.request_monitoring_service}"

  resource_labels = {
    created-by = "${var.request_created_by}"
    created-timestamp = "${var.request_created_timestamp}"
    created-with = "terraform"
  }

  lifecycle {
    ignore_changes = ["node_pool"]
  }
}

resource "google_storage_bucket" "lts-bucket" {
  name     = "${var.request_cluster_name}-lts"
  location = "EU"
}

resource "google_service_account" "kaniko-sa" {
  count        = var.enable_kaniko
  account_id   = "${var.request_cluster_name}-ko"
  display_name = "Kaniko service account for ${var.request_cluster_name}"
}

resource "google_service_account_key" "kaniko-sa-key" {
  count              = var.enable_kaniko
  service_account_id = "${google_service_account.kaniko-sa[0].name}"
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_project_iam_member" "kaniko-sa-storage-admin-binding" {
  count  = var.enable_kaniko
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.kaniko-sa[0].email}"
}

resource "google_project_iam_member" "kaniko-sa-storage-object-admin-binding" {
  count  = var.enable_kaniko
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.kaniko-sa[0].email}"
}

resource "google_project_iam_member" "kaniko-sa-storage-object-creator-binding" {
  count  = var.enable_kaniko
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.kaniko-sa[0].email}"
}

resource "google_storage_bucket" "vault-bucket" {
  count    = var.enable_vault
  name     = "${var.request_cluster_name}-vault"
  location = "EU"
}

resource "google_service_account" "vault-sa" {
  count        = var.enable_vault
  account_id   = "${var.request_cluster_name}-vt"
  display_name = "Vault service account for ${var.cluster_name}"
}

resource "google_service_account_key" "vault-sa-key" {
  count              = var.enable_vault
  service_account_id = "${google_service_account.vault-sa[0].name}"
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_project_iam_member" "vault-sa-storage-object-admin-binding" {
  count  = var.enable_vault
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vault-sa[0].email}"
}

resource "google_project_iam_member" "vault-sa-cloudkms-admin-binding" {
  count  = var.enable_vault
  role   = "roles/cloudkms.admin"
  member = "serviceAccount:${google_service_account.vault-sa[0].email}"
}

resource "google_project_iam_member" "vault-sa-cloudkms-crypto-binding" {
  count  = var.enable_vault
  role   = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member = "serviceAccount:${google_service_account.vault-sa[0].email}"
}

resource "google_kms_key_ring" "vault-keyring" {
  count    = var.enable_vault
  name     = "${var.request_cluster_name}-keyring"
  location = "${var.slm_location_id}"
}

resource "google_kms_crypto_key" "vault-crypto-key" {
  count           = var.enable_vault
  name            = "${var.request_cluster_name}-crypto-key"
  key_ring        = "${google_kms_key_ring.vault-keyring[0].self_link}"
  rotation_period = "100000s"

  lifecycle {
    prevent_destroy = true
  }
}

provider "kubernetes" {
  host = "https://${google_container_cluster.jx-cluster.endpoint}"
  username = "${google_container_cluster.jx-cluster.master_auth.0.username}"
  password = "${google_container_cluster.jx-cluster.master_auth.0.password}"
  client_certificate = "${base64decode(google_container_cluster.jx-cluster.master_auth.0.client_certificate)}"
  client_key = "${base64decode(google_container_cluster.jx-cluster.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.jx-cluster.master_auth.0.cluster_ca_certificate)}"
}

resource "kubernetes_namespace" "jx-namespace" {
  metadata {
    name = "jx"
  }
}

resource "kubernetes_secret" "kaniko-secret" {
  count = var.enable_kaniko
  metadata {
    name      = "kaniko-secret"
    namespace = "jx"
  }

  data = {
    "credentials.json" = "${base64decode(google_service_account_key.kaniko-sa-key[0].private_key)}"
  }
}

resource "kubernetes_secret" "vault-secret" {
  count = var.enable_vault
  metadata {
    name      = "vault-secret"
    namespace = "jx"
  }
  data = {
    "credentials.json" = "${base64decode(google_service_account_key.vault-sa-key[0].private_key)}"
  }
}
