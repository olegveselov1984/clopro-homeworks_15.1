#создаем облачную сеть
resource "yandex_vpc_network" "develop" {
  name = var.env_name_network #"develop"
 }

#создаем подсеть
resource "yandex_vpc_subnet" "develop" {
  name           = var.env_name_subnet #"develop-ru-central1-a"
  zone           = var.zone #"ru-central1-a"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = var.cidr 
 }

