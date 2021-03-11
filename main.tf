terraform {
  backend "azurerm" {
    resource_group_name = "NoBS"
    storage_account_name = "nobsstorageaccount"
    container_name = "tfstate"
    keyvault_name = "NOBS"
    key = "terraform.state"
  }
  required_providers {
    azurerm = {
      version = "2.0.0"
    }
  }
}

provider "azurerm" {
  version = "=2.0.0"
  features {}
}


data "azurerm_key_vault" "kv" {
  name                = var.resourceGroup
  resource_group_name = var.resourceGroup
}

data "azurerm_key_vault_secret" "keyVaultClientID" {
  name         = "AKSClientId"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "keyVaultClientSecret" {
  name         = "AKSClientSecret"
  key_vault_id = data.azurerm_key_vault.kv.id
}

resource "azurerm_kubernetes_cluster" "NoBSAKS" {
  name                = var.Name
  location            = var.location
  resource_group_name = var.resourceGroup
  dns_prefix          = "nobsprefix"

  default_node_pool {
    name = "default"
    node_count = 1
    vm_size = "Standard_D2_v2"
  }
  service_principal {
    client_id     = data.azurerm_key_vault_secret.keyVaultClientID.value
    client_secret = data.azurerm_key_vault_secret.keyVaultClientSecret.value
  }
}
