module "vpc-dev" { #название модуля
  source       = "./vpc-dev" 
  env_name_network = "VPC" #параметры которые передаем
  env_name_subnet  = "public" #параметры которые передаем
  zone = "ru-central1-a"
  cidr = ["192.168.10.0/24"]
  zone2 = "ru-central1-a"
  env_name_subnet2  = "private" #параметры которые передаем
  cidr2 = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private_routes.id
}

# module "vpc-dev-private" { #название модуля
#   source       = "./vpc-dev" 
#  # env_name_network = "VPC" #параметры которые передаем
#   env_name_subnet  = "private" #параметры которые передаем
#   zone = "ru-central1-a"
#   cidr = ["192.168.20.0/24"]
# }

resource "yandex_vpc_route_table" "private_routes" {  #создание роутера (NAT-инстанс)
  name       = "private-route-table"
  network_id = module.vpc-dev.network_id   #yandex_vpc_network.default.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
}

resource "yandex_compute_instance" "nat" {
  name = "nat"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
    }
  }
  network_interface {
    subnet_id = module.vpc-dev.subnet_id #module.vpc-dev.subnet_id #yandex_vpc_subnet.public.id
    ip_address = "192.168.10.254"
    nat       = true
  }
  metadata = {
    user-data          = data.template_file.cloudinit.rendered 
    serial-port-enable = 1
  }
}






resource "yandex_compute_instance" "public" {
  name = "public"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd8ondkh1s6iakbqm635"
    }
  }
  network_interface {
    subnet_id = module.vpc-dev.subnet_id #module.vpc-dev.subnet_id #yandex_vpc_subnet.public.id
    nat       = true
  }
  metadata = {
    user-data          = data.template_file.cloudinit.rendered 
    serial-port-enable = 1
  }
}

resource "yandex_compute_instance" "private" {
  name = "private"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd8ondkh1s6iakbqm635"
    }
  }
  network_interface {
    subnet_id = module.vpc-dev.private_id #module.vpc-dev.subnet_id #yandex_vpc_subnet.public.id
  #  nat       = true
  }
  metadata = {
    user-data          = data.template_file.cloudinit.rendered 
    serial-port-enable = 1
  }
}



# module "module-srv-vm01" {
#   #source         = "git::https://github.com/olegveselov1984/yandex_compute_instance.git?ref=main"
#   source         = "./module-srv-vm"
#   network_id     = module.vpc-dev.network_id 
#   subnet_zones   = ["ru-central1-a","ru-central1-b"]
#   subnet_ids     = [module.vpc-dev.subnet_id] 
#   instance_name  = "srv-vm01"
#   env_name = "srv-vm01" # Имя одной конкретной ВМ. instance_count не учитывается
#   image_family   = "ubuntu-2404-lts"
#   public_ip      = true
#   security_group_ids = [
#   yandex_vpc_security_group.example.id 
#   ]
#    labels = { 
#      project = "srv-vm01"
#       }
#   metadata = {
#     user-data          = data.template_file.cloudinit.rendered #Для демонстрации №3
#     serial-port-enable = 1
#   }

# }





# module "module-srv-vm02" {
#    source         = "git::https://github.com/olegveselov1984/yandex_compute_instance.git?ref=main"
#   network_id     = module.vpc-dev.network_id 
#   subnet_zones   = ["ru-central1-a"]
#   subnet_ids     = [module.vpc-dev.subnet_id]
#   instance_name  = "srv-vm02"
#   env_name = "srv-vm02"
#   image_family   = "ubuntu-2404-lts"
#   public_ip      = true
#   security_group_ids = [
#   yandex_vpc_security_group.example.id 
#   ]
#    labels = { 
#      project = "srv-vm02"
#       }
#   metadata = {
#     user-data          = data.template_file.cloudinit.rendered #Для демонстрации №3
#     serial-port-enable = 1
#   }

# }

# module "module-srv-vm03" {
#    source         = "git::https://github.com/olegveselov1984/yandex_compute_instance.git?ref=main"
#   network_id     = module.vpc-dev.network_id 
#   subnet_zones   = ["ru-central1-a"]
#   subnet_ids     = [module.vpc-dev.subnet_id]
#   instance_name  = "srv-vm03"
#   env_name = "srv-vm03"
#   image_family   = "ubuntu-2404-lts"
#   public_ip      = true
#   security_group_ids = [
#   yandex_vpc_security_group.example.id 
#   ]
#    labels = { 
#      project = "srv-vm03"
#       }
#   metadata = {
#     user-data          = data.template_file.cloudinit.rendered #Для демонстрации №3
#     serial-port-enable = 1
#   }

# }

#Пример передачи cloud-config в ВМ.(передали путь к yml файлу и переменную!_ssh_public_key)
data "template_file" "cloudinit" {
 template = file("./cloud-init.yml")
   vars = {
     ssh_public_key = var.ssh_public_key
   }
}

