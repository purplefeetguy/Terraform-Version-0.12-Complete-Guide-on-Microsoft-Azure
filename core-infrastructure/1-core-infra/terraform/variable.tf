variable "prefix" {
  default = "pfl-tfvmex"
}

variable "location" {
  default = "North Central US"
}

variable "name_count" {
  default = ["server1", "server2", "server3"]
}

variable "machine_type" {
  type = map
  default = {
    "dev"  = "Standard_DS1_v2"
    "prod" = "Standard_DS2_v2"
  }
}
