module "virtual_machine" {
  source = "../../virtual_machine"
  location = "UK WEST"
  prefix = "modulestestprefix"
}

module "virtual_machine_second" {
  source = "../../virtual_machine"  # GIT REPO 
  location = "UK WEST"
  prefix = "secondmachine"
}

module "database" {
  source = "../../database"
}
