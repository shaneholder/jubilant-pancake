resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

resource "azurerm_resource_group" "rg2" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id + "_xyzzy"
}
