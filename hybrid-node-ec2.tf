############################################
# hybrid-node-ec2.tf — usa data.aws_eks_cluster.this del archivo eks-hybrid-access.tf
############################################

# Región actual (para user-data)
data "aws_region" "current_virginia" {
  provider = aws.virginia
}

# AMI Amazon Linux 2023 (sin SSM Parameter Store)
data "aws_ami" "al2023_amd64" {
  provider    = aws.virginia
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
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
}

locals {
  # Ordena para selección determinística
  cluster_subnet_ids = sort(tolist(data.aws_eks_cluster.this.vpc_config[0].subnet_ids))

  # 1) var.hybrid_subnet_id si viene
  # 2) primera subnet pública de la VPC del root (si existe)
  # 3) primera subnet del cluster EKS
  hybrid_subnet_id = coalesce(
    var.hybrid_subnet_id,
    try(module.vpc_virginia.public_subnets[0], null),
    local.cluster_subnet_ids[0]
  )

  cluster_vpc_id = data.aws_eks_cluster.this.vpc_config[0].vpc_id
  k8s_version    = data.aws_eks_cluster.this.version

  # Sin data.aws_region.* (evita warning); usa la variable
  aws_region = var.aws_region
}

# SG para el nodo híbrido (ASCII-only)
resource "aws_security_group" "hybrid_node" {
  provider    = aws.virginia
  name        = "${module.eks.cluster_name}-hybrid-node-sg"
  description = "SG for hybrid node (lab)"
  vpc_id      = local.cluster_vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # (Opcional) SSH de laboratorio — en prod usar SSM Session Manager
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# EC2 que simula un nodo híbrido (misma VPC del cluster)
resource "aws_instance" "hybrid_node" {
  provider                    = aws.virginia
  ami                         = data.aws_ami.al2023_amd64.id
  instance_type               = var.hybrid_instance_type
  subnet_id                   = local.hybrid_subnet_id
  vpc_security_group_ids      = [aws_security_group.hybrid_node.id]
  key_name                    = var.hybrid_ssh_key_name
  associate_public_ip_address = false

  user_data_replace_on_change = true
  user_data                   = <<-EOF
    #!/usr/bin/env bash
    set -euxo pipefail
    dnf -y update || true
    dnf -y install curl tar

    # Instalar nodeadm (híbridos EKS)
    curl -fSL -o /usr/local/bin/nodeadm "https://hybrid-assets.eks.amazonaws.com/releases/latest/bin/linux/amd64/nodeadm"
    chmod +x /usr/local/bin/nodeadm

    # Instalar kubelet + containerd + SSM con la versión del cluster
    nodeadm install ${local.k8s_version} --credential-provider ssm

    # NodeConfig con Activation SSM y datos del cluster
    cat >/etc/nodeadm/nodeConfig.yaml <<NCFG
    apiVersion: node.eks.aws/v1alpha1
    kind: NodeConfig
    spec:
      cluster:
        name: ${module.eks.cluster_name}
        region: ${local.aws_region_name}
      hybrid:
        ssm:
          activationCode: ${aws_ssm_activation.hybrid.activation_code}
          activationId: ${aws_ssm_activation.hybrid.id}
    NCFG

    # Registrar el nodo
    nodeadm init -c file:///etc/nodeadm/nodeConfig.yaml
    systemctl enable --now kubelet
  EOF

  tags = merge(var.tags, { Name = "${module.eks.cluster_name}-hybrid-ec2" })

  depends_on = [
    aws_ssm_activation.hybrid,
    aws_security_group.hybrid_node,
    aws_eks_access_entry.hybrid_nodes
  ]
}
