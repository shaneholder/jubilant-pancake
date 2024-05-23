resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "random_string" "random" {
  length           = 8
  special          = false
}
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = format("%s_%s", random_pet.rg_name.id, var.environment)
}


resource "azurerm_resource_group" "rg2" {
  location = var.resource_group_location
  name     = format("%s_%s", "fred", var.environment)
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = format("%s_%s", random_string.random.id, var.environment)
}
