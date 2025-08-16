variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes minor version for the EKS cluster (e.g., 1.27)."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the cluster."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for control plane / node group."
}

variable "desired_size" {
  type        = number
  description = "Node group desired size."
  default     = 1
}

variable "min_size" {
  type        = number
  description = "Node group min size."
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Node group max size."
  default     = 2
}

variable "instance_types" {
  type        = list(string)
  description = "EC2 instance types for the node group."
  default     = ["t3.small"]
}

variable "capacity_type" {
  type        = string
  description = "ON_DEMAND or SPOT."
  default     = "ON_DEMAND"
}

variable "disk_size" {
  type        = number
  description = "Node root EBS size (GiB)."
  default     = 20
}

variable "ami_type" {
  type        = string
  description = "EKS node group AMI type."
  default     = "AL2023_x86_64_STANDARD"
}

variable "key_name" {
  type        = string
  description = "Optional EC2 KeyPair name for SSH to nodes."
  default     = null
}

variable "remote_access_sg_ids" {
  type        = list(string)
  description = "Optional SGs allowed to SSH to nodes when remote access is enabled."
  default     = []
}

variable "endpoint_private_access" {
  type        = bool
  description = "Whether the cluster endpoint is private."
  default     = false
}

variable "endpoint_public_access" {
  type        = bool
  description = "Whether the cluster endpoint is public."
  default     = true
}

variable "enable_bootstrap_admin" {
  type        = bool
  description = "Bootstrap the cluster creator with admin permissions."
  default     = true
}

variable "current_console_principal_arn" {
  type        = string
  description = "IAM principal to grant cluster-admin via AccessEntry. If null, use caller identity."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Common tags."
  default     = {}
}
