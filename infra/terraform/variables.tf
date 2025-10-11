variable "aws_region" { 
  default = "us-east-1" 
}

variable "project" { 
  default = "mvp-lms" 
}

variable "vpc_id" { 
  default = "" 
} 

# 1. Variables de Conexión a la Base de Datos (Aurora)

variable "db_user" {
  type        = string
  description = "Usuario maestro de Aurora."
  # Valor: 'admin'
  default     = "admin"
}

variable "db_password" {
  type        = string
  description = "Contraseña maestra de Aurora (¡Sensible!)."
  # NOTA: Por seguridad, se declara como sensible. Su valor debe pasarse 
  sensitive   = true 
}

variable "db_name" {
  type        = string
  description = "Nombre del esquema/base de datos creado en Aurora."
  # Valor: 'lms_db'
  default     = "lms_db"
}