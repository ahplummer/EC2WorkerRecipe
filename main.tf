resource "aws_vpc" "mainvpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Project  = var.PROJECT
    Name = "vpc-${var.PROJECT}"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.mainvpc.id
  tags = {
    Project  = var.PROJECT
    Name = "vpc-${var.PROJECT}"
  }
}

resource "aws_subnet" "public" {
  cidr_block = "10.0.0.0/24"
  vpc_id = aws_vpc.mainvpc.id
  availability_zone = var.AVAIL_ZONE
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-${var.PROJECT}"
    Project = var.PROJECT
  }
}

resource "aws_route_table" "publicrt" {
  vpc_id = aws_vpc.mainvpc.id
  tags = {
    Name = "rt-${var.PROJECT}"
    Engagement = var.PROJECT
  }
}

resource "aws_route" "public_inet_gw" {
  route_table_id = aws_route_table.publicrt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public"{
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.publicrt.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id = aws_vpc.mainvpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Project  = var.PROJECT
    Name = "sg-${var.PROJECT}"
  }
}


#A Worker EC2
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
 }
  owners = ["amazon"]
}
resource "aws_key_pair" "worker-key" {
  key_name   = "worker-key"
  public_key = var.EC2_PUBLIC_KEY
}
resource "aws_instance" "worker" {
  ami = data.aws_ami.amazon-linux-2.id
  associate_public_ip_address = true
  instance_type = "t2.micro"
  key_name = aws_key_pair.worker-key.key_name
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  tags = {
    Project  = var.PROJECT
    Name = "ec2-${var.PROJECT}"
  }
//  provisioner "file" {
//    source = "./motd"
//    destination = "~/motd"
//    connection {
//      host = aws_instance.worker.public_ip
//      user = "ec2-user"
//      private_key = file(var.KEYS_NAME)
//    }
//  }
  provisioner "local-exec" {
    command = "sleep 60; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ./${var.KEYS_NAME} -i '${aws_instance.worker.public_ip}',  provision.yml"
  }
}