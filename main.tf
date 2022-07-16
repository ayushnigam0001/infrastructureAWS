provider "aws" {
  region     = "us-east-2"
  access_key = ""
  secret_key = ""
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    "Name" = "2113074-ayush-vpc"
  }
}

resource "aws_subnet" "subnetPublic" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "2113074-ayush-subnet-public"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "2113074-ayush-igw"
  }
}

resource "aws_subnet" "subnetPrivate" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2a"
  tags = {
    "Name" = "2113074-ayush-subnet-private"
  }
}

resource "aws_route_table" "rTablePublic" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "2113074-ayush-rTable-public"
  }
}

resource "aws_route_table" "rTablePrivate" {
  vpc_id = aws_vpc.myvpc.id
  # route {
  #   cidr_block = "0.0.0.0/0"
  #   gateway_id = aws_instance.ec2NAT.ami
  # }
  tags = {
    Name = "2113074-ayush-rTable-private"
  }
}

resource "aws_route" "routeProxyInstance" {
  route_table_id            = aws_route_table.rTablePrivate.id
  destination_cidr_block    = "0.0.0.0/0"
  network_interface_id      = aws_instance.ec2NAT.primary_network_interface_id
}

resource "aws_route_table_association" "attachPublic" {
  subnet_id      = aws_subnet.subnetPublic.id
  route_table_id = aws_route_table.rTablePublic.id
}

resource "aws_route_table_association" "attachPrivate" {
  subnet_id      = aws_subnet.subnetPrivate.id
  route_table_id = aws_route_table.rTablePrivate.id
}

#ab ec2 service ka part suru hota hai

resource "aws_security_group" "sgPrivate" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    "Name" = "2113074-ayushn-sg-private"
  }
}

resource "aws_security_group" "sgPublic" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    "Name" = "2113074-ayushn-sg-public"
  }
}

resource "aws_security_group" "sgNAT" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    "Name" = "2113074-ayushn-sg-nat"
  }
}

resource "aws_security_group_rule" "sshinboundPublic" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sgPublic.id
}

resource "aws_security_group_rule" "allOutboundPublic" {
  type              = "egress"
  to_port           = 0
  protocol          = "all"
  from_port         = 65525
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sgPublic.id
}

resource "aws_security_group_rule" "sshinboundPrivate" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["10.0.1.0/24"]
  security_group_id = aws_security_group.sgPrivate.id
}

resource "aws_security_group_rule" "httpInboundPrivate" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["10.0.1.0/24"]
  security_group_id = aws_security_group.sgPrivate.id
}

# resource "aws_security_group_rule" "icmpInboundPrivate" {
#   type              = "ingress"
#   from_port         = 0
#   to_port           = 65525
#   protocol          = "icmp"
#   cidr_blocks       = ["10.0.1.0/24"]
#   security_group_id = aws_security_group.sgPrivate.id
# }

resource "aws_security_group_rule" "allOutboundPrivate" {
  type              = "egress"
  to_port           = 0
  protocol          = "all"
  from_port         = 65525
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sgPrivate.id
}

resource "aws_security_group_rule" "sshinboundNAT" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sgNAT.id
}

resource "aws_security_group_rule" "allinboundNAT" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65525
  protocol          = "all"
  cidr_blocks       = ["10.0.2.0/24"]
  security_group_id = aws_security_group.sgNAT.id
}

resource "aws_security_group_rule" "allOutboundNAT" {
  type              = "egress"
  to_port           = 0
  protocol          = "all"
  from_port         = 65525
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sgNAT.id
}

resource "aws_instance" "ec2Public-1" {
  ami                    = "ami-0960ab670c8bb45f3"
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.subnetPublic.id
  vpc_security_group_ids = ["${aws_security_group.sgPublic.id}"]
  key_name               = "2113074-pem"
  user_data              = file("init.sh")
  tags = {
    Name = "2113074-ayush-bation-1"
  }
}

resource "aws_instance" "ec2Private-1" {
  ami                    = "ami-0960ab670c8bb45f3"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnetPrivate.id
  vpc_security_group_ids = ["${aws_security_group.sgPrivate.id}"]
  key_name               = "2113074-pem"
  count                  = 2
  tags = {
    Name = "2113074-ayush-private-1"
  }
}

resource "aws_instance" "ec2NAT" {
  ami                    = "ami-083ef72694a2c1f4f"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnetPublic.id
  vpc_security_group_ids = ["${aws_security_group.sgNAT.id}"]
  source_dest_check      = false
  key_name               = "2113074-pem"
  tags = {
    Name = "2113074-ayush-NAT-1"
  }
}