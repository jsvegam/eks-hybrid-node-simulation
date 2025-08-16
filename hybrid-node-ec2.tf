#########################################
# hybrid-node-ec2.tf — HCL corregido
#########################################

# Reusa el data source ya definido en otro archivo:
# data "aws_eks_cluster" "this" { ... }  <-- NO lo declares de nuevo aquí.

# AMI Amazon Linux 2023 (sin SSM)
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
  # Subnets del cluster (set -> list -> ordenado)
  cluster_subnet_ids = sort(tolist(data.aws_eks_cluster.this.vpc_config[0].subnet_ids))

  # Elige la subnet para la EC2 híbrida:
  # 1) var.hybrid_subnet_id si viene
  # 2) primera subnet pública del módulo VPC (si existe)
  # 3) primera subnet del cluster
  hybrid_subnet_id = coalesce(
    var.hybrid_subnet_id,
    try(module.vpc_virginia.public_subnets[0], null),
    local.cluster_subnet_ids[0]
  )

  cluster_vpc_id = data.aws_eks_cluster.this.vpc_config[0].vpc_id
  k8s_version    = data.aws_eks_cluster.this.version
  aws_region     = var.aws_region
}

# SG para el nodo híbrido (ASCII-only)
resource "aws_security_group" "hybrid_node" {
  provider    = aws.virginia
  name        = "${data.aws_eks_cluster.this.name}-hybrid-node-sg"
  description = "SG for hybrid node (lab)"
  vpc_id      = local.cluster_vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH opcional (laboratorio). En prod, usa Session Manager.
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# EC2 que actuará como nodo híbrido
resource "aws_instance" "hybrid_node" {
  provider                    = aws.virginia
  ami                         = data.aws_ami.al2023_amd64.id
  instance_type               = var.hybrid_instance_type
  subnet_id                   = local.hybrid_subnet_id
  vpc_security_group_ids      = [aws_security_group.hybrid_node.id]
  key_name                    = var.hybrid_ssh_key_name
  associate_public_ip_address = true
  user_data_replace_on_change = true

  # Bootstrap con nodeadm usando la Activation SSM creada en eks-hybrid-access.tf
  user_data = <<-EOF
    #!/usr/bin/env bash
    set -euxo pipefail
    dnf -y update || true
    dnf -y install curl tar

    curl -fSL -o /usr/local/bin/nodeadm "https://hybrid-assets.eks.amazonaws.com/releases/latest/bin/linux/amd64/nodeadm"
    chmod +x /usr/local/bin/nodeadm

    nodeadm install ${local.k8s_version} --credential-provider ssm

    cat >/etc/nodeadm/nodeConfig.yaml <<NCFG
    apiVersion: node.eks.aws/v1alpha1
    kind: NodeConfig
    spec:
      cluster:
        name: ${data.aws_eks_cluster.this.name}
        region: ${local.aws_region}
      hybrid:
        ssm:
          activationCode: ${aws_ssm_activation.hybrid.activation_code}
          activationId: ${aws_ssm_activation.hybrid.id}
    NCFG

    nodeadm init -c file:///etc/nodeadm/nodeConfig.yaml
    systemctl enable --now kubelet
  EOF

  tags = merge(var.tags, { Name = "${data.aws_eks_cluster.this.name}-hybrid-ec2" })

  depends_on = [
    aws_security_group.hybrid_node,
    aws_ssm_activation.hybrid
  ]
}
