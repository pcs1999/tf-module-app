data "aws_ami" "ami_id" {
  most_recent      = true
  name_regex       = "pre-installed-ansible"
  owners           = ["490686900756"]

}

data "aws_kms_key" "key" {
  key_id = "alias/roboshop"
}