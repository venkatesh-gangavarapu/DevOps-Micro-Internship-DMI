# variables.tf
variable "aws_region"    { default = "ap-south-1" }
variable "instance_type" { default = "t2.micro" }
variable "key_pair_name" { default = "epicbook-key" }
variable "db_name"       { default = "epicbook" }
variable "db_username"   { default = "admin" }
variable "db_password"   { sensitive = true; default = "YourStr0ngPass!" }
variable "tags" {
  default = {
    Project    = "dmi-week10-epicbook"
    ManagedBy  = "terraform"
    Week       = "10"
    Assignment = "4"
    Author     = "venkatesh-gangavarapu"
  }
}
