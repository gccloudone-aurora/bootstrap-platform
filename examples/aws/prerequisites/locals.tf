locals {
  name = "bootstrap-aws-example"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Environment = "example"
    Project     = "bootstrap-aws"
    ManagedBy   = "terraform"
  }
}
