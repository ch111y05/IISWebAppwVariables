variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  default     = "10.123.0.0/16"
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet."
  default     = "10.123.1.0/24"
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the first public subnet."
  default     = "10.123.2.0/24"
}

variable "public_subnet_2_cidr" {
  description = "The CIDR block for the second public subnet."
  default     = "10.123.3.0/24"
}

variable "availability_zone_a" {
  description = "The primary availability zone for subnets."
  default     = "us-west-2a"
}

variable "availability_zone_b" {
  description = "The secondary availability zone for subnets."
  default     = "us-west-2b"
}

variable "key_name" {
  description = "The key name for the EC2 instance."
  default     = "hashikey"
}

variable "instance_type" {
  description = "The instance type for the EC2 instance."
  default     = "t3.micro"
}

variable "ami_owner" {
  description = "The AWS account ID that owns the desired AMI."
  default     = "801119661308"
}

variable "ami_name_filter" {
  description = "The name filter for searching AMIs."
  default     = "Windows_Server-2019-English-Full-Base-*"
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance."
  type        = string
}