variable "flow" {
  type    = string
  default = "sdvps-mia"
}

variable "cloud_id" {
  type    = string
  default = "b1geap6dpsnun6sh70qj"
}
variable "folder_id" {
  type    = string
  default = "b1gfjo6em0ve76o982vg"
}

variable "registry_id" {
  type    = string
  default = "crp8m8obdkmolgsfc3oc"
}

variable "test" {
  type = map(number)
  default = {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }
}