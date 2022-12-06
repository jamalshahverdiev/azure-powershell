# All in one ARM template installation and configuration

## To install and configure all from one ARM template we need execute the following script with '-UploadArtifacts' parameter

```sh
Deploy-AzureResourceGroup.ps1 -UploadArtifacts
```

When `Deploy-AzureResourceGroup.ps1` script will be called, it will read parameters from inside. The important parameters `$ResourceGroupLocation`, `$ResourceGroupName`, `$TemplateFile`, `$TemplateParametersFile`.

## Explanation of the parameters

1. `$ResourceGroupLocation` - The deployment location in Azure datacenters
2. `$ResourceGroupName` - Group name under which all resources will be deployed
3. `$TemplateFile` - ARM template file which will be called from `Deploy-AzureResourceGroup.ps1` script
4. `$TemplateParametersFile` - Parameters file which will be used from ARM `$TemplateFile` file

## Explanation of the `$TemplateFile` - azuredeploy.json

When this file will be executed firstly it is going to create the Storage account and upload all files and folders to the Azure BLOB container. Then it will create the two Virtual machine with DSC subresource (TeamCity and Octopus), Azure SQL database with two databases, and two PowerShell script extension resource (Teamcity and Octopus). But, PowerShell script extension resources will wait until success deployment answer from Virtual machine with DSC and Azure SQL with the databases. If you want to understand installation and configuration in details for TeamCity, Octopus and SonarQube just read `README.md` files from their folders. The main difference only all resources in the same ARM template.