data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = coalesce(var.ami_id, data.aws_ami.ubuntu.id)
  instance_type          = var.bastion_instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.bastion_sg_id]
  key_name                = var.key_name
  iam_instance_profile    = var.instance_profile_name

  tags = merge(var.tags, { Name = "${var.project_name}-bastion", Role = "bastion" })
}

resource "aws_instance" "private_nodes" {
  for_each = var.private_nodes

  ami                    = coalesce(var.ami_id, data.aws_ami.ubuntu.id)
  instance_type          = each.value.instance_type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = [var.private_nodes_sg_id]
  key_name                = var.key_name
  iam_instance_profile    = var.instance_profile_name

  tags = merge(var.tags, { Name = "${var.project_name}-${each.key}", Role = each.value.role })
}
