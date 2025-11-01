# Домашнее задание к занятию «Организация сети»

### Подготовка к выполнению задания

1. Домашнее задание состоит из обязательной части, которую нужно выполнить на провайдере Yandex Cloud, и дополнительной части в AWS (выполняется по желанию). 
2. Все домашние задания в блоке 15 связаны друг с другом и в конце представляют пример законченной инфраструктуры.  
3. Все задания нужно выполнить с помощью Terraform. Результатом выполненного домашнего задания будет код в репозитории. 
4. Перед началом работы настройте доступ к облачным ресурсам из Terraform, используя материалы прошлых лекций и домашнее задание по теме «Облачные провайдеры и синтаксис Terraform». Заранее выберите регион (в случае AWS) и зону.

---
### Задание 1. Yandex Cloud 

**Что нужно сделать**

1. Создать пустую VPC. Выбрать зону.
2. Публичная подсеть.

 - Создать в VPC subnet с названием public, сетью 192.168.10.0/24.
 - Создать в этой подсети NAT-инстанс, присвоив ему адрес 192.168.10.254. В качестве image_id использовать fd80mrhj8fl2oe87o4e1.
 - Создать в этой публичной подсети виртуалку с публичным IP, подключиться к ней и убедиться, что есть доступ к интернету.

main.tf
```
module "vpc-dev" { #название модуля
  source       = "./vpc-dev" 
  env_name_network = "VPC" #параметры которые передаем
  env_name_subnet  = "public" #параметры которые передаем
  zone = "ru-central1-a"
  cidr = ["192.168.10.0/24"]
}

resource "yandex_vpc_route_table" "private_routes" {  #создание роутера (NAT-инстанс)
  name       = "private-route-table"
  network_id = module.vpc-dev.network_id   #yandex_vpc_network.default.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
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

#Пример передачи cloud-config в ВМ.(передали путь к yml файлу и переменную!_ssh_public_key)
data "template_file" "cloudinit" {
 template = file("./cloud-init.yml")
   vars = {
     ssh_public_key = var.ssh_public_key
   }
}


```


<img width="2373" height="188" alt="image" src="https://github.com/user-attachments/assets/f277504c-e5c4-4fd6-81b7-9ebe62665a14" />

<img width="1607" height="439" alt="image" src="https://github.com/user-attachments/assets/0f376734-0296-4200-bd15-5ec4408dd4b5" />

<img width="760" height="813" alt="image" src="https://github.com/user-attachments/assets/26e8d173-cc30-4be1-bf0e-2a183d2a9ecb" />




3. Приватная подсеть.
 - Создать в VPC subnet с названием private, сетью 192.168.20.0/24.
 - Создать route table. Добавить статический маршрут, направляющий весь исходящий трафик private сети в NAT-инстанс.
 - Создать в этой приватной подсети виртуалку с внутренним IP, подключиться к ней через виртуалку, созданную ранее, и убедиться, что есть доступ к интернету.

main.tf
```
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

resource "yandex_vpc_route_table" "private_routes" {  #создание NAT)
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
###################### Раздел для настройки iptables. В моем случае ен нужен. У меня образ с NAT
#    user-data = <<EOF
##cloud-config
#users:
#  - name: ${var.ssh_user}
#    groups: sudo
#    shell: /bin/bash
#    sudo: 'ALL=(ALL) NOPASSWD:ALL'
#    ssh_authorized_keys:
#      - ${file("${var.ssh_public_key}")}
#
#runcmd:
#  - sysctl -w net.ipv4.ip_forward=1
#  - iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
#EOF
#######################
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

#Пример передачи cloud-config в ВМ.(передали путь к yml файлу и переменную!_ssh_public_key)
data "template_file" "cloudinit" {
 template = file("./cloud-init.yml")
   vars = {
     ssh_public_key = var.ssh_public_key
   }
}

```

<img width="1351" height="335" alt="image" src="https://github.com/user-attachments/assets/9f263b5c-2d31-4aa6-a94a-43a09a33f3a1" />  

ssh -J ubuntu@51.250.67.91 ubuntu@192.168.20.17  

<img width="914" height="770" alt="image" src="https://github.com/user-attachments/assets/e3555413-c984-4057-a0e0-8d83ea50cfe6" />




Resource Terraform для Yandex Cloud:

- [VPC subnet](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_subnet).
- [Route table](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_route_table).
- [Compute Instance](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_instance).

---
### Задание 2. AWS* (задание со звёздочкой)

Это необязательное задание. Его выполнение не влияет на получение зачёта по домашней работе.

**Что нужно сделать**

1. Создать пустую VPC с подсетью 10.10.0.0/16.
2. Публичная подсеть.

 - Создать в VPC subnet с названием public, сетью 10.10.1.0/24.
 - Разрешить в этой subnet присвоение public IP по-умолчанию.
 - Создать Internet gateway.
 - Добавить в таблицу маршрутизации маршрут, направляющий весь исходящий трафик в Internet gateway.
 - Создать security group с разрешающими правилами на SSH и ICMP. Привязать эту security group на все, создаваемые в этом ДЗ, виртуалки.
 - Создать в этой подсети виртуалку и убедиться, что инстанс имеет публичный IP. Подключиться к ней, убедиться, что есть доступ к интернету.
 - Добавить NAT gateway в public subnet.
3. Приватная подсеть.
 - Создать в VPC subnet с названием private, сетью 10.10.2.0/24.
 - Создать отдельную таблицу маршрутизации и привязать её к private подсети.
 - Добавить Route, направляющий весь исходящий трафик private сети в NAT.
 - Создать виртуалку в приватной сети.
 - Подключиться к ней по SSH по приватному IP через виртуалку, созданную ранее в публичной подсети, и убедиться, что с виртуалки есть выход в интернет.

Resource Terraform:

1. [VPC](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc).
1. [Subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet).
1. [Internet Gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway).

### Правила приёма работы

Домашняя работа оформляется в своём Git репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
Файл README.md должен содержать скриншоты вывода необходимых команд, а также скриншоты результатов.
Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.
