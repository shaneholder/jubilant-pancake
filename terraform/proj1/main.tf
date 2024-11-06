resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "random_pet" "rg_name2" {
  prefix = var.resource_group_name_prefix
}

resource "random_pet" "rg3" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = format("%s_%s", random_pet.rg_name.id, var.environment)
}

resource "azurerm_resource_group" "rg2" {
  location = var.resource_group_location
  name     = format("%s_%s", random_pet.rg_name2.id, var.environment)
}


resource "azurerm_resource_group" "rg-this" {
  location = var.resource_group_location
  name     = format("%s_%s", "fred", var.environment)
}

resource "azurerm_resource_group" "rg3" {
  location = var.resource_group_location
  name     = format("%s_%s", random_pet.rg3.id, var.environment)
}

# feature 1
# feature 2
# chore 1
# feature 3
# feature 4
# feature 5
# feature 6
# feature 7
# new feature
# new feature
# new feature
# new feature
# new feature
