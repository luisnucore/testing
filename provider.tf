variable "do_token" {}
variable "pub_key" {}
variable "pvt_key" {}
variable "fingerprint" {}

provider "digitalocean" {
  token = "${var.do_token}"
}
