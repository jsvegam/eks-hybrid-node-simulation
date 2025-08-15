variable "eks_cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "hybrid_registration_limit" {
  description = "How many hosts can register with this activation."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Common tags to apply to created resources."
  type        = map(string)
}

variable "aws_region" {
  description = "AWS region where resources will be created (e.g., us-east-1)."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version (e.g., 1.29)."
  type        = string
}

variable "hybrid_instance_type" {
  description = "Instance type for the EC2 that simulates the hybrid node."
  type        = string
  default     = "t3.small"
}

variable "hybrid_ssh_key_name" {
  description = "EC2 Key Pair name for SSH access to the hybrid node (optional)."
  type        = string
  default     = null
}


# --- Requeridas por tu main.tf (líneas 84–88) ---
variable "remote_node_cidr" {
  description = "CIDR de los nodos remotos (hybrid)."
  type        = string
  # Ajusta si quieres; así no te bloquea el plan.
  default     = "10.99.1.0/24"
}

variable "remote_pod_cidr" {
  description = "CIDR de los pods remotos (hybrid)."
  type        = string
  default     = "10.200.0.0/16"
}

variable "cluster_admin_principal_arn" {
  description = "ARN del principal IAM que será admin del clúster (CAM)."
  type        = string
}
