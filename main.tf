#############################################
# main.tf — Root (VPC + módulo EKS hijo)
#############################################

# ---------- VPC Virginia ----------
module "vpc_virginia" {
  source    = "terraform-aws-modules/vpc/aws"
  version   = "5.0.0"
  providers = { aws = aws.virginia }

  name = "vpc-virginia"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

# (Opcional) data source para fijar AMI EKS 1.29 (evita SSM)
# AMI EKS Optimized AL2023 para K8s 1.29 (cuenta oficial de EKS)
data "aws_ami" "eks_al2023_129" {
  provider    = aws.virginia
  most_recent = true
  owners      = ["602401143452"] # EKS official

  filter {
    name = "name"
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

# ---------- Módulo EKS (hijo ./modules/eks) ----------
module "eks" {
  source    = "./modules/eks"
  providers = { aws = aws.virginia }

  
  # NOMBRES que espera el módulo hijo
  cluster_name    = var.eks_cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc_virginia.vpc_id
  subnet_ids = module.vpc_virginia.private_subnets # privadas (con NAT)

  # Requeridos por el hijo (al menos uno true)
  endpoint_public_access  = true
  endpoint_private_access = false

  # Parámetros del Node Group
  desired_size   = 1
  min_size       = 1
  max_size       = 2
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.small", "t3a.small", "t3.medium", "t3a.medium", "t2.small"]
  disk_size      = 20

  # Fijar AMI explícita (usa el data anterior)
  managed_node_ami_id = data.aws_ami.eks_al2023_129.id

  # (Opcional) híbrido — queda inerte si no lo usas en el hijo
  remote_node_cidr = var.remote_node_cidr
  remote_pod_cidr  = var.remote_pod_cidr

  # (Opcional) CAM admin — si el hijo lo usa internamente
  cluster_admin_principal_arn = var.cluster_admin_principal_arn

  # Autenticación CAM (por defecto en el hijo: API_AND_CONFIG_MAP)
  authentication_mode = var.authentication_mode

  tags = {
    Environment = "production"
  }
}
