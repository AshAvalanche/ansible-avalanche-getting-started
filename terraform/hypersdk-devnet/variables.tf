variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Location of the created resources."
}

variable "ec2_ami" {
  type        = string
  default     = "ami-0a0e5d9c7acc336f1"
  description = "The AMI to use for the EC2 instances."
}

variable "ec2_instance_type" {
  type        = string
  default     = "t2.medium"
  description = "The type of EC2 instance to use."
}

variable "ec2_root_block_device_volume_size" {
  type        = string
  default     = "8"
  description = "The size of the root block device volume."
}

variable "instance_count" {
  type        = number
  default     = 5
  description = "Number of instances to create. Minimum is 5."
}
