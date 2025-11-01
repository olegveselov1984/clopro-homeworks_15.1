
variable "zone" {
  type        = string
}

variable "cidr" {
  type        = list(string)
}

variable "env_name_network" {
  type        = string
}

variable "env_name_subnet" {
  type        = string
}