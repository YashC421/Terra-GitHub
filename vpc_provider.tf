resource "aws_vpc" "tera-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tera-vpc"
  }

}

resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.tera-vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id     = aws_vpc.tera-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "my-internet-gateway" {
  vpc_id = "vpc-01b051b9a3aba6fa5"

  tags = {
    Name = "my-igw"
  }
}


resource "aws_route_table" "public-rout" {
  vpc_id = aws_vpc.tera-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-internet-gateway.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "association" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rout.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}
resource "aws_nat_gateway" "NAT-gw" {
  allocation_id = aws_eip.nat.id
  connectivity_type = "public"
  subnet_id     = aws_subnet.public-subnet.id

  tags = {
    Name = "NAT-gw"
  }
}

resource "aws_route_table" "private-rout" {
  vpc_id = aws_vpc.tera-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT-gw.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "association-1" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-rout.id
}


resource "aws_security_group" "my-vpc-sg" {
  name        = "my-vpc-sg"
  description = "Allow HTTP and SSH"
  vpc_id = aws_vpc.tera-vpc.id
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "my-vpc-instance" {
  ami               = "ami-0aa097a5c0d31430a"
  instance_type     = "t2.micro"
  subnet_id         = aws_subnet.public-subnet.id
  key_name          = "terraform-key"
  associate_public_ip_address = true
  security_groups   = [aws_security_group.my-vpc-sg.id]

  tags = {
    Name = "vpc-public-instance"
  }
}

resource "aws_instance" "my-vpc-private-instance" {
  ami               = "ami-0aa097a5c0d31430a"
  instance_type     = "t2.micro"
  subnet_id         = aws_subnet.private-subnet.id
  key_name          = "terraform-key"
  associate_public_ip_address = false
  security_groups   = [aws_security_group.my-vpc-sg.id]

  tags = {
    Name = "vpc-private-instance"
  }
}
