#
# Variables fulfilled by SLM
#

variable "slm_resource_project_id" {
  type = "string"
}

variable "slm_location_id" {
  type = "string"
}

variable "slm_instance_id" {
  type = "string"
}

#
# Variables fulfilled from REQUEST
#

variable "request_zone" {
  type = "string"
}

variable "request_cluster_name" {
  description = "Name of the K8s cluster"
}

variable "request_organisation" {
  description = "Organisation name for the cluster"
}

variable "request_cloud_provider" {
  description = "The cloud provider, currently only GKE is supported"
}

variable "request_min_node_count" {
  description = "Min Number of worker VMs to create"
  default = 3
}

variable "request_max_node_count" {
  description = "Max Number of worker VMs to create"
  default = 5
}

variable "request_node_machine_type" {
  description = "GCE machine type"
  default = "n1-standard-2"
}

variable "request_node_preemptible" {
  description = "Use preemptible nodes"
  default = "false"
}

variable "request_node_disk_size" {
  description = "Node disk size in GB"
  default = "100"
}

variable "request_node_devstorage_role" {
  description = "The devstorage oauth role to add to the node pool"
  default = "https://www.googleapis.com/auth/devstorage.read_only"
}

variable "request_enable_kubernetes_alpha" {
  default ="false"
} 

variable "request_enable_legacy_abac" {
  default ="true"
} 

variable "request_auto_repair" {
  default ="false"
} 

variable "request_auto_upgrade" {
  default = "false"
} 

variable "request_created_by" {
  description = "The user that created the cluster"
  default = "Unknown"
}

variable "request_created_timestamp" {
  description = "The timestamp this cluster was created"
  default = "Unknown"
}

variable "request_monitoring_service" {
  description = "The monitoring service to use. Can be monitoring.googleapis.com, monitoring.googleapis.com/kubernetes (beta) and none"
  default = "monitoring.googleapis.com"
}

variable "request_logging_service" {
  description = "The logging service to use. Can be logging.googleapis.com, logging.googleapis.com/kubernetes (beta) and none"
  default = "logging.googleapis.com"
}

variable "request_enable_kaniko" {
  description = "Enable Kaniko for building container images"
  default = "0"
}

variable "request_enable_vault" {
  description = "Enable vault for storing secrets"
  default = "0"
}
