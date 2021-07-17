provider "aws" {
  region  = ""
  profile = ""
}

##----------------------------
#     Get VPC Variables
##----------------------------

#-- Get VPC ID
data "aws_vpc" "selected" {
  tags = {
    Name = "${var.name_tag}"
  }
}

#-- Get Public Subnet List
data "aws_subnet_ids" "selected" {
  vpc_id = "${data.aws_vpc.selected.id}"

  tags = {
    Tier = "public"
  }
}

#--- Gets Security group with tag specified by var.name_tag
data "aws_security_group" "selected" {
  tags = {
    Name = "${var.name_tag}*"
  }
}
#-- Grab the latest AMI built with packer - widows2016.json
data "aws_ami" "Windows_2016" {
  filter {
    name   = "is-public"
    values = ["false"]
  }

  filter {
    name   = "name"
    values = ["windows2016Server*"]
  }

  most_recent = true
}

#-- sets the user data script
data "template_file" "user_data" {
  template = "/scripts/user_data.ps1"
}


#---- Test Development Server
resource "aws_instance" "this" {
  ami                  = "${data.aws_ami.Windows_2016.image_id}"
  instance_type        = "${var.instance}"
  key_name             = "${module.ssh_key_pair.key_name}"
  subnet_id            = "${data.aws_subnet_ids.selected.ids[01]}"
  security_groups      = ["${data.aws_security_group.selected.id}"]
  user_data            = "${data.template_file.user_data.rendered}"
  iam_instance_profile = "${var.iam_role}"
  get_password_data    = "true"

  root_block_device {
    volume_type           = "${var.volume_type}"
    volume_size           = "${var.volume_size}"
    delete_on_termination = "true"
  }

  tags {
    "Name"    = "NEW_windows2016"
    "Role"    = "Dev"
  }

 