variable "project_name" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnets: key => { cidr, az }"
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "private_subnets" {
  description = "Map of private subnets: key => { cidr, az }"
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
