#-------VPC------------------
resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "eks_vpc"
  }
}

#Availability zones

data "aws_availability_zones" "available" {
  state = "available"
}

#Internet Gateway

resource "aws_internet_gateway" "eks_internet_gateway" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks_igw"
  }
}

# Route Tables

resource "aws_route_table" "eks_public_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_internet_gateway.id
  }
}

resource "aws_default_route_table" "eks_private_rt" {
  default_route_table_id = aws_vpc.eks_vpc.default_route_table_id

  tags = {
    Name = "eks_private"
  }
}

#Subnets
resource "aws_subnet" "eks_public1_subnet" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.cidrs["public1"]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "eks_public1"
  }
}

resource "aws_subnet" "eks_public2_subnet" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.cidrs["public2"]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Names = "eks_public2"
  }
}

resource "aws_subnet" "eks_private1_subnet" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.cidrs["private1"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "eks_private1"
  }
}

resource "aws_subnet" "eks_private2_subnet" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.cidrs["private2"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "eks_private2"
  }
}



# Subnet Association

resource "aws_route_table_association" "eks_public1_assoc" {
  subnet_id      = aws_subnet.eks_public1_subnet.id
  route_table_id = aws_route_table.eks_public_rt.id
}

resource "aws_route_table_association" "eks_public2_assoc" {
  subnet_id      = aws_subnet.eks_public2_subnet.id
  route_table_id = aws_route_table.eks_public_rt.id
}

#--Security Group--------

resource "aws_security_group" "eks_sg" {
  name        = "eks_sg"
  description = "Used to access to the dev instance"
  vpc_id      = aws_vpc.eks_vpc.id

  #SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Public Secuity Group

resource "aws_security_group" "eks_public_sg" {
  name        = "eks_public_sg"
  description = "Used for the elastic load balancer for public access"
  vpc_id      = aws_vpc.eks_vpc.id

  #HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Creating an Elastic IP for the NAT Gateway!
resource "aws_eip" "Nat-Gateway-EIP" {
  depends_on = [
    aws_route_table_association.eks_public1_assoc,
    aws_route_table_association.eks_public2_assoc
  ]
  vpc = true
}

# Creating a NAT Gateway!
resource "aws_nat_gateway" "NAT_GATEWAY" {
  depends_on = [
    aws_eip.Nat-Gateway-EIP
  ]

  # Allocating the Elastic IP to the NAT Gateway!
  allocation_id = aws_eip.Nat-Gateway-EIP.id

  # Associating it in the Public Subnet!
  subnet_id = aws_subnet.eks_public1_subnet.id
  tags = {
    Name = "Nat-Gateway_Project"
  }
}

# Creating a Route Table for the Nat Gateway!
resource "aws_route_table" "NAT-Gateway-RT" {
  depends_on = [
    aws_nat_gateway.NAT_GATEWAY
  ]

  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT_GATEWAY.id
  }

  tags = {
    Name = "Route Table for NAT Gateway"
  }

}

# Creating an Route Table Association of the NAT Gateway route
# table with the Private Subnet!
resource "aws_route_table_association" "eks_private1_rt_assoc" {
  depends_on = [
    aws_route_table.NAT-Gateway-RT
  ]

  #  Private Subnet ID for adding this route table to the DHCP server of Private subnet!
  subnet_id      = aws_subnet.eks_private1_subnet.id

  # Route Table ID
  route_table_id = aws_route_table.NAT-Gateway-RT.id
}

# Creating an Route Table Association of the NAT Gateway route
# table with the Private Subnet!
resource "aws_route_table_association" "eks_private2_rt_assoc" {
  depends_on = [
    aws_route_table.NAT-Gateway-RT
  ]

  #  Private Subnet ID for adding this route table to the DHCP server of Private subnet!
  subnet_id      = aws_subnet.eks_private2_subnet.id

  # Route Table ID
  route_table_id = aws_route_table.NAT-Gateway-RT.id
}
