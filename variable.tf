variable "environment" {
    description = "Environment name"
    default = "myenv"
}

variable "vpc_cidr" {
    description = "Cidr value of vpc"
    default = "10.0.0.0/16"
}

variable "vpc_name" {
    description = "Name of vpc"
    default = "myvpc"
}

variable "cluster_name" {
    description = "mycluster"
    default = "mycluster"
}

variable "public_subnets_cidr" {
    description = "List of public subnet cidr"
    type = list
    default = [ "10.0.1.0/24" ]
}

variable "availability_zones_public" {
    description = "List of availability zones of public subnets"
    type = list
    default = [ "us-east-2a" ]
}

variable "private_subnets_cidr" {
    description = "List of private subnets cidr"
    type = list
    default = [ "10.0.2.0/24" ]
}

variable "availability_zones_private" {
    description = "List of availability zones of private subnets"
    type = list
    default = [ "us-east-2b" ]
}
variable "cidr_block-nat_gw" {
    description = "Destination cidr of nat gateway"
    default = "0.0.0.0/0"
}

variable "cidr_block-internet_gw" {
    description = "Destination cidr of internet gateway"
    default = "0.0.0.0/0"
}
variable "fargate_namespace" {
  description = "Name of fargate selector namespace"
  default = "fargate-node"
}
variable "eks_node_group_instance_types" {
  description  = "Instance type of node group"
  default = "t2.micro"
}
