variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "admin_cidrs" {
  description = "Your admin IP(s) in CIDR form, e.g. [\"203.0.113.5/32\"]. Never use 0.0.0.0/0 here."
  type        = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
