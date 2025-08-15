##############################
# eks-hybrid-access.tf
##############################

# Trust policy: allow SSM to assume this role for Hybrid Activations
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

# Role used by your hybrid nodes (via SSM Hybrid Activations)
resource "aws_iam_role" "hybrid_nodes" {
  name               = "${var.eks_cluster_name}-hybrid-nodes"
  assume_role_policy = data.aws_iam_policy_document.hybrid_nodes_trust.json
  tags               = var.tags
}

# Minimum permissions so SSM can manage the host
resource "aws_iam_role_policy_attachment" "hybrid_ssm_core" {
  role       = aws_iam_role.hybrid_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create the SSM activation (you’ll get activation_code and id)
resource "aws_ssm_activation" "hybrid" {
  name               = "${var.eks_cluster_name}-hybrid-activation"
  description        = "Hybrid activation for EKS hybrid nodes"
  iam_role           = aws_iam_role.hybrid_nodes.name
  registration_limit = var.hybrid_registration_limit
  tags               = var.tags
}

# Allow the hybrid nodes role to join the cluster (HYBRID_LINUX)
resource "aws_eks_access_entry" "hybrid_nodes" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.hybrid_nodes.arn
  type          = "HYBRID_LINUX"
  depends_on    = [module.eks]
}

# Useful outputs (copy these for nodeadm on your host)
output "hybrid_activation_code" {
  value       = aws_ssm_activation.hybrid.activation_code
  description = "SSM activation code for nodeadm"
  sensitive   = true
}

output "hybrid_activation_id" {
  value       = aws_ssm_activation.hybrid.id
  description = "SSM activation id for nodeadm"
  sensitive   = true
}
