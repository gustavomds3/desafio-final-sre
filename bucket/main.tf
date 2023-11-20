provider "aws" {
  region  = "us-east-1"
  profile = "desafio-final"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "gustavo-formacao-sre"

  tags = {
    IaC         = "Terraform"
    Environment = "Dev"
  }
}