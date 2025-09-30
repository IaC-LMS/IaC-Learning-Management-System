variable "aws_region" { default = "us-east-1" }
variable "project" { default = "mvp-lms" }
variable "vpc_id" { default = "" } 

variable "db_user" {
  type        = string
  description = "Aurora master username"
  default     = "admin"
}

variable "db_password" {
  type        = string
  description = "Aurora master password"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Aurora database name"
  default     = "lmsdb"
}