data "aws_caller_identity" "current" {}

# --- EKS Cluster IAM Role ---
resource "aws_iam_role" "eks_cluster" {
  name = "gitops-infra-eks-cluster-prod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --- Node Group IAM Role ---
resource "aws_iam_role" "eks_prod_nodes" {
  name = "gitops-infra-eks-prod-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_prod_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_prod_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_read" {
  role       = aws_iam_role.eks_prod_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# --- EKS Cluster ---
resource "aws_eks_cluster" "main" {
  name     = "gitops-infra-eks-prod"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.35"

  vpc_config {
    subnet_ids              = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    endpoint_public_access  = false
    endpoint_private_access = true
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = "arn:aws:kms:us-east-1:${data.aws_caller_identity.current.account_id}:alias/aws/eks"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# --- Managed Node Group ---
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "gitops-infra-prod-nodes"
  node_role_arn   = aws_iam_role.eks_prod_nodes.arn
  subnet_ids      = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  instance_types = ["t3.medium"] # Demo only — production minimum t3.large, recommended m5.xlarge+

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 4
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr_read,
  ]
}