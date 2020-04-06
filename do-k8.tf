variable "trabajadores" {
  default = 1
}

output "master" {
  value = digitalocean_droplet.do-master.ipv4_address
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
      "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml",
      "DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=9c69c53d75900006ea86a2870429b15c bash -c \" $(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh) \" ",
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl",
      "sudo mv ./kubectl /usr/local/bin/kubectl",
    ]
  }

  provisioner "local-exec" {
      command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa root@${digitalocean_droplet.do-master.ipv4_address}:/etc/kubernetes/admin.conf ~/kbcnf/"
  }
}


resource "digitalocean_droplet" "do-worker" {
    count    = "${var.trabajadores}"
    image = "ubuntu-18-04-x64"
    name = "do-worker${count.index}"
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
      "DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=9c69c53d75900006ea86a2870429b15c bash -c \" $(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh) \" ",
    ]
  }
}


