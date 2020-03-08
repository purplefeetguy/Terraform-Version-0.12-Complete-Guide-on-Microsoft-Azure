variable "prefix" {
  default = "pfl-tfvmex"
}

variable "location" {
  default = "North Central US"
}

variable "name_count" {
  default = ["server1", "server2", "server3"]
}

variable "machine_type_PROD" {
  default = "Standard_DS2_v2"
}

variable "machine_type_DEV" {
  default = "Standard_DS1_v2"
}

variable "environment" {
  default = "production"
}
