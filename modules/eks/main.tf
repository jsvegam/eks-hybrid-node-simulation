########################################################
# modules/eks/main.tf — Wrapper del módulo oficial EKS
########################################################

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  # Identidad y versión (mapeo desde variables del hijo)
  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  # Red
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Autenticación (CAM)
  authentication_mode = var.authentication_mode

  # Endpoint (al menos uno true)
  endpoint_public_access  = var.endpoint_public_access
  endpoint_private_access = var.endpoint_private_access

  # (Opcional) Redes híbridas: se pasan vacías si no hay CIDRs
  remote_network_config = {
    remote_node_networks = { cidrs = var.remote_node_cidr == null ? [] : [var.remote_node_cidr] }
    remote_pod_networks  = { cidrs = var.remote_pod_cidr == null ? [] : [var.remote_pod_cidr] }
  }

  # Access Entry admin por CAM (solo si se pasa un ARN)
  access_entries = var.cluster_admin_principal_arn == null ? {} : {
    admin = {
      principal_arn = var.cluster_admin_principal_arn
      type          = "STANDARD"
      access_policy_associations = {
        cluster_admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  # Managed Node Group (con bootstrap forzado)
  eks_managed_node_groups = {
    default = {
      desired_size   = var.desired_size
      min_size       = var.min_size
      max_size       = var.max_size
      instance_types = var.instance_types
      capacity_type  = var.capacity_type
      disk_size      = var.disk_size

      ami_type = "AL2023_x86_64_STANDARD"
      ami_id   = var.managed_node_ami_id # si es null, el módulo usará SSM

      enable_bootstrap_user_data = true
      bootstrap_extra_args       = ""

      iam_role_additional_policies = {
        eks_worker = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        eks_cni    = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        ecr_ro     = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    }
  }

  tags = var.tags
}
