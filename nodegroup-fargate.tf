resource "aws_eks_fargate_profile" "fargate-ng" {
  cluster_name           = aws_eks_cluster.cluster01.name}
  fargate_profile_name   = "fargate-ng-${aws_eks_cluster.cluster01.name}"
  pod_execution_role_arn = aws_iam_role.fargate-ng-role.arn
  subnet_ids             =  [module.vpc.private_subnet1,module.vpc.private_subnet2]

  selector {
    namespace = "fargateng"
  }
}

resource "aws_iam_role" "fargate-ng-role" {
  name = "fargate-ng-${aws_eks_cluster.cluster01.name}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonManaged-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate-ng-role.name
}

