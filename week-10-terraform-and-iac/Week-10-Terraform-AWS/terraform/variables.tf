# variables.tf
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "dmi-week10-aws"
    ManagedBy   = "terraform"
    Environment = "learning"
    Week        = "10"
    Assignment  = "2"
    Author      = "venkatesh-gangavarapu"
  }
}
