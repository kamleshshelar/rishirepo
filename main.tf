############################--VPC CReation --########################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.vpc_name}-${var.environment}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "shared"
  }
}
resource "aws_subnet" "public1" {
  vpc_id                   = aws_vpc.main.id
  cidr_block               = "10.0.1.0/24"
  availability_zone        = "us-east-2a"
  map_public_ip_on_launch  = true
  depends_on = [ aws_vpc.main ]

  tags = {

      "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "shared"
      "kubernetes.io/role/elb" = 1
    Name   = "public1-subnet-1"
    state  = "public1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id                   = aws_vpc.main.id
  cidr_block               = "10.0.2.0/24"
  availability_zone        = "us-east-2b"
  map_public_ip_on_launch  = true
  depends_on = [ aws_vpc.main ]

  tags = {

      "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "shared"
      "kubernetes.io/role/elb" = 1
    Name   = "public2-subnet-2"
    state  = "public2"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  depends_on = [ aws_vpc.main ]

  tags = {
    Name = "eks-internet-gateway-${var.environment}"
  }
}

resource "aws_route_table" "internet-route" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "${var.cidr_block-internet_gw}"
    gateway_id = aws_internet_gateway.gw.id
  }
  depends_on = [ aws_vpc.main ]
  tags  = {
      Name = "eks-public_route_table-${var.environment}"
      state = "public"
  }
}

resource "aws_route_table_association" "publicassociation1" {
  subnet_id = aws_subnet.public1.id
  route_table_id = aws_route_table.internet-route.id
  depends_on = [ aws_route_table.internet-route ,
                 aws_subnet.public1
  ]
}

resource "aws_route_table_association" "publicassociation2" {
  subnet_id = aws_subnet.public2.id
  route_table_id = aws_route_table.internet-route.id
  depends_on = [ aws_route_table.internet-route ,
                 aws_subnet.public2
  ]
}

######################## eks Cluster Creation ################################3
#created an Role to which we gave access ,so that it can access eks services frist we create a role
#in our case its "terraformekscluster" under resource name "iam-role-eks-cluster" 
#and then we assign this role the "AmazonEKSClusterPolicy" #policy  in below section.
resource "aws_iam_role" "clusterServiceRole" {
  name = "clusterServiceRole"
  assume_role_policy = <<POLICY
{
 "Version": "2012-10-17",
 "Statement": [
   {
   "Effect": "Allow",
   "Principal": {
    "Service": "eks.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
   }
  ]
 }
POLICY
}

# Attaching the EKS-Cluster policies to the terraformekscluster role.

resource "aws_iam_role_policy_attachment" "clusterServiceRole_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.clusterServiceRole.name}"
}


# Security group for network traffic to and from AWS EKS Cluster.

resource "aws_security_group" "mySecurityGroup" {
  name        = "mySecurityGroup"
  vpc_id      = aws_vpc.main.id

# Egress allows Outbound traffic from the EKS cluster to the  Internet 

  egress {                   # Outbound Rule
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
# Ingress allows Inbound traffic to EKS cluster from the  Internet 

  ingress {                  # Inbound Rule
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Creating the EKS cluster, this also needs the role which we 
# created to be assigned to the cluster

resource "aws_eks_cluster" "myCluster" {
  name     = "myCluster"
  role_arn =  "${aws_iam_role.clusterServiceRole.arn}"
  version  = "1.19"

# Adding VPC Configuration

  vpc_config {             # Configure EKS with vpc and network settings 
   security_group_ids = ["${aws_security_group.mySecurityGroup.id}"]
   subnet_ids         = [aws_subnet.public1.id,aws_subnet.public2.id]   
#   subnet_ids         = ["subnet-1312586","subnet-8126352"]
   }

  depends_on = [
#    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
#    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
     aws_iam_role_policy_attachment.clusterServiceRole_Policy,
#    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy,
#    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSServicePolicy,
   ]
}

## Creating IAM role for EKS nodes to work with other AWS Services. 


resource "aws_iam_role" "myNodeGroupRole" {
  name = "myNodeGroup"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attaching the different Policies to Node Members.

resource "aws_iam_role_policy_attachment" "myNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.myNodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "myCNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.myNodeGroupRole.name
}

resource "aws_iam_role_policy_attachment" "myEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.myNodeGroupRole.name
}

# Create EKS cluster node group

resource "aws_eks_node_group" "myNodegroup" {
  cluster_name    = aws_eks_cluster.myCluster.name
  node_group_name = "myNodeGroup"
  node_role_arn   = aws_iam_role.myNodeGroupRole.arn
  subnet_ids         = [aws_subnet.public1.id,aws_subnet.public2.id]
#  subnet_ids      = ["subnet-","subnet-"]   #--> HardCoded

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.myNodePolicy,
    aws_iam_role_policy_attachment.myCNI_Policy,
    aws_iam_role_policy_attachment.myEC2ContainerRegistryReadOnly,
  ]
}
