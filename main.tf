//Criar configuração do Provedor
provider "aws" {
  region  = "us-east-1"
  profile = "desafio-final"
}

terraform {
  backend "s3" {
    profile              = "desafio-final"
    bucket               = "gustavo-formacao-sre"
    key                  = "infra/network/terraform.tfstate"
    region               = "us-east-1"
    workspace_key_prefix = "env:"
  }
}

//Criar VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name,
    IaC  = "Terraform"
  }
}

//Criar Subnets
resource "aws_subnet" "publica1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.cidr_publica1

  tags = {
    Name = var.nome_publica1
  }
  depends_on = [
    aws_vpc.main
  ]
}
resource "aws_subnet" "publica2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.cidr_publica2

  tags = {
    Name = var.nome_publica2
  }
  depends_on = [
    aws_vpc.main
  ]
}
resource "aws_subnet" "privada1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.cidr_privada1

  tags = {
    Name = var.nome_privada1
  }
  depends_on = [
    aws_vpc.main
  ]
}
resource "aws_subnet" "privada2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.cidr_privada2

  tags = {
    Name = var.nome_privada2
  }
  depends_on = [
    aws_vpc.main
  ]
}

//Cria Internet Gateway
resource "aws_internet_gateway" "internet-gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "iac-internet-gw",
    IaC  = "Terraform"
  }
  depends_on = [
    aws_vpc.main
  ]
}

//Cria os IPs dos Nat Gateways
resource "aws_eip" "ip-nat-gateway-1" {
  domain = "vpc"
  tags = {
    IaC = "Terraform"
  }
  depends_on = [
    aws_vpc.main,
    aws_internet_gateway.internet-gw
  ]
}

resource "aws_eip" "ip-nat-gateway-2" {
  domain = "vpc"
  tags = {
    IaC = "Terraform"
  }
  depends_on = [
    aws_vpc.main,
    aws_internet_gateway.internet-gw
  ]
}

//Cria os Nat Gateways
resource "aws_nat_gateway" "nat-gateway-1" {
  allocation_id = aws_eip.ip-nat-gateway-1.id
  subnet_id     = aws_subnet.publica1.id

  tags = {
    Name = "iac-nat-gw-1",
    IaC  = "Terraform"
  }
  depends_on = [
    aws_vpc.main,
    aws_internet_gateway.internet-gw,
    aws_eip.ip-nat-gateway-1
  ]
}

resource "aws_nat_gateway" "nat-gateway-2" {
  allocation_id = aws_eip.ip-nat-gateway-2.id
  subnet_id     = aws_subnet.publica2.id

  tags = {
    Name = "iac-nat-gw-1",
    IaC  = "Terraform"
  }
  depends_on = [
    aws_vpc.main,
    aws_internet_gateway.internet-gw,
    aws_eip.ip-nat-gateway-2
  ]
}

//Cria Tabelas de Roteamento
resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gw.id
  }
  tags = {
    Name = "iac-rtb-publica",
    IaC  = "Terraform"
  }
  depends_on = [
    aws_vpc.main,
    aws_internet_gateway.internet-gw
  ]
}

resource "aws_route_table" "privada1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway-1.id
  }
  tags = {
    Name = "iac-rtb-privada1",
    IaC  = "Terraform"
  }
  depends_on = [
    aws_vpc.main,
    aws_internet_gateway.internet-gw
  ]
}
resource "aws_route_table" "privada2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway-2.id
  }
  tags = {
    Name = "iac-rtb-privada2",
    IaC  = "Terraform"
  }
  depends_on = [
    aws_vpc.main,
    aws_internet_gateway.internet-gw
  ]
}

resource "aws_route_table_association" "publica1" {
  subnet_id      = aws_subnet.publica1.id
  route_table_id = aws_route_table.publica.id
}
resource "aws_route_table_association" "publica2" {
  subnet_id      = aws_subnet.publica2.id
  route_table_id = aws_route_table.publica.id
}
resource "aws_route_table_association" "privada1" {
  subnet_id      = aws_subnet.privada1.id
  route_table_id = aws_route_table.privada1.id
}
resource "aws_route_table_association" "privada2" {
  subnet_id      = aws_subnet.privada2.id
  route_table_id = aws_route_table.privada2.id
}

######################################## EC2 ########################################

resource "aws_security_group" "allow_ssh" {
  name        = var.name_security_group
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
    ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_SSH"
  }
}

resource "aws_instance" "ec2_1" {
  ami                    = var.ami_aws_instance
  instance_type          = var.type_aws_instance
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name               = var.key_aws_instance
  user_data = <<-EOF
              #!/bin/bash 
              sudo apt update && sudo apt install curl ansible unzip -y 
              cd /tmp
              wget https://esseeutenhocertezaqueninguemcriou.s3.amazonaws.com/ansible.zip
              unzip ansible.zip
              sudo ansible-playbook wordpress.yml
              EOF
  monitoring             = true
  subnet_id              = aws_subnet.publica1.id
  associate_public_ip_address = true
  

  tags = {
    Name = "Minha_primeira_maquina"
  }
}


######################################## RDS ########################################


resource "aws_db_instance" "banco" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = var.dbuser
  password             = var.dbpass
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}



######################################## BUCKET ########################################

# Create a bucket
resource "aws_s3_bucket" "bucket" {

  bucket = "desafiofinalgustavo"

  tags = {

    Name        = "Ansible bucket"

    Environment = "Prod"

  }

}

# Upload an object
resource "aws_s3_bucket_object" "this" {

  bucket = aws_s3_bucket.bucket.id

  key    = "ansible.zip"

  acl    = "public-read"  # or can be "private"

  source = "ansible.zip"

  etag = filemd5("ansible.zip")

}