module "vpc" {
  source = "./module/vpc"
  cidrs = var.cidrs
}
  
resource "aws_iam_role" "eks-cluster-role" {
  name = "eks-cluster-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonManaged-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonManaged-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role" "eks-managed-node_role" {
  name = "eks-managed-node_role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}
  
resource "aws_cloudwatch_log_group" "cluster_log" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}

  
resource "aws_eks_cluster" "cluster01" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks-cluster-role.arn

  vpc_config {
    subnet_ids = [module.vpc.public_subnet1,module.vpc.public_subnet2]
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonManaged-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonManaged-AmazonEKSVPCResourceController,
  ]
}
   

    
output "endpoint" {
  value = aws_eks_cluster.cluster01.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.cluster01.certificate_authority[0].data
}
