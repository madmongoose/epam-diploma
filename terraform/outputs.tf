output "epm-control-dns-name" {
  value = aws_instance.epm-control.public_dns
}

output "epm-jenkins-dns-name" {
  value = aws_instance.epm-jenkins.public_dns
}

output "rds-cluster-endpoints" {
    value = aws_rds_cluster.epm-rds-cluster.endpoint
}
/*output "db-instance-endpoint" {
  value = module.db.db_instance_endpoint
}

/*output "rds_addresses-1" {
    value = aws_rds_cluster_instance.epm-rds-instances[count.index]
}

output "rds_addresses-2" {
    value = aws_rds_cluster_instance.epm-rds-instances[count.index]
}

output "epm-eks-cluster-endpoint" {
  value = aws_eks_cluster.epm-eks-cluster.endpoint
}

output "epm-eks-cluster-certificate-authority" {
  value = aws_eks_cluster.epm-eks-cluster.certificate_authority 
}*/

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.epm-eks-cluster.endpoint
}

output "eks_cluster_certificate_authority" {
  value = aws_eks_cluster.epm-eks-cluster.certificate_authority 
}