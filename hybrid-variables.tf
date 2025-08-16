variable "hybrid_registration_limit" {
  description = "Máximo de hosts a registrar con la Activación SSM."
  type        = number
  default     = 1
}

variable "hybrid_instance_type" {
  description = "Tipo de instancia EC2 para el nodo híbrido (lab)."
  type        = string
  default     = "t3.small"
}

variable "hybrid_ssh_key_name" {
  description = "KeyPair para SSH (opcional, mejor usar SSM Session Manager)."
  type        = string
  default     = null
}

variable "hybrid_subnet_id" {
  description = "Subnet donde lanzar la EC2 del nodo híbrido. Si es null, se usa la primera subnet del cluster."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default = {
    Project = "eks-hybrid-node-simulation"
    Env     = "lab"
  }
}
