# variables.tf
variable "aws_region"    { default = "ap-south-1" }
variable "instance_type" { default = "t2.micro" }
variable "key_pair_name" { default = "bookreview-key" }
variable "db_username"   { default = "admin" }
variable "db_password"   { sensitive = true; default = "SecurePass1234!" }
variable "tags" {
  default = {
    Project    = "dmi-week10-bookreview"
    ManagedBy  = "terraform"
    Week       = "10"
    Assignment = "5"
    Author     = "venkatesh-gangavarapu"
  }
}
