terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Usar una versión específica asegura consistencia.
      version = "~> 6.0" 
    }
  }
}

provider "aws" {
  region = var.aws_region 
}