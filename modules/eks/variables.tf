# modules/eks/variables.tf
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.24"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cluster"
  type        = list(string)
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "instance_types" {
  description = "List of EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "ami_type" {
  description = "AMI type for worker nodes"
  type        = string
  default     = "AL2_x86_64"
}

variable "capacity_type" {
  description = "Capacity type for nodes (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "disk_size" {
  description = "Disk size for worker nodes"
  type        = number
  default     = 20
}

variable "key_name" {
  description = "SSH key name for worker nodes"
  type        = string
  default     = null
}

variable "remote_access_sg_ids" {
  description = "List of security group IDs for remote access"
  type        = list(string)
  default     = []
}

variable "endpoint_private_access" {
  description = "Enable private access to the Kubernetes API server"
  type        = bool
  default     = false
}

variable "endpoint_public_access" {
  description = "Enable public access to the Kubernetes API server"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}