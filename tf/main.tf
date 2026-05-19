data "yandex_compute_image" "ubuntu_2404_lts" {
  family = "ubuntu-2404-lts"
}

resource "yandex_compute_instance" "python-app-mia" {
  name        = "python-app-mia"
  hostname    = "python-app-mia"
  platform_id = "standard-v4a"
  zone        = "ru-central1-a"

  resources {
    cores         = var.test.cores
    memory        = var.test.memory
    core_fraction = var.test.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  connection {
    type = "ssh"
    user = "user"
    private_key = file("~/.ssh/muriakey")
    host = self.network_interface.0.nat_ip_address
  }

  provisioner "file" {
    source = "./example-python.sh"
    destination = "/home/user/example-python.sh"
  }

  provisioner "file" {
    source = "./backup.sh"
    destination = "/home/user/backup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y ca-certificates curl",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc",
      "sudo chmod a+r /etc/apt/keyrings/docker.asc",
      "sudo tee /etc/apt/sources.list.d/docker.sources <<EOF",
      "Types: deb",
      "URIs: https://download.docker.com/linux/ubuntu",
      "Suites: $(. /etc/os-release && echo \"$${UBUNTU_CODENAME:-$VERSION_CODENAME}\")",
      "Components: stable",
      "Architectures: $(dpkg --print-architecture)",
      "Signed-By: /etc/apt/keyrings/docker.asc",
      "EOF",
      "sudo chmod a+r /etc/apt/sources.list.d/docker.list",
      "sudo apt update",
      "sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo mv /home/user/example-python.sh /opt/example-python.sh",
      "sudo mv /home/user/backup.sh /opt/backup.sh",
      "sudo chmod +x /opt/example-python.sh",
      "sudo chmod +x /opt/backup.sh",
      "sudo bash /opt/example-python.sh"
      ]
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id          = yandex_vpc_subnet.sdvps-mia.id
    nat                = true
  }
}

resource "local_file" "inventory" {
  content  = <<-XYZ

  [webservers]
  ${yandex_compute_instance.python-app-mia.network_interface.0.nat_ip_address}

  XYZ
  filename = "./hosts.ini"
}