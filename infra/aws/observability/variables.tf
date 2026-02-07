variable "project_name" {
  type    = string
  default = "reliability-lab"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "default"
}

variable "enable_resource_creation" {
  type    = bool
  default = false
}
