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

variable "monitorName" {
    type = string
}

variable "firstName" {
    type = string
}

variable "lastName" {
    type = string
}

variable "companyName" {
    type = string
}

variable "emailAddress" {
    type = string
}

variable "domain" {
    type = string
}

variable "country" {
    type = string
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
    "monitorName" = {
      value = var.monitorName
    },
    "monitorLocation" = {
      value = var.location
    },
    "firstName" = {
      value = var.firstName
    },
    "lastName" = {
      value = var.lastName
    },
    "companyName" = {
      value = var.companyName
    },
    "emailAddress" = {
      value = var.emailAddress
    },
    "domain" = {
      value = var.domain
    },
    "country" = {
      value = var.country
    }
  })
  // Source ARM template from file in another folder
  template_content = file("../elasticsearch-arm/elasticsearch-arm.json")
}
