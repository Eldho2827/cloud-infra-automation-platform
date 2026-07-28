terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  tags = {
    Project     = var.project_name
    Environment = terraform.workspace
    ManagedBy   = "terraform"
  }
}

module "network" {
  source       = "../../modules/network"
  project_name = "${var.project_name}-${terraform.workspace}"
  vpc_cidr     = var.vpc_cidr

  public_subnets = {
    "public-a" = { cidr = "10.0.1.0/24", az = "${var.region}a" }
  }
  private_subnets = {
    "private-a" = { cidr = "10.0.11.0/24", az = "${var.region}a" }
  }

  tags = local.tags
}

module "security" {
  source       = "../../modules/security"
  project_name = "${var.project_name}-${terraform.workspace}"
  vpc_id       = module.network.vpc_id
  vpc_cidr     = var.vpc_cidr
  admin_cidrs  = var.admin_cidrs
  tags         = local.tags
}

module "iam" {
  source       = "../../modules/iam"
  project_name = "${var.project_name}-${terraform.workspace}"
  tags         = local.tags
}

module "compute" {
  source                 = "../../modules/compute"
  project_name           = "${var.project_name}-${terraform.workspace}"
  key_name               = var.key_name
  public_subnet_id       = values(module.network.public_subnet_ids)[0]
  bastion_sg_id          = module.security.bastion_sg_id
  bastion_instance_type  = var.bastion_instance_type
  private_nodes_sg_id    = module.security.private_nodes_sg_id
  instance_profile_name  = module.iam.instance_profile_name

  private_nodes = {
    "app-node-1" = {
      subnet_id     = values(module.network.private_subnet_ids)[0]
      instance_type = var.node_instance_type
      role          = "app"
    }
    "jenkins-agent-1" = {
      subnet_id     = values(module.network.private_subnet_ids)[0]
      instance_type = var.node_instance_type
      role          = "jenkins-agent"
    }
  }

  tags = local.tags
}
