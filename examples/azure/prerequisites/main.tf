#####################
### Prerequisites ###
#####################

resource "azurerm_resource_group" "this" {
  name     = "rg-boot-dev-cc-00"
  location = local.azure_resource_attributes.location
  tags     = local.tags
}

# Identity used by Argo CD repo-server (workload identity / AVP → Key Vault).
resource "azurerm_user_assigned_identity" "argocd" {
  name                = "id-boot-argocd-dev-cc-00"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

##############################
### Virtual Network Module ###
##############################

module "virtual_network" {
  source = "git::https://github.com/gccloudone-aurora-iac/terraform-azure-virtual-network.git?ref=v2.0.1"

  naming_convention         = "oss"
  user_defined              = "bootstrap"
  azure_resource_attributes = local.azure_resource_attributes
  resource_group_name       = azurerm_resource_group.this.name

  address_space = ["10.0.0.0/16"]

  subnets = [
    {
      name             = "system"
      address_prefixes = ["10.0.0.0/22"]
    }
  ]

  tags = local.tags
}

##################
### AKS Cluster ##
##################

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-boot-dev-cc-00"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "boot-dev-cc-00"
  kubernetes_version    = "1.31"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name           = "system"
    vm_size        = "Standard_D2s_v3"
    node_count     = 2
    vnet_subnet_id = lookup(module.virtual_network.vnet_subnets_name_id, "system")
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }

  tags = local.tags
}

resource "azurerm_role_assignment" "aks_network" {
  scope                = module.virtual_network.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id
}
