resource "aws_security_group" "prod" {
  name        = "${var.project_name}-prod-sg"
  description = "security group for gitops pipeline prod"
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

  tags = {
    Name        = "${var.project_name}-prod-instance"
    managed-by  = "terraform"
    environment = "prod"
    created-by  = "github-actions"
  }
}