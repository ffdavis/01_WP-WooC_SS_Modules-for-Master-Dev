resource "aws_instance" "StoreOne-ec2" {
  ami                         = "${lookup(var.ami, var.region)}"
  instance_type               = "${var.instance_type}"
  associate_public_ip_address = "${var.associate_public_ip_address}"

  #subnet_id                  = "$$${var.subnet_id_var}"             I can't pass subnet_id as variable from main becuase I got the error: 
  #                                                                  * aws_instance.StoreOne-ec2: Error launching source instance: InvalidSubnetID.NotFound: 
  #                                                                  The subnet ID '${aws_subnet.StoreOneSNPublic.id}' does not exist
  #                                                                  status code: 400, request id: 705631b0-efb2-49a9-8435-5b1811ca2b87

  subnet_id = "${aws_subnet.StoreOneSNPublic.id}"
  #vpc_security_group_ids     = "$$${var.vpc_security_group_ids_var}" Same issue as the one with "$$${var.subnet_id_var}" 
  vpc_security_group_ids = ["${aws_security_group.StoreOneSG.id}"]
  key_name               = "${var.key_name}"
  tags = {
    Name = "${var.instance_name}"
  }
}

locals {
  STOREONEEC2DPUBIP  = "${aws_instance.StoreOne-ec2.public_ip}"
  STOREONEEC2DNSNAME = "${aws_instance.StoreOne-ec2.public_dns}"
}

resource "null_resource" "StoreOne-ec2-copy" {
  provisioner "file" {
    source      = "./modules/userdata.sh"
    destination = "~/userdata.sh"

    connection {
      host        = "${aws_instance.StoreOne-ec2.public_ip}"
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("c:/tmp/AWS Keys/myKey.pem")}"
      timeout     = "10m"
      agent       = "false"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 744 ~/userdata.sh",
      "sudo sleep 180",                                                       # I had to add a sleep of 180 to get the "apt install apache2 -y" defined in userdate.sh, working ok.
      "~/userdata.sh ${local.STOREONEEC2DPUBIP} ${local.STOREONEEC2DNSNAME}",
    ]

    connection {
      host        = "${aws_instance.StoreOne-ec2.public_ip}"
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("c:/tmp/AWS Keys/myKey.pem")}"
      timeout     = "10m"
      agent       = "false"
    }
  }
}
