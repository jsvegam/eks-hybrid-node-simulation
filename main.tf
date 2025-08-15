
module "vpc_virginia" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
  providers = {
    aws = aws.virginia
  }

  name = "vpc-virginia"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  enable_dns_hostnames   = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

# module "eks" {
#   source = "./modules/eks"
#   providers = {
#     aws = aws.virginia
#   }

#   cluster_name    = "my-eks-cluster"
#   cluster_version = "1.27"
#   vpc_id          = module.vpc_virginia.vpc_id
#   subnet_ids      = module.vpc_virginia.private_subnets

#   # Node group configuration
#   desired_size    = 2
#   max_size        = 3
#   min_size        = 1
#   instance_types  = ["t3.small"]
#   capacity_type   = "SPOT"
#   disk_size       = 20

#   tags = {
#     Environment = "production"
#   }
# }


module "eks" {
  source    = "./modules/eks"
  providers = { aws = aws.virginia }

  # Identidad del clúster (coincide con lo que pide el módulo hijo)
  cluster_name       = var.eks_cluster_name
  kubernetes_version = var.kubernetes_version

  # Red
  vpc_id     = module.vpc_virginia.vpc_id
  subnet_ids = module.vpc_virginia.private_subnets  # privadas (con NAT)

  # Requeridos por el hijo
  authentication_mode             = "API_AND_CONFIG_MAP"
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  # Node group (ajusta a gusto)
  desired_size   = 1
  min_size       = 1
  max_size       = 2
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.small", "t3a.small", "t3.medium", "t3a.medium", "t2.small"]
  disk_size      = 20

  # AMI explícita (si usas el data source en root)
  managed_node_ami_id = data.aws_ami.eks_al2023_129.id

  # (Opcional) Híbrido — el hijo debe declararlas si las usa
  remote_node_cidr = var.remote_node_cidr
  remote_pod_cidr  = var.remote_pod_cidr

  # Admin del cluster vía CAM (si el hijo lo usa)
  cluster_admin_principal_arn = var.cluster_admin_principal_arn

  tags = {
    Environment = "production"
  }
}



# AMI EKS Optimized AL2023 para K8s 1.29 (cuenta oficial de EKS)
data "aws_ami" "eks_al2023_129" {
  provider    = aws.virginia
  most_recent = true
  owners      = ["602401143452"] # EKS official

  filter {
    name   = "name"
    values = [
      "amazon-eks-node-al2023-x86_64-standard-1.29-*",
      "amazon-eks-1.29-al2023-x86_64-*",
    ]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}





output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_ca_certificate" {
  value = module.eks.cluster_certificate_authority_data
}
