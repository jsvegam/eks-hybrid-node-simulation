variable "cluster_name" {
  description = "Nombre del clúster EKS (se mapea a 'name' del módulo oficial)."
  type        = string
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes para el control plane (p. ej., 1.29)."
  type        = string
}

variable "vpc_id" {
  description = "VPC donde vive el clúster."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets para el control plane y/o data plane."
  type        = list(string)
}

variable "authentication_mode" {
  description = "Modo de autenticación de EKS (p. ej., API_AND_CONFIG_MAP)."
  type        = string
}

variable "cluster_endpoint_public_access" {
  description = "Habilita acceso público al endpoint del API server."
  type        = bool
}

variable "cluster_endpoint_private_access" {
  description = "Habilita acceso privado al endpoint del API server."
  type        = bool
}

# (Opcional) Config de redes híbridas
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

# Access Entry admin (CAM)
variable "cluster_admin_principal_arn" {
  description = "ARN del principal IAM que tendrá permisos de admin (CAM)."
  type        = string
}

# Parámetros del Managed Node Group
variable "desired_size" {
  description = "Tamaño deseado del node group."
  type        = number
}

variable "min_size" {
  description = "Tamaño mínimo del node group."
  type        = number
}

variable "max_size" {
  description = "Tamaño máximo del node group."
  type        = number
}

variable "instance_types" {
  description = "Tipos de instancia para el node group."
  type        = list(string)
}

variable "capacity_type" {
  description = "Tipo de capacidad del node group (ON_DEMAND o SPOT)."
  type        = string
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type debe ser ON_DEMAND o SPOT."
  }
}

variable "disk_size" {
  description = "Tamaño del disco (GiB) para los nodos."
  type        = number
}

# AMI explícita para el node group (opcional)
variable "managed_node_ami_id" {
  description = "AMI ID para el node group (si no se usa SSM)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Etiquetas comunes."
  type        = map(string)
  default     = {}
}


# Si tu modules/eks/main.tf usa aws_eks_cluster con:
#   version  = var.cluster_version
#   vpc_config { endpoint_private_access = var.endpoint_private_access
#                endpoint_public_access  = var.endpoint_public_access }

variable "cluster_version" {
  description = "Versión de Kubernetes del control plane (p.ej. 1.29)."
  type        = string
}

variable "endpoint_private_access" {
  description = "Acceso privado al endpoint del API server."
  type        = bool
}

variable "endpoint_public_access" {
  description = "Acceso público al endpoint del API server."
  type        = bool
}

