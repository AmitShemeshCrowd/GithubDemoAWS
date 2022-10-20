


########################## terraform file #####################

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.70.0"
    }
  }
}


provider "aws" {
#     access_key = "${AWS_ACCESS_KEY_ID}"
#     secret_key = "${AWS_SECRET_ACCESS_KEY}"
    region     ="us-east-1"
}

variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default = "10.1.0.0/16"
}
variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  default = "10.1.0.0/24"
}
variable "availability_zone" {
  description = "availability zone to create subnet"
  default = "us-east-1a"
}
variable "public_key_path" {
  description = "Public key path"
  default = "~/.ssh/id_rsa.pub"
}
variable "instance_ami" {
  description = "AMI for aws EC2 instance"
  default = "ami-026b57f3c383c2eec"
}
variable "instance_type" {
  description = "type for aws EC2 instance"
  default = "t2.micro"
}
variable "environment_tag" {
  description = "Environment tag"
  default = "YanivTryOuts"
}



resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Environment = var.environment_tag
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Environment = var.environment_tag
  }
}


resource "aws_subnet" "subnet_public" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.cidr_subnet
  map_public_ip_on_launch = "true"
  availability_zone = var.availability_zone
  tags = {
    Environment = var.environment_tag
  }
}


resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id
route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
  }
tags = {
    Environment = var.environment_tag
  }
}


resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.rtb_public.id
}




resource "aws_security_group" "sg_22" {
  name = "sg_22"
  vpc_id = aws_vpc.vpc.id
  ingress {
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
    Environment = var.environment_tag
  }
}


resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "amitkey"
  public_key = "${tls_private_key.example.public_key_openssh}"
}

resource "local_file" "aws_cloud_pem" { 
  filename = "${path.module}/awscloudtls.pem"
  content = tls_private_key.example.private_key_pem
}


resource "aws_instance" "testInstance" {
  ami           = var.instance_ami
  instance_type = "t2.micro"
#   instance_type = var.instance_type
#   subnet_id = aws_subnet.subnet_public.id
#   vpc_security_group_ids = [aws_security_group.sg_22.id]
#   key_name = aws_key_pair.generated_key.key_name
#  tags = {
#   Environment = var.environment_tag
#  }
}
