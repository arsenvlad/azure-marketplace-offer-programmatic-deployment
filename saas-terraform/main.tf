provider "azurerm" {
   features {}
}

# Variables
variable "location" {
    type = string
}

variable "rgName" {
    type = string
}

variable "name" {
    type = string
}

variable "planId" {
    type = string
}

variable "offerId" {
    type = string
}

variable "publisherId" {
    type = string
}

variable "quantity" {
    type = number
}

variable "termId" {
    type = string
}

variable "azureSubscriptionId" {
    type = string
}

variable "publisherTestEnvironment" {
    type = string
    default = ""
}

variable "autoRenew" {
    type = bool
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = var.rgName
    location = var.location
}

# Create ARM template deployment
resource "azurerm_resource_group_template_deployment" "arm_template" {
  name                = "terraform_arm_template"
  resource_group_name =  azurerm_resource_group.myterraformgroup.name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    "name" = {
      value = var.name
    },
    "publisherId" = {
      value = var.publisherId
    },
    "offerId" = {
      value = var.offerId
    },
    "planId" = {
      value = var.planId
    },
    "termId" = {
      value = var.termId
    },
    "quantity" = {
      value = var.quantity
    },
    "azureSubscriptionId" = {
      value = var.azureSubscriptionId
    },
    "autoRenew" = {
      value = var.autoRenew
    }
  })
  // Source ARM template from file in another folder
  template_content = file("../saas-arm/saas-arm.json")
}
