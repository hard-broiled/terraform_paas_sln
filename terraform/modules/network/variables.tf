variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "vnet_name" {
  type    = string
  default = "vnet"
}

variable "address_space" {
  type    = list(string)
  default = ["10.1.0.0/16"]
}

variable "subnets" {
  type = map(object({
    address_prefix    = string
    service_endpoints = list(string)
    delegation = object({
      name         = string
      service_name = string
      actions      = list(string)
    })
  }))
  default = {
    web = {
      address_prefix    = "10.1.1.0/24"
      service_endpoints = []
      delegation        = null
    }
    app = {
      address_prefix = "10.1.2.0/24"
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.Sql",
        "Microsoft.KeyVault"
      ]
      delegation = {
        name         = "app-delegation"
        service_name = "Microsoft.Web/serverFarms"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action"
        ]
      }
    }
    db = {
      address_prefix    = "10.1.3.0/24"
      service_endpoints = []
      delegation        = null
    }
    privateendpoint = {
      address_prefix    = "10.1.4.0/24"
      service_endpoints = []
      delegation        = null
    }
  }
}

variable "private_dns_zones" {
  type = map(string)
  default = {
    sql     = "privatelink.database.windows.net"
    blob    = "privatelink.blob.core.windows.net"
    kv      = "privatelink.vaultcore.azure.net"
    web     = "privatelink.azurewebsites.net"
  }
}
