# Octopus installation and configuration

## To install and configure Octopus we must execute the following script with  `-UploadArtifacts` parameter. But, don't forget it must be called only from `deploy-menu.ps1` main script. The reason is `Login-AzureRmAccount` is not configured inside of `Deploy-AzureResourceGroup.ps1` script

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

When this file will be executed firstly it is going to create the Storage account and upload all files and folders to the Azure BLOB container. Then it will create a Virtual machine with DSC subresource, Azure SQL database, and PowerShell script extension resource. But, PowerShell script extension resource will wait until success deployment answer from Virtual machine with DSC and Azure SQL with the database. Virtual machine DSC resource copies scripts (`octopus-api-token-create.ps1` and `certconfigureoctohttps.ps1`) and certificate (`deploy-digitalcommerce-volvocars-com.pfx`) from Azure Storage container to the inside of the VM. Then PowerShell script extension executes `installoctopusdeploy.ps1` script with needed (Octopus admin username, password, SQL credentials) parameters. At the end of the execution `installoctopusdeploy.ps1` will be executed `octopus-api-token-create.ps1` and `certconfigureoctohttps.ps1` scripts with needed parameters.

## Explanation of the `installoctopusdeploy.ps1` - Octopus Installer PowerShell script

`installoctopusdeploy.ps1` - PowerShell script takes the following parameters to install and configure Octopus server

1. `$SqlDbConnectionString` - Azure SQL database connection (Username, Password, URL) string
2. `$LicenseFullName` - License name for Octopus server
3. `$LicenseOrganisationName` - License Organisation name for Octopus server
4. `$LicenseEmailAddress` - License email address for Octopus server
5. `$OctopusAdminUsername` - Administrator user name for Octopus web administration
6. `$OctopusAdminPassword` - Administrator user password for Octopus web administration
7. `$OctopusURI` - URI for octopus server
8. `$OctopusUsername` - Parameter will be used for `octopus-api-token-create.ps1` script
9. `$OctopusPassword` - Parameter will be used for `octopus-api-token-create.ps1` script

## Explanation of the `octopus-api-token-create.ps1` - Octopus API token creator PowerShell script

`octopus-api-token-create.ps1` - PowerShell script takes the following parameters to generate Octopus API token then, install/configure Tentacle agent and connect to the Octopus server.

1. `$OctopusURI` - DNS URI for Octopus server
2. `$OctopusUsername` - Octopus admin username
3. `$OctopusPassword` - Octopus admin username password

## Explanation of the  `certconfigureoctohttps.ps1` - HTTP to HTTPS rewrite PowerShell script

`certconfigureoctohttps.ps1` - PowerShell script takes only one parameter (Octopus DNS URL). It configure Octopus Manager server to listen in definaed DNS names and force rewrite HTTP traffic to the HTTPS.