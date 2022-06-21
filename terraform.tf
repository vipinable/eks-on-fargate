terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 4.18.0"
    }
  }
  backend "s3" {
    bucket         = "terraform-288866261642"
    key            = "terraform.tfstate"
    region = "us-west-2"
    dynamodb_table = "terraform-state-lock"
  }
}
provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "s3-terraform" {
  bucket = "terraform-288866261642"
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Name        = "terraform_back"
    Environment = "Test"
  }
}

module "tfstatefilestore" {
  source = "./module/s3policy"
  bucket = aws_s3_bucket.s3-terraform.id
}

resource "aws_dynamodb_table" "terraform-state-lock" {
  name = "terraform-state-lock"
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
