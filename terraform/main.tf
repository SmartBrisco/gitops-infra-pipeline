# Data source - get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Data source - get default VPC
data "aws_vpc" "main" {
  default = true
}

data "aws_subnets" "main" {
  filter {
    name   = "defaultForAz"
    values = ["true"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Security group - SSH and HTTP access
resource "aws_security_group" "dev" {
  name        = "${var.project_name}-sg"
  description = "temp security group for gitops pipeline"
  vpc_id      = data.aws_vpc.main.id

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
    Name      = "${var.project_name}-sg"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# EC2 instance
resource "aws_instance" "dev" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.main.ids[0]
  vpc_security_group_ids = [aws_security_group.dev.id]

  tags = {
    Name      = "${var.project_name}-instance"
    Project   = var.project_name
    ManagedBy = "terraform"
    CreatedBy = "github-actions"
  }
}

