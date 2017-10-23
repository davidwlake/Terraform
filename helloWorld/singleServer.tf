##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "portID" {}
variable "key_name" {
  default = "helloWorld"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

##################################################################################
# RESOURCES
##################################################################################
resource "aws_security_group" "instance" {
  name = "terraform-firstEC2-instance"
  ingress {
    from_port = "${var.portID}"
    to_port ="${var.portID}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "firstEC2" {
  ami           = "ami-3f2de345"
  instance_type = "t2.micro"
  key_name  = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  connection {
    user = "ec2-user"
    private_key = "${file(var.private_key_path)}"
  }
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.portID}" & 
              EOF
}  
              


##################################################################################
# OUTPUT
##################################################################################

output "public_ip" {
  value = "${aws_instance.firstEC2.public_ip}"
}
