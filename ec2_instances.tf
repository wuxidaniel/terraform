provider "aws" { }

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical's official AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-*-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Look up existing resources by their Name tags
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["UP247-VPC"]
  }
}

data "aws_subnet" "public" {
  filter {
    name   = "tag:Name"
    values = ["up247-public-subnet"]
  }
}

data "aws_subnet" "private" {
  filter {
    name   = "tag:Name"
    values = ["up247-private-subnet"]
  }
}

data "aws_security_group" "public_host" {
  filter {
    name   = "group-name"
    values = ["sg_public_host"]
  }
}

data "aws_security_group" "private_host" {
  filter {
    name   = "group-name"
    values = ["sg_private_host"]
  }
}

# Key pair
resource "aws_key_pair" "ansible" {
  key_name   = "ansible-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# EC2 instance — references existing infra via data sources
resource "aws_instance" "public_host" {
  ami           = data.aws_ami.ubuntu.id   # 👈 always resolves to latest
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ansible.key_name
  subnet_id              = data.aws_subnet.public.id        # 👈 existing subnet
  vpc_security_group_ids = [data.aws_security_group.public_host.id]

  user_data = <<-EOF
    #!/bin/bash
    hostname public-host
  EOF

  tags = {
    Name = "public-host"
  }
}

resource "aws_instance" "private_host" {
  ami           = data.aws_ami.amazon_linux.id   # 👈 always resolves to latest
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ansible.key_name
  subnet_id              = data.aws_subnet.private.id        # 👈 existing subnet
  vpc_security_group_ids = [data.aws_security_group.private_host.id]

  user_data = <<-EOF
    #!/bin/bash
    hostname private-host
  EOF

  tags = {
    Name = "private-host"
  }
}

output "public_instance_id" {
  value = aws_instance.public_host.id
}

output "instance_public_ip" {
  value = aws_instance.public_host.public_ip
}
/*
output "public_dns" {
  value = aws_instance.public_host.public_dns
}
*/
output "private_instance_id" {
  value = aws_instance.private_host.id
}

output "ssh_command_to_public_host" {
  value = "ssh ubuntu@${aws_instance.public_host.public_ip}"
}

output "ssh_command_to_private_host" {
  value = "ssh ec2-user@${aws_instance.private_host.private_ip}"
}
