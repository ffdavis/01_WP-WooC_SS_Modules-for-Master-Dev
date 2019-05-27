# VPC
resource "aws_vpc" "StoreOneVPC" {
  cidr_block = "${var.vpc_cidr}"

  #### this 2 true values are for use the internal vpc dns resolution
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.vpc_name}"
  }
}

data "aws_availability_zones" "available" {}

# SUBNET PUBLIC
resource "aws_subnet" "StoreOneSNPublic" {
  vpc_id     = "${aws_vpc.StoreOneVPC.id}"
  cidr_block = "${var.subnet_public_cidr}"

  tags {
    Name = "${var.subnet_public_name}"
  }

  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

resource "aws_route_table_association" "StoreOneRTA" {
  subnet_id      = "${aws_subnet.StoreOneSNPublic.id}"
  route_table_id = "${aws_route_table.StoreOneRTPub.id}"
}
