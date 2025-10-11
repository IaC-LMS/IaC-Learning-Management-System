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
  # Usamos la variable de región definida en variables.tf
  region = var.aws_region 
}