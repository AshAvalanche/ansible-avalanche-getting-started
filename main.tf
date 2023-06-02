terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "ansible_key"
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./files/ansible_key.pem && chmod 400 ./files/ansible_key.pem"
  }
}

resource "aws_security_group" "ssh_avax_sg" {
  name        = "ssh_avax"
  description = "Allow SSH, AVAX HTTP & Staking and outbound traffic"

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "AVAX HTTP"
    from_port        = 9650
    to_port          = 9650
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "AVAX Staking"
    from_port        = 9651
    to_port          = 9651
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = "Outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "fuji_node" {
  ami = "ami-053b0d53c279acc90"
  instance_type = "t2.2xlarge"
  key_name   = aws_key_pair.kp.key_name
  security_groups = [
    aws_security_group.ssh_avax_sg.name
  ]
  root_block_device {
    volume_size = 300
  }
} 

output "fuji_node_ip" {
  value = "${aws_instance.fuji_node.public_ip}"
}
