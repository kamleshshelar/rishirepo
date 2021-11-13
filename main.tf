##################################################################--VPC Creation--#######################################################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.vpc_name}-${var.environment}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "shared"
  }
}
