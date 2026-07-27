module "vpc" {
  source = "../../../../terraform-aws-vpc"

  name               = local.name
  cidr_blocks        = ["10.0.0.0/16"]
  availability_zones = local.azs
  single_nat_gateway = true

  subnets = {
    "public" = {
      cidr_blocks        = ["10.0.1.0/24", "10.0.2.0/24"]
      subnet_type        = "public"
      create_nat_gateway = true
    }
    "private" = {
      cidr_blocks = ["10.0.10.0/24", "10.0.20.0/24"]
      subnet_type = "private"
    }
  }

  tags = local.tags
}

module "eks" {
  source = "../../../../terraform-aws-kubernetes-cluster"

  name            = local.name
  cluster_version = "1.31"

  subnet_ids = module.vpc.subnet_id_map["private"]
  vpc_id     = module.vpc.vpc.id

  api_server = {
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  bootstrap_self_managed_addons = true

  node_groups = {
    system = {
      instance_types = ["t3.medium"]
      subnet_ids     = module.vpc.subnet_id_map["private"]

      scaling = {
        min_size     = 2
        max_size     = 4
        desired_size = 2
      }

      iam_role_additional_policies = {
        SSM = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }

  tags = local.tags
}
