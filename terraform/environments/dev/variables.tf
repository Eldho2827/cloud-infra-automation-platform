variable "project_name" {
  type    = string
  default = "capstone2"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "key_name" {
  description = "Existing EC2 key pair name for SSH access"
  type        = string
}

variable "admin_cidrs" {
  description = "Your admin IP(s) in CIDR form for SSH to the bastion, e.g. [\"203.0.113.5/32\"]"
  type        = list(string)
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.small"
}
variable "node_instance_type" {
  type    = string
  default = "t3.small"
}
