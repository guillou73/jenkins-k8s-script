provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

# VPC and Security Group
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins server"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins Web Interface"
    from_port   = 8080
    to_port     = 8080
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
    Name = "jenkins-sg"
  }
}

# IAM Role and Policies
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Kubernetes admin policy
resource "aws_iam_role_policy" "kubernetes_admin_policy" {
  name = "kubernetes_admin_policy"
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*",
          "ec2:DescribeInstances",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "iam:GetRole",
          "iam:ListRoles",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ]
        Resource = "*"
      }
    ]
  })
}

# SSM policy attachment
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EKS cluster policy attachment
resource "aws_iam_role_policy_attachment" "eks_admin" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.jenkins_role.name
}

resource "aws_iam_role_policy_attachment" "eks_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.jenkins_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.jenkins_role.name
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins_profile"
  role = aws_iam_role.jenkins_role.name
}

# EC2 Instance
resource "aws_instance" "jenkins_server" {
  ami           = "ami-005fc0f236362e99f"  # Ubuntu 22.04 LTS AMI ID for us-east-1
  instance_type = "t2.medium"
  key_name      = "test-key-1024"

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install -y openjdk-17-jdk

              # Add Jenkins repository
              curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
                /usr/share/keyrings/jenkins-keyring.asc > /dev/null
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
                https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null

              # Install Jenkins
              sudo apt update
              sudo apt install -y jenkins

              # Start Jenkins
              sudo systemctl enable jenkins
              sudo systemctl start jenkins

              # Install additional tools
              sudo apt install -y git docker.io
              sudo usermod -aG docker jenkins
              sudo usermod -aG docker ubuntu

              # Install AWS CLI
              sudo apt install -y unzip
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install

              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

              # Install eksctl
              curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
              sudo mv /tmp/eksctl /usr/local/bin
              
              # Get the initial admin password
              echo "Jenkins initial admin password: " > /home/ubuntu/jenkins-initial-password
              sudo cat /var/lib/jenkins/secrets/initialAdminPassword >> /home/ubuntu/jenkins-initial-password
              EOF

  tags = {
    Name = "jenkins-server"
  }
}

# Output values
output "jenkins_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins_server.public_ip}:8080"
}

output "ssh_connection" {
  value = "ssh -i test-key-1024.pem ubuntu@${aws_instance.jenkins_server.public_ip}"
}
