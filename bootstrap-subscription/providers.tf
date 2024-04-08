terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.86.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
  backend "azurerm" {
    use_oidc = true
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  use_oidc = true
}

provider "azuread" {
  use_oidc = true
}

provider "github" {

}