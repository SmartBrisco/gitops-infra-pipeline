resource "aws_security_group" "prod" {
  name        = "${var.project_name}-prod-sg"
  description = "security group for gitops pipeline prod"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Internal only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  tags = {
    Name        = "${var.project_name}-prod-sg"
    managed-by  = "terraform"
    environment = "prod"
  }
}

resource "aws_instance" "prod" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.prod.id]

  root_block_device {
    encrypted = true
  }

  tags = {
    Name        = "${var.project_name}-prod-instance"
    managed-by  = "terraform"
    environment = "prod"
    created-by  = "github-actions"
  }
}