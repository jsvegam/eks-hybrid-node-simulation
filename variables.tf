#############################################
# variables.tf — Root
#############################################

variable "eks_cluster_name" {
  description = "Nombre del clúster EKS."
  type        = string
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes (p.ej. 1.29)."
  type        = string
  default     = "1.29"
}

variable "remote_node_cidr" {
  description = "CIDR de nodos remotos (hybrid)."
  type        = string
  default     = null
}

variable "remote_pod_cidr" {
  description = "CIDR de pods remotos (hybrid)."
  type        = string
  default     = null
}

variable "cluster_admin_principal_arn" {
  description = "ARN del principal IAM que será admin (CAM)."
  type        = string
  default     = null
}

variable "authentication_mode" {
  description = "Modo de autenticación de EKS (API, CONFIG_MAP, API_AND_CONFIG_MAP)."
  type        = string
  default     = "API_AND_CONFIG_MAP"
}
