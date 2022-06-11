# Main entrypoint
terraform {
  backend "s3" {
    bucket         = "sverify-terraform-state-backend"
    key            = "dev/main/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "sverify-terraform-state"
  }
  required_version = ">=1.1.0"
}


# Local variables
locals {
  account_id           = "412857254796"
  region               = "us-east-2"
  cluster_name         = "dev-sVerify-psv-daq-cluster"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.0.0/22", "10.0.4.0/22", "10.0.8.0/22"]
  private_subnet_cidrs = ["10.0.12.0/22", "10.0.16.0/22", "10.0.20.0/22"]
  db_subnet_cidrs      = ["10.0.24.0/22", "10.0.28.0/22", "10.0.32.0/22"]
  enable_vpc_flow_log  = true
  flow_log_max_aggregation_interval = 60
  vpc_flow_logs_retention_in_days   = 30
  project_name 	        = "verify"
}


# Providers
provider "aws" {
  region = local.region
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}


# sVerify VPC terraform module
module "sVerify_vpc" {
  source               = "../../../projects/verify/modules/sVerify_vpc"
  account_id           = local.account_id
  region               = local.region
  cluster_name         = local.cluster_name
  vpc_cidr             = local.vpc_cidr
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  db_subnet_cidrs      = local.db_subnet_cidrs
  enable_vpc_flow_log  = local.enable_vpc_flow_log
  flow_log_max_aggregation_interval = local.flow_log_max_aggregation_interval
  vpc_flow_logs_retention_in_days   = local.vpc_flow_logs_retention_in_days

}

# sVerify EKS terraform module
module "sVerif_eks" {

  source       = "../../../projects/verify/modules/sVerify_eks"
  cluster_name                = local.cluster_name
  cluster_enabled_log_types   = ["audit", "api", "authenticator"]
  create_cloudwatch_log_group = true
  cluster_version             = "1.22"
  account_id                  = local.account_id
  region                      = local.region
  project_name                = local.project_name

  vpc_id                = module.sVerify_vpc.vpc_id
  private_subnet_ids    = module.sVerify_vpc.private_subnets

  instance_types = ["t3.medium"]
  min            = 0
  des            = 0
  max            = 1
}

# Outputs
output "account_id" {
  value = local.account_id
}

output "region" {
  value = local.region
}

