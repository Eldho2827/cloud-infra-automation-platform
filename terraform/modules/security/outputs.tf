output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

output "private_nodes_sg_id" {
  value = aws_security_group.private_nodes.id
}
