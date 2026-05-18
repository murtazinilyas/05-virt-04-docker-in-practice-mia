resource "yandex_vpc_network" "sdvps-mia" {
  name = "${var.flow}"
}

resource "yandex_vpc_subnet" "sdvps-mia" {
  name           = "${var.flow}-ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.sdvps-mia.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}