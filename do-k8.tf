resource "digitalocean_droplet" "do-master" {
    image = "ubuntu-18-04-x64"
    name = "do-master"
    region = "nyc3"
    size = "2gb"
    private_networking = true
    ssh_keys = [
      "${var.fingerprint}"
    ]

connection {
      user = "root"
      agent = true
      host     = "${digitalocean_droplet.do-master.ipv4_address}"
      type = "ssh"
      private_key = "${file(var.pvt_key)}"
      timeout = "2m"
  }

provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # install docker
      "sudo apt-get update",
      "sudo apt install -y docker.io",
      # install kubeadm
      "apt install -y curl",
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add",
      "apt-add-repository 'deb http://apt.kubernetes.io/ kubernetes-xenial main'",
      "apt install -y kubeadm",
      "kubeadm version",
      "swapoff -a",
    ]
  }
}


resource "digitalocean_droplet" "do-slave" {
    image = "ubuntu-18-04-x64"
    name = "do-slave"
    region = "nyc3"
    size = "2gb"
    private_networking = true
    depends_on = [digitalocean_droplet.do-master]
    ssh_keys = [
      "${var.fingerprint}"
    ]

connection {
      user = "root"
      agent = true
      host     = "${digitalocean_droplet.do-slave.ipv4_address}"
      type = "ssh"
      private_key = "${file(var.pvt_key)}"
      timeout = "2m"
  }

provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # install docker
      "sudo apt-get update",
      "sudo apt install -y docker.io",
      # install kubeadm
      "apt install -y curl",
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add",
      "apt-add-repository 'deb http://apt.kubernetes.io/ kubernetes-xenial main'",
      "apt install -y kubeadm",
      "kubeadm version",
      "swapoff -a",
    ]
  }
}

