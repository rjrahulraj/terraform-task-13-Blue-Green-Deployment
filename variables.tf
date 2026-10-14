variable "region" {
  type        = string
  description = "AWS region"
}

variable "prefix" {
  type        = string
  description = "Resource name prefix"
}

variable "vpc_name" {
  type        = string
  description = "Existing VPC name"
}

variable "subnet_names" {
  type        = list(string)
  description = "Existing public subnet names"
}

variable "sg_ssh_name" {
  type        = string
  description = "SSH security group name"
}

variable "sg_http_name" {
  type        = string
  description = "HTTP security group name for instances"
}

variable "sg_lb_name" {
  type        = string
  description = "ALB security group name"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
}

variable "blue_weight" {
  type        = number
  description = "Traffic weight for Blue"
}

variable "green_weight" {
  type        = number
  description = "Traffic weight for Green"
}