# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "n8n_ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "n8n_ec2_profile"
  role = aws_iam_role.ec2_role.name
}

# Security Group
resource "aws_security_group" "n8n_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting to your IP for better security
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5678
    to_port     = 5678
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

# Network ACL
resource "aws_network_acl" "n8n_acl" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public.*.id

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 5678
    to_port    = 5678
  }

  ingress {
    rule_no    = 140
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 8080
    to_port    = 8080
  }

  ingress {
    rule_no    = 200
    protocol   = "-1"
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 200
    protocol   = "-1"
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# EC2 Instance
resource "aws_instance" "n8n_ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = element(aws_subnet.public.*.id, 0)
  vpc_security_group_ids      = [aws_security_group.n8n_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "n8n-ec2-instance"
  }
}

# Wait for Instance
resource "null_resource" "wait_for_instance" {
  depends_on = [aws_instance.n8n_ec2]

  provisioner "local-exec" {
    command = "sleep 120"
  }
}

# Output Public IP
output "public_ip" {
  value = aws_instance.n8n_ec2.public_ip
}

# Provision Instance
resource "null_resource" "provision_instance" {
  depends_on = [null_resource.wait_for_instance]

  provisioner "file" {
    source      = "../aws/ec2/docker-compose.yml"
    destination = "/home/ubuntu/docker-compose.yml"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/n8nsetup.pem")
      host        = aws_instance.n8n_ec2.public_ip
      timeout     = "5m"
    }
  }

  provisioner "file" {
    source      = "../aws/ec2/.env"
    destination = "/home/ubuntu/.env"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/n8nsetup.pem")
      host        = aws_instance.n8n_ec2.public_ip
      timeout     = "5m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo service docker start",
      "sudo usermod -a -G docker ubuntu",
      "sudo amazon-linux-extras install docker-compose -y",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "docker-compose -f /home/ubuntu/docker-compose.yml up -d"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/n8nsetup.pem")
      host        = aws_instance.n8n_ec2.public_ip
      timeout     = "5m"
    }
  }
}
