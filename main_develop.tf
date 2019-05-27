locals {
  env = "DEVELOP" # It could be PROD, STAGING, DEV, etc                                                       <-----------
}

variable region {
  default = "us-east-1"
}

provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  region                  = "${var.region}"      # us-east-1
  profile                 = "default"
}

module "StoreOne-DEVELOP" {
  # EC2 Variables
  source = "./modules"     #                                                         <-----------
  region = "${var.region}"

  ami {
    us-east-1 = "ami-0a313d6098716f372" # Ubuntu Server 18.04 LTS (HVM), SSD Volume Type -  (64-bit x86)
  }

  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  key_name                    = "myKey"
  instance_name               = "StoreOne-ec2-${local.env}" # "StoreOne-ec2-Develop"

  # Note: Unable to pass these 2 parameters from here as variables as this throws errors:
  #      - subnet_id and 
  #      - vpc_secuirty_group_ids 
  # Based on several notes from terraform forums, it is a general issue where you can't pass variables inside variables.
  # I found a way as. subnet_id = "$$${var.subnet_id_var}" but still got an issue when running terraform APPLY.

  # VPC & SUBNETS variables
  vpc_name           = "StoreOneVPC-${local.env}"
  vpc_cidr           = "173.28.0.0/27"                 #                                                      <-----------
  subnet_public_name = "StoreOneSNPublic-${local.env}"
  subnet_public_cidr = "173.28.0.0/28"                 #                                                      <-----------
  # ROUTING & NETWORK
  ig_name   = "StoreOneGW-${local.env}"
  nacl_name = "StoreOneACL-${local.env}"
  rt_name   = "StoreOneRTPub-${local.env}"
  # SECURITY GROUPS
  sg_name = "StoreOneSG-${local.env}"
}

# Test the installation as follows:
# 
# Edit the hosts file in the local windows 10 machine and add for example:
#
# 3.94.55.148		ec2-3-94-55-148.compute-1.amazonaws.com		wpserver.net   # this are the public ip and dns gotten from AWS console
#
# Then from a browser type:
#   http://wpserver.net
#      and 
#   http://wpserver.net/wp-admin 
#      and verify that you can log in with the WordPress user you created in the previous step.
#

