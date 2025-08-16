##############################################
# eks-hybrid-access.tf
# IAM + SSM Activation + EKS Access Entry (HYBRID)
##############################################

# Trust policy para que SSM asuma el rol de las managed instances (nodeadm)
data "aws_iam_policy_document" "hybrid_nodes_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Rol usado por las instancias híbridas registradas vía SSM (nodeadm --credential-provider ssm)
resource "aws_iam_role" "hybrid_nodes" {
  provider           = aws.virginia
  name               = "eks-hybrid-nodes-role"
  assume_role_policy = data.aws_iam_policy_document.hybrid_nodes_trust.json
  tags               = var.tags
}

# Permisos SSM para que la instancia sea "Managed Instance"
resource "aws_iam_role_policy_attachment" "hybrid_nodes_ssm_core" {
  provider   = aws.virginia
  role       = aws_iam_role.hybrid_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Activación SSM: entrega activationCode/activationId que usará nodeadm
resource "aws_ssm_activation" "hybrid" {
  provider           = aws.virginia
  name               = "eks-hybrid-activation"
  description        = "Hybrid activation for EKS hybrid node(s)"
  iam_role           = aws_iam_role.hybrid_nodes.name
  registration_limit = var.hybrid_registration_limit
  tags               = var.tags
}

# Leemos el cluster EKS (asegura orden con depends_on)
data "aws_eks_cluster" "this" {
  provider   = aws.virginia
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

# Access Entry HYBRID_LINUX: autoriza al rol a registrar nodos híbridos en el cluster
resource "aws_eks_access_entry" "hybrid_nodes" {
  provider      = aws.virginia
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.hybrid_nodes.arn
  type          = "HYBRID_LINUX"
  depends_on    = [aws_iam_role.hybrid_nodes]
}
