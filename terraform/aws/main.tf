# VPC
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

# Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-subnet"
    managed-by  = "terraform"
    environment = "dev"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    managed-by  = "terraform"
    environment = "dev"
  }
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-rt"
    managed-by  = "terraform"
    environment = "dev"
  }
}

# Route Table Association
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Security Group
resource "aws_security_group" "dev" {
  name        = "${var.project_name}-sg"
  description = "temp security group for gitops pipeline"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg"
    managed-by  = "terraform"
    environment = "dev"
  }
}

# AMI - hardcoded for policy testing, data source requires real AWS credentials
# To use dynamic lookup restore: data "aws_ami" "amazon_linux_2" block
# and set ami = data.aws_ami.amazon_linux_2.id on the instance resource
resource "aws_instance" "dev" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2 us-east-1
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.dev.id]

  tags = {
    Name        = "${var.project_name}-instance"
    managed-by  = "terraform"
    environment = "dev"
    created-by  = "github-actions"
  }
}