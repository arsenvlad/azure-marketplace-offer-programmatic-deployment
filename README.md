# Programmatic Deployment of Azure Marketplace Offers

This repo shows simple examples of how to programmatically deploy various offer types from Azure Marketplace.

## Table of Contents

* [Elasticsearch SaaS from Azure Marketplace](#elasticsearch-saas-from-azure-marketplace)
* [Virtual Machine from Azure Marketplace](#virtual-machine-from-azure-marketplace)
* [SaaS Offer from Azure Marketplace](#saas-offer-from-azure-marketplace)
* [Azure Managed Application from Azure Marketplace](#azure-managed-application-from-azure-marketplace)
* [Solution Template from Azure Marketplace](#solution-template-from-azure-marketplace)

## Elasticsearch SaaS from Azure Marketplace

[Elasticsearch](https://azuremarketplace.microsoft.com/marketplace/apps/elastic.ec-azure-pp) is a special type of `SaaS offer` that is available as an Azure Resource Manager type `Microsoft.Elastic/monitors`. Therefore, it can be deployed using regular ARM or Bicep templates. As of January 2022, Terraform provider and Azure CLI support are not yet available, but Terraform [azurerm_resource_group_template_deployment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) can be used to deploy an ARM template.

### Deploy Elasticsearch using ARM template and Azure CLI

ARM template example [elasticsearch-arm/elasticsearch-arm.json](elasticsearch-arm/elasticsearch-arm.json):

```bash
az group create --resource-group avelastic100 --location eastus2

az deployment group create --resource-group avelastic100 --template-file elasticsearch-arm/elasticsearch-arm.json --parameters monitorName=avelastic100 monitorLocation=eastus2 firstName=MyFirstName lastName=MyLastName companyName=MyCompany emailAddress=myemail@mycompany.com domain=mycompany.com country=US
```

Since Elasticsearch is a 3rd party paid offering, Azure subscription must be associated with a valid payment method and cannot be free or sponsored subscription. If there is no valid payment method on the Azure subscription, the deployment will fail with the following type of error:

```jsonc
{"status":"Failed","error":{"code":"DeploymentFailed","message":"At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/DeployOperations for usage details.","details":[{"code":"BadRequest","message":"{\r\n  \"error\": {\r\n    \"code\": \"BadRequest\",\r\n    \"message\": \"{\\\"message\\\":\\\"Purchase 
has failed because we couldn't find a valid credit card nor a payment method associated with your Azure subscription. Please use a different Azure subscription or add\\\\\\\\update current credit card or payment method for this subscription and retry.\\\",\\\"code\\\":\\\"BadRequest\\\"}\"\r\n  }\r\n}"}]}}
```

### Deploy Elasticsearch using Terraform invoking an ARM template

Terraform example [elasticsearch-terraform/main.tf](elasticsearch-terraform/main.tf):

```bash
cd elasticsearch-terraform
terraform init
terraform apply -var "location=eastus2" -var "rgName=avelastic100" -var "monitorName=avelastic100" -var "firstName=MyFirstName" -var "lastName=MyLastName" -var "companyName=MyCompany" -var "emailAddress=myemail@mycompany.com" -var "domain=mycompany.com" -var "country=US"
```

## Virtual Machine from Azure Marketplace

### Accept VM Offer Terms

In order to deploy 3rd party VMs from Azure Marketplace, you need to first accept the End User License Agreement (EULA) for the VM image that is being deployed. Once the EULA is accepted one time in an Azure subscription, you should be able to deploy the same VM offer again without needing to accept the terms again. If you are deploying the VM from Azure Portal, the terms are accepted there. However, when you do the deployment programmatically, you need to accept the terms using the `az vm image terms accept --publisher X --offer Y --plan Z` or by using ARM REST APIs as described [here](https://arsenvlad.medium.com/azure-marketplace-api-to-programmatically-review-and-accept-publisher-agreement-eula-3066a6c143dd).

If the terms are not yet accepted, the following error will be shown:

```jsonc
{"error":{"code":"MarketplacePurchaseEligibilityFailed","message":"Marketplace purchase eligibilty check returned errors. See inner errors for details. ","details":[{"code":"BadRequest","message":"Offer with PublisherId: 'barracudanetworks', OfferId: 'waf' cannot be purchased due to validation errors. For more information see details. Correlation Id: 'a7779729-3814-4461-a919-8b5d388dac77' You have not accepted the legal terms on this subscription: 'c9c8ae57-acdb-48a9-99f8-d57704f18dee' for this plan. Before the subscription can be used, you need to accept the legal terms of the image. To read and accept legal terms, use the Azure CLI commands described at https://go.microsoft.com/fwlink/?linkid=2110637 or the PowerShell commands available at https://go.microsoft.com/fwlink/?linkid=862451. Alternatively, deploying via the Azure portal provides a UI experience for reading and accepting the legal terms. Offer details: publisher='barracudanetworks' offer = 'waf', sku = 'byol', Correlation Id: 'a7779729-3814-4461-a919-8b5d388dac77'.[{\"You have not accepted the legal terms on this subscription: 'c9c8ae57-acdb-48a9-99f8-d57704f18dee' for this plan. Before the subscription can be used, you need to accept the legal terms of the image. To read and accept legal terms, use the Azure CLI commands described at https://go.microsoft.com/fwlink/?linkid=2110637 or the PowerShell commands available at https://go.microsoft.com/fwlink/?linkid=862451. Alternatively, deploying via the Azure portal provides a UI experience for reading and accepting the legal terms. Offer details: publisher='barracudanetworks' offer = 'waf', sku = 'byol', Correlation Id: 'a7779729-3814-4461-a919-8b5d388dac77'.\":\"StoreApi\"}]"}]}}
```

VM offer terms can be accepted as follows using Azure CLI:

```bash
# Accept terms
az vm image terms accept --publisher barracudanetworks --offer waf --plan byol

# Review that terms were accepted (i.e., accepted=true)
az vm image terms show --publisher barracudanetworks --offer waf --plan byol -o json
```

### Deploy VM from Azure Marketplace using Azure CLI

Once the terms are accepted, you can deploy the VM using the regular methods such as ARM/Bicep template, Azure CLI, Terraform, etc. The key requirement for 3rd party VM images is to specify the **[plan](https://docs.microsoft.com/rest/api/compute/virtual-machines/create-or-update#plan)** properties for the VM.

```bash
az group create --resource-group avvm100 --location eastus2

az vm create --resource-group avvm100 --location eastus2 --name avvm100 --image barracudanetworks:waf:byol:latest --plan-publisher barracudanetworks --plan-product waf --plan-name byol --public-ip-sku Standard
```

### Deploy VM from Azure Marketplace using Terraform

When using Terraform, VM offer terms can be accepted using [azurerm_marketplace_agreement](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement).

Specify `plan` block in the [azurerm_virtual_machine](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine) provider.

If the plan block is not specified, the deployment will fail with the following error:

```text
Code="VMMarketplaceInvalidInput" Message="Creating a virtual machine from Marketplace image or a custom image sourced from a Marketplace image requires Plan information in the request. VM: '/subscriptions/c9c8ae57-acdb-48a9-99f8-d57704f18dee/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM'.
```

Terraform example [vm-terraform/main.tf](vm-terraform/main.tf):

```bash
cd vm-terraform
terraform init
terraform apply -var "location=eastus2" -var "rgName=avvm100"
```

## SaaS Offer from Azure Marketplace

SaaS Offers are usually deployed by customers via the Azure Portal. After the SaaS offer is deployed using Azure Portal, the customer uses the "Configure account now" button to visit the SaaS ISV's landing page and finish configuring the SaaS offer. After the offer is configured, the SaaS ISV activates it using [SaaS Fulfillment API](https://docs.microsoft.com/azure/marketplace/partner-center-portal/pc-saas-fulfillment-life-cycle).

Azure Portal generates an ARM template and specific parameter values for the SaaS offer deployment. The ARM template uses the resource type `Microsoft.SaaS/resources` to create the offer and requires very specific opaque values for parameters like termId. In order to know the proper value to use for termId, you would have to first deploy the offer **manually via Azure Portal**, visit its resource group deployment blade, and look for the values of the input parameters that were generated.

If a given SaaS offer was never deployed in the Azure subscription, the programmatic deployment will fail with an error like the following:

```jsonc
{"status":"Failed","error":{"code":"DeploymentFailed","message":"At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/DeployOperations for usage details.","details":[{"code":"BadRequest","message":"{\r\n  \"error\": {\r\n    \"code\": \"BadRequest\",\r\n    \"message\": \"Failed to process eligibility check with error Purchase has failed due to signature verification on Marketplace legal agreement. Please retry. If error persists use different Azure subscription, or contact support with correlation-id 'beac5707-71cd-4082-9a8c-e3ecbc1385c0' and this error message..\"\r\n  }\r\n}"}]}}
```

### Deploy SaaS offer using ARM template and Azure CLI

ARM template example [saas-arm/saas-arm.json](saas-arm/saas-arm.json):

```bash
az group create --resource-group avsaas100 --location eastus2

az deployment group create --resource-group avsaas100 --template-file saas-arm/saas-arm.json --parameters name=avsaas100 publisherId=neo4j offerId=neo4j-enterprise-saas planId=neo4j-30-day-trial termId=ccdjsqgba7zo quantity=1 azureSubscriptionId=c9c8ae57-acdb-48a9-99f8-d57704f18dee autoRenew=true
```

After the SaaS offer resource is provisioned, you can invoke the following ARM API to view its properties:

```bash
az rest --method get --uri /subscriptions/c9c8ae57-acdb-48a9-99f8-d57704f18dee/resourceGroups/avsaas100/providers/Microsoft.SaaS/resources/avsaas100?api-version=2018-03-01-beta -o json
```

Output looks like this

```json
{
  "id": "/subscriptions/c9c8ae57-acdb-48a9-99f8-d57704f18dee/resourceGroups/avsaas100/providers/Microsoft.SaaS/resources/avsaas100",
  "location": "global",
  "name": "avsaas100",
  "properties": {
    "additionalInfo": null,
    "autoRenew": true,
    "created": "2022-01-24T20:23:19.0268958Z",
    "cspProperties": null,
    "isFreeTrial": true,
    "lastModified": "2022-01-24T20:23:21.9721121Z",
    "market": "US",
    "offerId": "neo4j-enterprise-saas",
    "orderId": null,
    "paymentChannelMetadata": {
      "azureSubscriptionId": "c9c8ae57-acdb-48a9-99f8-d57704f18dee"
    },
    "paymentChannelType": "SubscriptionDelegated",
    "publisherId": "neo4j",
    "publisherTestEnvironment": null,
    "quantity": null,
    "saasResourceName": "avsaas100",
    "saasSubscriptionId": "767f03d3-431b-42d5-cd5d-4292afb249a3",
    "skuId": "neo4j-30-day-trial",
    "status": "PendingFulfillmentStart",
    "statusReason": "None",
    "storeFront": "AzurePortal",
    "term": {
      "endDate": "2022-02-23T00:00:00Z",
      "startDate": "2022-01-24T00:00:00Z",
      "termId": null,
      "termUnit": "P1M"
    },
    "termId": "ccdjsqgba7zo"
  },
  "resourceGroup": "avsaas100",
  "tags": null,
  "type": "Microsoft.SaaS/resources"
}
```

Based on the Swagger [specification of the Microsoft.SaaS resource provider](https://github.com/Azure/azure-rest-api-specs/tree/main/specification/saas/resource-manager/Microsoft.SaaS/preview/2018-03-01-beta), you can make a POST call to get the marketplace token and landing page URL. This URL can be used to browse to the SaaS ISV's landing page to finish configuring and activating the SaaS offer.

```bash
az rest --method post --uri /subscriptions/c9c8ae57-acdb-48a9-99f8-d57704f18dee/resourceGroups/avsaas100/providers/Microsoft.SaaS/resources/avsaas100/listAccessToken?api-version=2018-03-01-beta -o json
```

```json
{
  "expiryTime": "2022-01-25T20:24:18.7991013Z",
  "offerUriWithToken": "https://upstream-api.tackle.io/v1/azure/order/KCVBE0T?token=A0rx0llebSxpuREs%2fEruALeEn%2bkq1oER...",
  "publisherOfferBaseUri": "https://upstream-api.tackle.io/v1/azure/order/KCVBE0T",
  "token": "A0rx0llebSxpuREs/EruALeEn+kq1oER/icsJlc/EsSJW1nSpyhWqR..."
}
```

### Deploy SaaS offer from Azure Marketplace using Terraform

Please review the section above describing how to deploy SaaS offer using ARM since Terraform deployment would use the same ARM template.

Terraform example [saas-terraform/main.tf](saas-terraform/main.tf):

```bash
cd saas-terraform
terraform init
terraform apply -var "location=eastus2" -var "rgName=avsaas100" -var "name=avsaas100" -var "planId=neo4j-30-day-trial" -var "offerId=neo4j-enterprise-saas" -var "publisherId=neo4j" -var "quantity=1" -var "termId=ccdjsqgba7zo" -var "azureSubscriptionId=c9c8ae57-acdb-48a9-99f8-d57704f18dee" -var "autoRenew=true"
```

## Azure Managed Application from Azure Marketplace

Azure Portal generates an ARM template for Azure Managed Application deployment. This ARM template creates a resource of type `Microsoft.Solutions/applications` which points to a specific `plan` and passes in the application-specific parameters from the UI fields that the customer fills out in Azure Portal.

### Accept Azure Managed App Terms

Similar to Virtual Machine offer, in order to deploy the Azure Managed Application programmatically using the ARM template into an Azure subscription, the subscription needs to accept the terms for the `plan` of the Azure Managed App. When deployed via the Azure Portal, the terms acceptance happens implicitly and subsequent programmatic deployments of the same plan in the same Azure subscription work without issues. It is also possible to accept the terms of an Azure Managed App offer using the same `az vm image terms accept` as described above in the VM section.

```bash
# Show terms for Azure Managed App
az vm image terms show --publisher hashicorp-4665790 --offer hcs-production --plan on-demand-v2 -o json

# Unaccept (i.e., cancel terms)
az vm image terms cancel --publisher hashicorp-4665790 --offer hcs-production --plan on-demand-v2 -o json

# Accept terms
az vm image terms accept --publisher hashicorp-4665790 --offer hcs-production --plan on-demand-v2 -o json
```

If Azure Managed Application is "paid" (i.e., uses monthly or metered billing), the Azure subscription that you use to deploy it must be associated with a valid payment method (i.e., cannot be a free or sponsored subscription).

### Deploy Azure Managed Application using ARM template and Azure CLI

ARM template example [managedapp-arm/managedapp-arm.json](managedapp-arm/managedapp-arm.json):

```bash
az group create --resource-group avmanagedapp100 --location eastus2

az deployment group create --resource-group avmanagedapp100 --template-file managedapp-arm/managedapp-arm.json --parameters location=eastus2 applicationResourceName=avmanagedapp100 managedResourceGroupId=/subscriptions/c9c8ae57-acdb-48a9-99f8-d57704f18dee/resourceGroups/avmanagedapp100-mrg email=myemail@mycompany.com
```

### Deploy Azure Managed App from Azure Marketplace using Terraform

Please review the section above describing how to deploy Azure Managed App offer using ARM since Terraform deployment would use the same ARM template.

Terraform example [managedapp-terraform/main.tf](managedapp-terraform/main.tf):

```bash
cd managedapp-terraform
terraform init
terraform apply -var "location=eastus2" -var "managedResourceGroupId=/subscriptions/c9c8ae57-acdb-48a9-99f8-d57704f18dee/resourceGroups/avmanagedapp100-mrg" -var "applicationResourceName=avmanagedapp100" -var "email=myemail@mycompany.com"
```

## Solution Template from Azure Marketplace

When deploying **Solution Template** (not Azure Managed App) offers from Azure Marketplace, the deployment is simply the ARM template that the ISV published with the corresponding UI fields passed as parameters. To deploy solution template offer programmatically, use Azure Portal to do the deployment, copy the ARM template, and use it in the subsequent deployments. Since Solution Templates are not "paid" offers, there are no special terms that need to be accepted. However, if Solution Template ARM template is referring to an VM image from Azure Marketplace, you will need to first accept the terms of the VM offer as described in the VM offer section.
