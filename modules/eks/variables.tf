########################################################
# modules/eks/variables.tf — Variables del módulo hijo
########################################################

variable "cluster_name" {
  description = "Nombre del clúster EKS."
  type        = string
}

variable "cluster_version" {
  description = "Versión de Kubernetes del control plane (p.ej., 1.29)."
  type        = string
}

variable "vpc_id" {
  description = "VPC donde vive el clúster."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets (privadas o públicas) para el clúster/nodos."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Acceso público al endpoint del API server."
  type        = bool
}

variable "endpoint_private_access" {
  description = "Acceso privado al endpoint del API server."
  type        = bool
}

variable "desired_size" {
  description = "Tamaño deseado del node group."
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Tamaño mínimo del node group."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Tamaño máximo del node group."
  type        = number
  default     = 2
}

variable "instance_types" {
  description = "Tipos de instancia para el node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "capacity_type" {
  description = "Tipo de capacidad del node group."
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type debe ser ON_DEMAND o SPOT."
  }
}

variable "disk_size" {
  description = "Tamaño del disco (GiB) para los nodos."
  type        = number
  default     = 20
}

variable "managed_node_ami_id" {
  description = "AMI ID para el node group (si quieres forzar una AMI concreta)."
  type        = string
  default     = null
}

variable "remote_node_cidr" {
  description = "CIDR de los nodos remotos (hybrid)."
  type        = string
  default     = null
}

variable "remote_pod_cidr" {
  description = "CIDR de los pods remotos (hybrid)."
  type        = string
  default     = null
}

variable "cluster_admin_principal_arn" {
  description = "ARN del principal IAM para admin del cluster (CAM)."
  type        = string
  default     = null
}

variable "authentication_mode" {
  description = "Modo de autenticación (API, CONFIG_MAP, API_AND_CONFIG_MAP)."
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "tags" {
  description = "Etiquetas comunes para todos los recursos."
  type        = map(string)
  default     = {}
}
