provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}


resource "tls_private_key" "dev" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

variable "key_name" {
  default = "ztna_demo_ec2_ssh_key"
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.dev.public_key_openssh
  provisioner "local-exec" { # Create "key_name.pem" to your computer!!
    command = "echo '${tls_private_key.dev.private_key_pem}' > ./'${var.key_name}'.pem"
  }
  provisioner "local-exec" {
    command = "chmod 600 ./'${var.key_name}'.pem"
  }
}

/* locals {
  user_data = file("scripts/ec2_user_data.sh")
} */

data "template_file" "init" {
  template = "${file("scripts/ec2_user_data.sh")}"
  vars = {
    vm_connector_name = "${var.vm_connector_name}"
    vm_connector_token = "${var.vm_connector_token}"
    kind_connector_name = "${var.kind_connector_name}"
    kind_connector_token = "${var.kind_connector_token}"  
  }
}

resource "aws_vpc" "ztna_demo_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.deployment_name}_vpc"
  }
}

resource "aws_subnet" "ztna_demo_public_subnet" {
  vpc_id            = aws_vpc.ztna_demo_vpc.id
  cidr_block        = "10.0.100.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.deployment_name}_public_subnet"
  }
}

resource "aws_subnet" "ztna_demo_private_subnet" {
  vpc_id            = aws_vpc.ztna_demo_vpc.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.deployment_name}_private_subnet"
  }
}

resource "aws_internet_gateway" "ztna_demo_ig" {
  vpc_id = aws_vpc.ztna_demo_vpc.id

  tags = {
    Name = "${var.deployment_name}_ig"
  }
}

resource "aws_route_table" "ztna_demo_public_rt" {
  vpc_id = aws_vpc.ztna_demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ztna_demo_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.ztna_demo_ig.id
  }

  tags = {
    Name = "${var.deployment_name}_public_route_table"
  }
}

resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.ztna_demo_public_subnet.id
  route_table_id = aws_route_table.ztna_demo_public_rt.id
}


data "aws_ami" "centos" {
  most_recent = true

  owners = ["aws-marketplace"]

  filter {
    name = "product-code"

    values = [
      "cvugziknvmxgqna9noibqnnsy",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "aws-marketplace",
    ]
  }
}

resource "aws_security_group" "ztna_demo_sg" {
  name   = "${var.deployment_name}_sg_ext"
  vpc_id = aws_vpc.ztna_demo_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ztna-demo" {
  key_name = aws_key_pair.generated_key.key_name
  ami           = data.aws_ami.centos.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.ztna_demo_public_subnet.id

  vpc_security_group_ids      = [aws_security_group.ztna_demo_sg.id]
  associate_public_ip_address = true

  provisioner "file" {
    source      = "../ztenvchart"
    destination = "/home/centos/ztenvchart"

    connection {   
      host        = self.public_ip
      user        = "centos"
      private_key = file("./${var.key_name}.pem")
    }
  } 
  user_data_base64 = base64encode(data.template_file.init.rendered)

  root_block_device {
      volume_type = "gp3"
      volume_size = 40
      tags = {
        Name = "${var.deployment_name}_root_block"
      }
    }

  tags = {
    Name = "${var.deployment_name}"
    "Env"      = "ZTNA Demo Env"
  }
}

