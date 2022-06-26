resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster01.name
  node_group_name = "eksmanaged-ng"
  node_role_arn   =  aws_iam_role.eks-managed-node_role.arn
  capacity_type   = "SPOT"
  instance_types  = ["t3.micro"]
  subnet_ids = [module.vpc.private_subnet1,module.vpc.private_subnet2]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonManaged-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonManaged-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonManaged-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role_policy_attachment" "AmazonManaged-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-managed-node_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonManaged-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-managed-node_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonManaged-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-managed-node_role.name
}
