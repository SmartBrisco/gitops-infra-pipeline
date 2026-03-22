resource "aws_security_group" "prod" {
    name        = "${var.project_name}-prod-sg"
  description = "security group for gitops pipeline prod"
  vpc_id      = aws_vpc.main.id
  ingress {
    cidr_blocks = ["10.0.0.0/8"]  # internal only
  }
  egress {
    cidr_blocks = ["10.0.0.0/8"]  # internal only
  }
}

resource "aws_instance" "prod" {
  root_block_device {
    encrypted = true
  }
    tags = {
    Name        = "${var.project_name}-prod-sg"
    managed-by  = "terraform"
    environment = "prod"
  }
}

resource "aws_instance" "prod" {
  root_block_device {
    encrypted = true
  }
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.prod.id]

  tags = {
    Name        = "${var.project_name}-prod-instance"
    managed-by  = "terraform"
    environment = "prod"
    created-by  = "github-actions"
  }
}