vpc_cidr      = "10.255.0.0/16"
vpc_name      = "treinamento"
cidr_privada1 = "10.255.1.0/24"
cidr_privada2 = "10.255.2.0/24"
cidr_publica1 = "10.255.3.0/24"
cidr_publica2 = "10.255.4.0/24"
nome_publica1 = "sub-publica1"
nome_publica2 = "sub-publica2"
nome_privada1 = "sub-privada1"
nome_privada2 = "sub-privada-2"

######## EC2 ########

name_security_group = "security group da ec2"
ami_aws_instance = "ami-0fc5d935ebf8bc3bc"
key_aws_instance = "ec2"
#subnet_id_aws_instance = aws_subnet.publica1.id