output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "private_node_ips" {
  value = { for k, v in aws_instance.private_nodes : k => v.private_ip }
}

output "private_node_roles" {
  value = { for k, v in aws_instance.private_nodes : k => v.tags["Role"] }
}
