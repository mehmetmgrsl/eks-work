terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.100.0"
    }
  }

  required_version = ">= 1.6"
}

provider "aws" {
  region = local.region
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  cluster_version = "1.30"
  region          = "eu-north-1"

  vpc_cidr        = "10.0.0.0/16"
  azs             = ["eu-north-1a", "eu-north-1b"]
}

# Create VPC to host EKS cluster resources
module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  version         = "5.21.0"

  name = "example-eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-north-1a", "eu-north-1b"]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]


  enable_nat_gateway = true
  enable_vpn_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# Create EKS cluster using the terraform-aws-modules EKS module 
module "eks" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "20.8.5"

  cluster_name       = "example-eks-cluster"
  cluster_version    = local.cluster_version

  cluster_endpoint_public_access  = true

  enable_cluster_creator_admin_permissions = true


  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }  

  subnet_ids         = module.vpc.private_subnets
  vpc_id             = module.vpc.vpc_id

  enable_irsa        = true

  eks_managed_node_groups = {
    default = {
      name         = "worker-node"
      min_size     = var.managed_node_group.min_size
      max_size     = var.managed_node_group.max_size
      desired_size = var.managed_node_group.desired_size

      instance_types = var.managed_node_group.instance_types
      capacity_type  = var.managed_node_group.capacity_type

      update_config = {
        max_unavailable_percentage = 80
      }

      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
  
    }
  }  

  tags = {
    Environment = "example-eks-cluster"
  }
}
