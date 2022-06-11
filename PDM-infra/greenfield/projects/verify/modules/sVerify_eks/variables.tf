#Variables for AWS account_id and azs

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_id
}

variable "cluster_name" {
  description = "EKS Cluster Name"
}

variable "cluster_version" {
  description = "EKS Cluster Version"
}

variable "cluster_enabled_log_types" {
  description = "Functional Kubernetes logging for different components"
}

variable "create_cloudwatch_log_group" {
  description = "Cloudwatch logs group for EKS cluster"
}

variable "region" {
  description = "AWS default region"
}

variable "account_id" {
  description = "AWS Account ID"
}

variable "vpc_id" {
  description = "EKS's VPC"
}

variable "private_subnet_ids" {
  description = "Private subnets for EKS cluster and node group"
}

variable "instance_types" {
  description = "EKS Worker node Instance types"
}

variable "min" {
  description = "EKS minimum worker nodes"
}

variable "max" {
  description = "EKS maximum Worker nodes"
}

variable "des" {
  description = "EKS desired Worker nodes"
}

variable "project_name" {
  description = "Project Name"
}
