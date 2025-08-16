variable "aws_region" {
  type        = string
  description = "AWS region where the cluster and the hybrid node live."
  default     = "us-east-1"
}

variable "ssh_allowed_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH into the hybrid node (lab only)."
  default     = ["0.0.0.0/0"]
}
