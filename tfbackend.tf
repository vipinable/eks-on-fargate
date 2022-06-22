#Set default region
provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" { state = "available" }


##remote backend configuration
terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 4.19.0"
    }
  }
  backend "s3" {
    region	   = "us-east-1"
    bucket         = "eks-tfstatefilestore-598271471667"
    key            = "terraform.tfstate"
    dynamodb_table = "eks-tfstatefilestorelock"
  }
}

#remote backend s3 storage
resource "aws_s3_bucket" "tfstatefilestore" {
  bucket = "${var.appname}-tfstatefilestore-${data.aws_caller_identity.current.account_id}"
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Name        = "${var.appname}-tfstatefilestore-${data.aws_caller_identity.current.account_id}"
    Environment = "${var.envname}"
  }
}

module "tfstatefilestore" {
  source = "./module/s3policy"
  bucket = aws_s3_bucket.tfstatefilestore.id
}

#remote backend state lock dynamodb table
resource "aws_dynamodb_table" "tfstatefilestorelock" {
  name = "${var.appname}-tfstatefilestorelock"
  hash_key = "LockID"
  read_capacity = 5
  write_capacity = 5
  lifecycle {
    prevent_destroy = true
  }
  attribute {
    name = "LockID"
    type = "S"
  }
}
