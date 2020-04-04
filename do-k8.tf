variable "trabajadores" {
  default = 1
}


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
      "systemctl enable docker.service",
      # install kubeadm
      "apt install -y curl",
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add",
      "apt-add-repository 'deb http://apt.kubernetes.io/ kubernetes-xenial main'",
      "apt install -y kubeadm",
      "kubeadm version",
      "swapoff -a",
      "kubeadm init --pod-network-cidr=10.244.0.0/16 --token rdzukz.38nvax5kpjg3hfof",
      "mkdir -p $HOME/.kube",
      "cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "chown $(id -u):$(id -g) $HOME/.kube/config",
      "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
    ]
  }
}


resource "digitalocean_droplet" "do-worker" {
    count    = "${var.trabajadores}"
    image = "ubuntu-18-04-x64"
    name = "do-slave${count.index}"
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
      host     = self.ipv4_address
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
      "systemctl enable docker.service",
      # install kubeadm
      "apt install -y curl",
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add",
      "apt-add-repository 'deb http://apt.kubernetes.io/ kubernetes-xenial main'",
      "apt install -y kubeadm",
      "kubeadm version",
      "swapoff -a",
      "sudo kubeadm join ${digitalocean_droplet.do-master.ipv4_address_private}:6443 --token rdzukz.38nvax5kpjg3hfof --discovery-token-unsafe-skip-ca-verification",
    ]
  }
}
 
