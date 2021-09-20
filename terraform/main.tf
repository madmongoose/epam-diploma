#-------------------------------------------------
# Terraform
#
# Create:
# - Security Groups for Web Server, RDS and EFS
# - Network, IGW and Routes
# - Application Load Balancer in 2 Availability Zones
# - Instances and EFS storage
# - RDS
#
#-------------------------------------------------

provider "aws" {
    region = "eu-west-2"
}

data "aws_availability_zones" "available" {}

data "aws_ami" "latest-amazon2" {
    owners      = ["amazon"]
    most_recent = true
    filter {
      name      = "name"
      values    = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

#-------------------------------------------------
#
# Security
#
#-------------------------------------------------

resource "tls_private_key" "dev_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.generated_key_name
  public_key = tls_private_key.dev_key.public_key_openssh

  provisioner "local-exec" {      # Key *.pem will be create in current directory
    command = "echo '${tls_private_key.dev_key.private_key_pem}' > ./'${var.generated_key_name}'.pem"
  }

  provisioner "local-exec" {
    command = "chmod 400 ./'${var.generated_key_name}'.pem"
  }
}

resource "aws_vpc" "epm-vpc-main" {
  cidr_block            = "10.10.0.0/16"
  instance_tenancy      = "default"
  enable_dns_hostnames  = true
}

resource "aws_security_group" "epm-sg-web" {
  name = "epm-sg-web"
  description    = "Allow web traffic"
  vpc_id  = aws_vpc.epm-vpc-main.id

  dynamic "ingress" {
      for_each = ["22","80","443","8080"]
    content {
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
  }
} 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = merge(var.common-tags, {Name = "${var.common-tags["Environment"]} Dynamic Security Group"})
}
resource "aws_security_group" "epm-sg-db" {
  name = "epm-sg-db"
  description = "Allow SQL traffic"
  vpc_id = aws_vpc.epm-vpc-main.id
}

resource "aws_security_group_rule" "epm-sg-db-in-web" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.epm-sg-web.id
  security_group_id        = aws_security_group.epm-sg-db.id
}

resource "aws_security_group_rule" "epm-sg-db-in-eks" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.epm-sg-eks-cluster.id
  security_group_id        = aws_security_group.epm-sg-db.id
}

resource "aws_security_group_rule" "epm-sg-db-out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.epm-sg-db.id
}

resource "aws_security_group" "epm-sg-eks-cluster" {
  name = "epm-sg-eks-cluster"
  description    = "Allow EKS traffic"
  vpc_id  = aws_vpc.epm-vpc-main.id

  dynamic "ingress" {
      for_each = ["22","80","443","8080"]
    content {
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
  }
} 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = merge(var.common-tags, {Name = "${var.common-tags["Environment"]} Dynamic Security Group"})
}
#-------------------------------------------------
#
# Network and Routing
#
#-------------------------------------------------

resource "aws_internet_gateway" "epm-igw" {
  vpc_id = aws_vpc.epm-vpc-main.id
}

resource "aws_subnet" "epm-pub-net-1" {
  vpc_id                  = aws_vpc.epm-vpc-main.id
  cidr_block              = "10.10.10.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "epm-pub-net-2" {
  vpc_id                  = aws_vpc.epm-vpc-main.id
  cidr_block              = "10.10.20.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
}

resource "aws_route_table" "epm-rt-pub" {
  vpc_id = aws_vpc.epm-vpc-main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.epm-igw.id
  }
}

resource "aws_route_table_association" "epm-rta-1" {
  subnet_id      = aws_subnet.epm-pub-net-1.id
  route_table_id = aws_route_table.epm-rt-pub.id
}

resource "aws_route_table_association" "epm-rta-2" {
  subnet_id      = aws_subnet.epm-pub-net-2.id
  route_table_id = aws_route_table.epm-rt-pub.id
}

#-------------------------------------------------
#
# Instance and storage
#
#-------------------------------------------------

resource "aws_instance" "epm-control" {
  ami                     = data.aws_ami.latest-amazon2.id
  instance_type           = "t3.small"
  subnet_id               = aws_subnet.epm-pub-net-1.id
  vpc_security_group_ids  = [aws_security_group.epm-sg-web.id]
  key_name                = aws_key_pair.generated_key.key_name
  
tags        = merge(var.common-tags, {Name = "${var.common-tags["Environment"]} Control Server"})
}

resource "aws_instance" "epm-jenkins" {
  ami                     = data.aws_ami.latest-amazon2.id
  instance_type           = "t3.small"
  subnet_id               = aws_subnet.epm-pub-net-1.id
  vpc_security_group_ids  = [aws_security_group.epm-sg-web.id]
  key_name                = aws_key_pair.generated_key.key_name
  user_data = <<EOF
#!/bin/bash
sudo amazon-linux-extras install epel
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum -y install epel-release # repository that provides 'daemonize'
sudo amazon-linux-extras install java-openjdk11 -y
sudo yum -y install jenkins
sudo systemctl daemon-reload
sudo systemctl start jenkins
sudo systemctl status jenkins
EOF
tags        = merge(var.common-tags, {Name = "${var.common-tags["Environment"]} Jenkins"})
}

#-------------------------------------------------
#
# RDS Cluster
#
#-------------------------------------------------

resource "aws_ssm_parameter" "epm-rds-host" {
  name  = "epm-rds-host"
  type  = "String"
  value = aws_rds_cluster.epm-rds-cluster.endpoint
}

resource "random_string" "epm-rds-pass" {
  length           = 10
  special          = true
  override_special = "!#&"

  /*keepers = {
    kepeer1 = var.name # Uncoment for change db password
  }*/
}

resource "aws_ssm_parameter" "epm-rds-pass" {
  name        = "epm-rds-pass"
  description = "Admin password for MySQL"
  type        = "SecureString"
  value       = random_string.epm-rds-pass.result
}

data "aws_ssm_parameter" "get-epm-rds-pass" {
  name       = "epm-rds-pass"
  depends_on = [aws_ssm_parameter.epm-rds-pass]
}

resource "aws_rds_cluster" "epm-rds-cluster" {

    cluster_identifier_prefix     = "epm-rds-cluster-"
    engine                        = "aurora-mysql"
    database_name                 = "cbr"
    master_username               = "cbr"
    master_password               = data.aws_ssm_parameter.get-epm-rds-pass.value
    port                          = "3306"
    backup_retention_period       = 14
    db_subnet_group_name          = aws_db_subnet_group.epm-rds-sng.name
    vpc_security_group_ids        = [aws_security_group.epm-sg-db.id]
    skip_final_snapshot           = true
    apply_immediately             = true
    
    tags = merge(var.common-tags, {Name = "${var.common-tags["Environment"]} MySQL Cluster"})
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_rds_cluster_instance" "epm-rds-instances" {

    count                 = 2
    identifier            = "epm-rds-cluster${count.index}"
    cluster_identifier    = aws_rds_cluster.epm-rds-cluster.id
    instance_class        = "db.t3.small"
    db_subnet_group_name  = aws_db_subnet_group.epm-rds-sng.name
    publicly_accessible   = true
    engine                = "aurora-mysql"

    lifecycle {
        create_before_destroy = true
    }

}
resource "aws_db_subnet_group" "epm-rds-sng" {
    name          = "epm-rds-sng"
    description   = "Allowed subnets for Aurora DB cluster instances"
    subnet_ids    = [aws_subnet.epm-pub-net-1.id, aws_subnet.epm-pub-net-2.id]
}

#-------------------------------------------------
#
# Kubernetes Cluster
#
#-------------------------------------------------

resource "aws_iam_role" "epm-eks-cluster" {
  name = "epm-eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.epm-eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.epm-eks-cluster.name
}

resource "aws_eks_cluster" "epm-eks-cluster" {
  name     = "epm-eks-cluster"
  role_arn = aws_iam_role.epm-eks-cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.epm-sg-eks-cluster.id]
    subnet_ids         = [aws_subnet.epm-pub-net-1.id, aws_subnet.epm-pub-net-2.id]
  }

  tags = {
    Name = "epm-eks-cluster"
  }
}

resource "aws_iam_role" "epm-eks-nodes" {
  name = "epm-eks-nodes"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.epm-eks-nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.epm-eks-nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.epm-eks-nodes.name
}

resource "aws_eks_node_group" "epm-eks-nodes" {
  cluster_name    = aws_eks_cluster.epm-eks-cluster.name
  node_group_name = "epm-eks-nodes"
  instance_types = ["t3.small"]
  node_role_arn   = aws_iam_role.epm-eks-nodes.arn
  subnet_ids    = [aws_subnet.epm-pub-net-1.id, aws_subnet.epm-pub-net-2.id]

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}