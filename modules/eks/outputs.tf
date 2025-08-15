output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = aws_eks_cluster.cluster.name
}