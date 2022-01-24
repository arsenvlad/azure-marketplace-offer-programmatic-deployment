provider "azurerm" {
   features {}
}

# Variables
variable "location" {
    type = string
}

variable "applicationResourceName" {
    type = string
}

variable "managedResourceGroupId" {
    type = string
}

variable "email" {
    type = string
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myterraformgroup"
    location = var.location
}

# Create ARM template deployment
resource "azurerm_resource_group_template_deployment" "arm_template" {
  name                = "terraform_arm_template"
  resource_group_name =  azurerm_resource_group.myterraformgroup.name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    "location" = {
      value = var.location
    },
    "applicationResourceName" = {
      value = var.applicationResourceName
    },
    "managedResourceGroupId" = {
      value = var.managedResourceGroupId
    },
    "email" = {
      value = var.email
    }
  })
  // Source ARM template from file in another folder
  template_content = file("../managedapp-arm/managedapp-arm.json")
}
