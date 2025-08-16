
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

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"      = "1"
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

module "eks" {
  source = "./modules/eks"
  providers = {
    aws = aws.virginia
  }

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.27"
  vpc_id          = module.vpc_virginia.vpc_id
  subnet_ids      = module.vpc_virginia.private_subnets


  # Requerido por tu módulo (y por Access Entries como HYBRID_LINUX)
  authentication_mode     = "API_AND_CONFIG_MAP" # o "API"
  endpoint_public_access  = true
  endpoint_private_access = false

  # Node group configuration
  desired_size   = 2
  max_size       = 3
  min_size       = 1
  instance_types = ["t3.small"]
  capacity_type  = "SPOT"
  disk_size      = 20


  # AMI type que tu módulo referencia en aws_eks_node_group
  # (con 1.27 puedes usar "AL2_x86_64" o "AL2023_x86_64_STANDARD")
  ami_type = "AL2_x86_64"

  # (Opcional) si quieres SSH a los nodos del nodegroup:
  # key_name             = "mi-keypair"
  # remote_access_sg_ids = [aws_security_group.algo.id]


  tags = {
    Environment = "production"
  }
}




output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_ca_certificate" {
  value = module.eks.cluster_certificate_authority_data
}
