variable "project_name" {
  type = string
}

variable "ami_id" {
  type    = string
  default = null
}

variable "key_name" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "bastion_sg_id" {
  type = string
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "private_nodes_sg_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "private_nodes" {
  description = "Map of private node key => { subnet_id, instance_type, role }"
  type = map(object({
    subnet_id     = string
    instance_type = string
    role          = string
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
