# Security Group
resource "aws_security_group" "dev" {
  name        = "${var.project_name}-sg"
  description = "temp security group for gitops pipeline"
  network_id      = aws_network.main.id

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
  network_security_group_ids = [aws_security_group.dev.id]

  tags = {
    Name        = "${var.project_name}-instance"
    managed-by  = "terraform"
    environment = "dev"
    created-by  = "github-actions"
  }
}