/*
Network Address	Mask bits   hosts
172.28.0.0      /27         30

Subnet address	Netmask	          Range of addresses	          Useable IPs	                Hosts
172.28.0.0/28	  255.255.255.240	  172.28.0.0 - 172.28.0.15	    172.28.0.1 - 172.28.0.14	  14		
172.28.0.16/28	255.255.255.240	  172.28.0.16 - 172.28.0.31	    172.28.0.17 - 172.28.0.30	  14	
*/

#
# ec2-ubuntu
#
variable "region" {}

variable "ami" {
  type        = "map"
  description = "Showing the map feature"
}

variable "instance_type" {}
variable "associate_public_ip_address" {}

# variable "vpc_security_group_ids" {}
variable "key_name" {
  default     = "myKey"
  description = "the ssh key to use in the EC2 machines"
}

variable "instance_name" {}

#
# vpc-subnets.tf
#
variable "vpc_name" {}

variable "vpc_cidr" {}
variable "subnet_public_name" {}
variable "subnet_public_cidr" {}

#
# routing-andnetwork.tf
#
variable "ig_name" {}

variable "nacl_name" {}
variable "rt_name" {}

#
# securitygroups.tf
#
variable "sg_name" {}
