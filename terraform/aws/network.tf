# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    managed-by  = "terraform"
    environment = "dev"
  }
}

# --- Public Subnet ---
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24" # fixed from /16
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name                                     = "${var.project_name}-subnet-public"
    managed-by                               = "terraform"
    environment                              = "dev"
    "kubernetes.io/role/elb"                 = "1"
    "kubernetes.io/cluster/gitops-infra-eks" = "shared"
  }
}

# --- Private Subnet A ---
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name                                     = "${var.project_name}-subnet-private-a"
    managed-by                               = "terraform"
    environment                              = "dev"
    "kubernetes.io/role/internal-elb"        = "1"
    "kubernetes.io/cluster/gitops-infra-eks" = "owned"
  }
}

# --- Private Subnet B ---
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name                                     = "${var.project_name}-subnet-private-b"
    managed-by                               = "terraform"
    environment                              = "dev"
    "kubernetes.io/role/internal-elb"        = "1"
    "kubernetes.io/cluster/gitops-infra-eks" = "owned"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    managed-by  = "terraform"
    environment = "dev"
  }
}

# --- Elastic IP for NAT Gateway ---
resource "aws_eip" "nat" {
  domain = "vpc"
}

# --- NAT Gateway (lives in public subnet) ---
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.main.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "${var.project_name}-nat"
    managed-by  = "terraform"
    environment = "dev"
  }
}

# --- Public Route Table ---
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-rt-public"
    managed-by  = "terraform"
    environment = "dev"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# --- Private Route Table ---
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-rt-private"
    managed-by  = "terraform"
    environment = "dev"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
