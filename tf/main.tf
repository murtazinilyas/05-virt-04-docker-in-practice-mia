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