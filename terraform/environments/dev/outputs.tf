output "vpc_id" {
  value = module.network.vpc_id
}

output "bastion_public_ip" {
  value = module.compute.bastion_public_ip
}

output "private_node_ips" {
  value = module.compute.private_node_ips
}

output "private_node_roles" {
  value = module.compute.private_node_roles
}
