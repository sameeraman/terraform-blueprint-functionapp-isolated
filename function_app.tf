
resource "azurerm_storage_account" "stg1" {
  name                     = "spfuncstg0825"
  resource_group_name      = module.rg1.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Disable public access to force traffic through private endpoint
  public_network_access_enabled = false



#   # Allow access from the Function App subnet
#   network_rules {
#     default_action             = "Deny"
#     virtual_network_subnet_ids = [
#       "/subscriptions/d52efbb5-d6ec-4788-adf1-735b0fd5d3e4/resourceGroups/cts-aue1-prd-rg-spoke1/providers/Microsoft.Network/virtualNetworks/cts-aue1-prd-vnet-spoke1/subnets/appservice"
#     ]
#   }
}

resource "azurerm_service_plan" "appsp1" {
  name                = "sp-func-app-service-plan"
  location            = var.location
  resource_group_name = module.rg1.name
  os_type             = "Linux"  # or "Windows" depending on your needs
  sku_name           = "P0v3"     # Changed from nested sku block
}

resource "azurerm_linux_function_app" "functionapp1" {
  name                       = "sp-func-app-235"
  location                   = var.location
  resource_group_name        = module.rg1.name
  service_plan_id           = azurerm_service_plan.appsp1.id  # Changed from app_service_plan_id
  storage_account_name       = azurerm_storage_account.stg1.name
  storage_account_access_key = azurerm_storage_account.stg1.primary_access_key

  # Disable public access
  public_network_access_enabled = false


  site_config {
    vnet_route_all_enabled = true
    always_on = true 
    # You may need to specify additional site_config settings like:
    # application_stack {
    #   python_version = "3.9"  # or your preferred Python version
    # }
        # .NET Core on Linux
    application_stack {
      dotnet_version =  "8.0"  # or "6.0" for .NET 6
      use_dotnet_isolated_runtime = true  # Use .NET isolated runtime, need isolated run time for dotnet core on linux
      # other settings
    }
  }

  # Configure app settings for private endpoints
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"               = "dotnet-isolated"  # Added missing setting
    "FUNCTIONS_EXTENSION_VERSION"            = "~4"  
    #"WEBSITE_CONTENTOVERVNET"                = "1"
    #"WEBSITE_VNET_ROUTE_ALL"                 = "1"
    #"WEBSITE_DNS_SERVER"                     = "168.63.129.16"
    #"WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.stg1.name};AccountKey=${azurerm_storage_account.stg1.primary_access_key};EndpointSuffix=core.windows.net"
  }

  depends_on = [
    azurerm_private_endpoint.storage_blob_pe,
    azurerm_private_endpoint.storage_file_pe,
    azurerm_private_endpoint.storage_table_pe,
    azurerm_private_endpoint.storage_queue_pe
  ]
}


# Private endpoint for Function App
resource "azurerm_private_endpoint" "functionapp_pe" {
  name                = "pe-${azurerm_linux_function_app.functionapp1.name}"
  location            = var.location
  resource_group_name = module.rg1.name
  subnet_id           = data.azurerm_subnet.vnet_private_endpoint_subnet.id

  private_service_connection {
    name                           = "psc-${azurerm_linux_function_app.functionapp1.name}"
    private_connection_resource_id = azurerm_linux_function_app.functionapp1.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "azurewebsites-dns-zone-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.azurewebsites.id]
  }
}

# VNet Integration of the app service to the existing VNet
resource "azurerm_app_service_virtual_network_swift_connection" "func_vnet_integration" {
  app_service_id = azurerm_linux_function_app.functionapp1.id
  subnet_id      = data.azurerm_subnet.vnet_appservice_subnet.id
}


# Reference existing private endpoint subnet from another project
data "azurerm_subnet" "vnet_private_endpoint_subnet" {
  name                 = var.vnet_private_endpoint_subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_rg_name
}

data "azurerm_subnet" "vnet_appservice_subnet" {
  name                 = var.vnet_appservice_subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_rg_name
}

# Reference existing DNS zones from another project
data "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.dns_resource_group_name
}

data "azurerm_private_dns_zone" "storage_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.dns_resource_group_name
}

data "azurerm_private_dns_zone" "storage_table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = var.dns_resource_group_name
}

data "azurerm_private_dns_zone" "storage_queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = var.dns_resource_group_name
}


data "azurerm_private_dns_zone" "azurewebsites" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.dns_resource_group_name
}

# Private endpoints using existing subnet
resource "azurerm_private_endpoint" "storage_blob_pe" {
  name                = "pe-${azurerm_storage_account.stg1.name}-blob"
  location            = var.location
  resource_group_name = module.rg1.name
  subnet_id           = data.azurerm_subnet.vnet_private_endpoint_subnet.id

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.stg1.name}-blob"
    private_connection_resource_id = azurerm_storage_account.stg1.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage_blob.id]
  }
}


resource "azurerm_private_endpoint" "storage_file_pe" {
  name                = "pe-${azurerm_storage_account.stg1.name}-file"
  location            = var.location
  resource_group_name = module.rg1.name
  subnet_id           = data.azurerm_subnet.vnet_private_endpoint_subnet.id

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.stg1.name}-file"
    private_connection_resource_id = azurerm_storage_account.stg1.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "file-dns-zone-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage_file.id]
  }
}


resource "azurerm_private_endpoint" "storage_table_pe" {
  name                = "pe-${azurerm_storage_account.stg1.name}-table"
  location            = var.location
  resource_group_name = module.rg1.name
  subnet_id           = data.azurerm_subnet.vnet_private_endpoint_subnet.id

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.stg1.name}-table"
    private_connection_resource_id = azurerm_storage_account.stg1.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "table-dns-zone-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage_table.id]
  }
}


resource "azurerm_private_endpoint" "storage_queue_pe" {
  name                = "pe-${azurerm_storage_account.stg1.name}-queue"
  location            = var.location
  resource_group_name = module.rg1.name
  subnet_id           = data.azurerm_subnet.vnet_private_endpoint_subnet.id

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.stg1.name}-queue"
    private_connection_resource_id = azurerm_storage_account.stg1.id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "queue-dns-zone-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage_queue.id]
  }
}