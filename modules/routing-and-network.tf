# EXTERNAL NETWORK , IG, ROUTE TABLE
resource "aws_internet_gateway" "StoreOneGW" {
  vpc_id = "${aws_vpc.StoreOneVPC.id}"

  tags = {
    Name = "${var.ig_name}"
  }
}

resource "aws_network_acl" "StoreOneACL" {
  vpc_id = "${aws_vpc.StoreOneVPC.id}"

  egress {
    protocol   = "-1"
    rule_no    = 2
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 1
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.nacl_name}"
  }
}

# Routing Table PUBLIC access
resource "aws_route_table" "StoreOneRTPub" {
  vpc_id = "${aws_vpc.StoreOneVPC.id}"

  tags = {
    Name = "${var.rt_name}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.StoreOneGW.id}"
  }
}
