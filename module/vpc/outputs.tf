output "vpc_id" {
  value = aws_vpc.eks_vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.eks_vpc.cidr_block
}

output "public_subnet1" {
  value = aws_subnet.eks_public1_subnet.id
}

output "public_subnet2" {
  value = aws_subnet.eks_public2_subnet.id
}

output "private_subnet1" {
  value = aws_subnet.eks_private1_subnet.id
}

output "private_subnet2" {
  value = aws_subnet.eks_private2_subnet.id
}
