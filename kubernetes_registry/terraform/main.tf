module "aks" {
  source  = "Azure/aks/azurerm"
  version = "2.0.0"

  CLIENT_ID     = "9ae1311f-d973-4f66-93a3-9d2e3d5a5977"
  CLIENT_SECRET = "77ebb707-45ba-4359-820d-4bdc0ddc2747"
  prefix        = "pfltfm"
}
