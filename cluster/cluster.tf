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
data "aws_availability_zones" "all" {}
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
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-firstEC2-elb"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "aws_launch_configuration" "firstCluster" {
  image_id = "ami-2d39803a"
  instance_type = "t2.micro"
  key_name  = "${var.key_name}"
  security_groups = ["${aws_security_group.instance.id}"]

  connection {
    user = "ec2-user"
    private_key = "${file(var.private_key_path)}"
  }
  
  lifecycle {
    create_before_destroy = true
  }
  user_data = <<-EOF
              #!/bin/bash
              r=$((( $RANDOM % 10 )+1));  
              echo "Welcome to Cluster: " + $r > index.html
              nohup busybox httpd -f -p "${var.portID}" & 
              EOF
    
}  
              
resource "aws_autoscaling_group" "firstCluster" {
  launch_configuration = "${aws_launch_configuration.firstCluster.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  min_size = 2
  max_size = 10

  load_balancers = ["${aws_elb.firstCluster.name}"]
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "terraform-asg-firstCluster"
    propagate_at_launch = true
  }
}

resource "aws_elb" "firstCluster" {
  name = "terraform-asg-firstCluster"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups = ["${aws_security_group.elb.id}"]

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.portID}/"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "${var.portID}"
    instance_protocol = "http"
  }

}

##################################################################################
# OUTPUT
##################################################################################


output "elb_dns_name" {
  value = "${aws_elb.firstCluster.dns_name}"
}