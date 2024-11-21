provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "Security group for Kubernetes cluster"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 2379
    to_port   = 2380
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 10250
    to_port   = 10259
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kubernetes-sg"
  }
}

resource "aws_instance" "k8s_master" {
  ami           = "ami-005fc0f236362e99f"
  instance_type = "t2.medium"

  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name              = var.key_pair_name

  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "k8s-master"
  }

  user_data = templatefile("${path.module}/scripts/master-init.sh", {})

  # Add metadata options to ensure IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

resource "aws_instance" "k8s_worker" {
  ami           = "ami-005fc0f236362e99f"
  instance_type = "t3.micro"
  depends_on    = [aws_instance.k8s_master]

  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name              = var.key_pair_name

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "k8s-worker"
  }

  user_data = templatefile("${path.module}/scripts/worker-init.sh", {
    master_ip = aws_instance.k8s_master.private_ip
  })

  # Add metadata options to ensure IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}