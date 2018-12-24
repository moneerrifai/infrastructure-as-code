provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "C:\\Users\\admin\\.aws\\credentials" 
  profile                 = "default"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.1.0/24"
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"

  tags {
    Name = "ICC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "ICC-IGW"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/28"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "true"

  tags {
    Name = "ICC-Subnet-1"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "ICC-route_table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.main.id}"
  route_table_id = "${aws_route_table.rt.id}"
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow all inbound ssh and http traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  ami = "ami-009d6802948d06e52"
  instance_type = "t2.micro"
  subnet_id = "{$aws_subnet.main.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh_http.id}"]
  key_name = "generic-key"
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              sudo service httpd start
              EOF
  tags {
    Name = "terraform-example"
  }
}

output "public_ip" {
  value = "${aws_instance.example.public_ip}"
}