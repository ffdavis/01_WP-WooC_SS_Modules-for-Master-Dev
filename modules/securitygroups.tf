resource "aws_security_group" "StoreOneSG" {
  name = "FrontEnd"

  tags {
    Name = "${var.sg_name}"
  }

  description = "ONLY HTTP CONNECTION INBOUD"
  vpc_id      = "${aws_vpc.StoreOneVPC.id}"

  ingress {
    from_port   = 22            # SSH Port
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80            # NGINX Port
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306          # MariaDB port
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080          # Apache2 Web Server Port
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
