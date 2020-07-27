provider "aws" {
  region = "ap-south-1"
  profile="surbhisahdev508"
}

resource "tls_private_key" "generated_key" {
  algorithm   = "RSA"
  
}

resource "aws_key_pair" "generated_key" {
  depends_on = [ tls_private_key.generated_key, ]
  key_name   = "sshkey2"
  public_key = tls_private_key.generated_key.public_key_openssh
}

resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "main"
  }
}



//Provides an VPC subnet resource


resource "aws_subnet" "wpsubnet1" {
  vpc_id     = "vpc-05b4a21e5005ec5cb"
  cidr_block = "192.168.1.0/24"
//availability_zone = aws_instance.my_instance.availability_zone
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"


  tags = {
    Name = "wpsubnet1"
  }
}


//Provides an VPC subnet resource


resource "aws_subnet" "mysqlsubnet2" {
  vpc_id     = "vpc-05b4a21e5005ec5cb"
  cidr_block = "192.168.0.0/24"
//availability_zone = aws_instance.my_instance.availability_zone
  availability_zone = "ap-south-1a"


  tags = {
    
     Name = "mysqlsubnet2"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = "vpc-05b4a21e5005ec5cb"

  tags = {
    Name = "gateway"
  }
}
resource "aws_route_table" "gateway_route" {
  vpc_id = "vpc-05b4a21e5005ec5cb"


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "aws_internet_gateway.gateway.id"
  }


  tags = {
    Name = "my_gw_route"
  }
}


// Provides a resource to create an association


resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.wpsubnet1.id
  route_table_id = aws_route_table.gateway_route.id
}

// Provides a security group resource for wordpress_sg

resource "aws_security_group" "wpsg" {
  name        = "wordpress_sg"
  description = "Allow inbound traffic"
  vpc_id = "vpc-05b4a21e5005ec5cb"


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


// Provides a security group resource for mysqlsg

resource "aws_security_group" "mysqlsg" {
  name        = "mysqlsg"
  description = "MySQL sg set-up"
  vpc_id = "vpc-05b4a21e5005ec5cb"


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TCP"
    from_port   = 3306
    to_port     = 3306
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

//Provides an EC2 instance resource


resource "aws_instance" "WpOs" {
	ami = "ami-0c3d500b591de7dd9"
	instance_type = "t2.micro"
        associate_public_ip_address = true
	key_name =  aws_key_pair.instance_key.key_name
	vpc_security_group_ids = [aws_security_group.wpsg.id]
        subnet_id="${aws_subnet.public_subnet.id}"
tags = {
	Name = "WordPressOS"
	}
   }


resource "aws_instance" "mysqlOs" {
	ami = "ami-08706cb5f68222d09"
	instance_type = "t2.micro"
        associate_public_ip_address = true  
	key_name =  aws_key_pair.instance_key.key_name
	vpc_security_group_ids = [aws_security_group.mysqlsg.id]
       subnet_id="${aws_subnet.private_subnet.id}"
     
tags = {
	Name = "MySqlOS"
	}
   }


resource "null_resource" "save_key_pair"  {
	provisioner "local-exec" {
	command = "echo  '${tls_private_key.instance_key.private_key_pem}' > key.pem"
  	
   }
 }