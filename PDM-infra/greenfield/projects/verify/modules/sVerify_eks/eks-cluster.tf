# Create EKS cluster
module "eks" {
  source                      = "terraform-aws-modules/eks/aws"
  cluster_name                = var.cluster_name
  cluster_version             = var.cluster_version
  subnet_ids                  = var.private_subnet_ids
  cluster_enabled_log_types   = var.cluster_enabled_log_types
  create_cloudwatch_log_group = var.create_cloudwatch_log_group
  version                     = "18.20.5"

  cluster_addons = {
    #coredns = {
    #  resolve_conflicts = "OVERWRITE"
    #}
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  aws_auth_roles = [
    {

    },
  ]

  eks_managed_node_groups = {
    "${var.cluster_name}-dev" = {
      create_launch_template     = true
      name                       = "worker-node"
      subnet_ids                 = var.private_subnet_ids
      instance_types             = var.instance_types
      max_size                   = var.max
      min_size                   = var.min
      desired_size               = var.des
      iam_role_arn               = aws_iam_role.eks_cluster_node_role.arn
      create_iam_role            = false
      create_node_security_group = false
    }
  }

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "All traffic"
      protocol                   = "-1"
      from_port                  = 0
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    },
    ingress_cluster_all = {
      description                   = "All from cluster security group"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  fargate_profiles = {
    "fp-default" = {
      name = "fp-default"
      selectors = [
        {
          namespace = "default"
        },
        {
          namespace = "kube-system"
        }
      ]
      subnet_ids = [var.private_subnet_ids[0], var.private_subnet_ids[1]]

      tags = {
        Owner = "default"
      }

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    },
    "fp-dev" = {
      name = "fp-dev"
      selectors = [
        {
          namespace = "dev"
        }
      ]
      subnet_ids = [var.private_subnet_ids[0], var.private_subnet_ids[1]]

      tags = {
        Owner = "default"
      }

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    },
    "fp-test" = {
      name = "fp-test"
      selectors = [
        {
          namespace = "test"
        }
      ]
      subnet_ids = [var.private_subnet_ids[0], var.private_subnet_ids[1]]

      tags = {
        Owner = "default"
      }

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    },
    "fp-stage" = {
      name = "fp-stage"
      selectors = [
        {
          namespace = "stage"
        }
      ]
      subnet_ids = [var.private_subnet_ids[0], var.private_subnet_ids[1]]

      tags = {
        Owner = "default"
      }
    
      timeouts = {
        create = "20m"
        delete = "20m"
      }
    }
  }

  tags = {
    Environment = var.cluster_name
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  vpc_id = var.vpc_id
}

resource "null_resource" "create_kubeconfig" {

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.region}"
  }
  depends_on = [
    module.eks.eks_managed_node_groups
  ]
}

resource "null_resource" "coredns_patch" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
		kubectl patch deployment coredns \
		  --namespace kube-system \
		  --type=json \
		  -p='[{"op": "remove", "path": "/spec/template/metadata/annotations", "value": "eks.amazonaws.com/compute-type"}]'
	EOF
  }
  depends_on = [
    module.eks.eks_managed_node_groups, null_resource.create_kubeconfig
  ]
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

}
