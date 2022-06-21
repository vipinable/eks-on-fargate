variable "appname" {
  default = "eks"
  type    = string
}

variable "envname" {
  default = "test"
  type    = string
}

variable "vpc_cidr" {
  type        = string
  description = "The IP range to use for the VPC"
  default     = "10.0.0.0/16"
}

variable "cidrs" {
  type = map
}

variable "cluster_name" {
  default = "cluster_01"
  type    = string
}
