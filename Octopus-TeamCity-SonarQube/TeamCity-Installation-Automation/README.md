# TeamCity installation and configuration

## To install and configure TeamCity we must execute the following script with  `-UploadArtifacts` parameter. But, don't forget it must be called only from `deploy-menu.ps1` main script. The reason is `Login-AzureRmAccount` is not configured inside of `Deploy-AzureResourceGroup.ps1` script

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

When this file will be executed firstly it is going to create the Storage account and upload all files and folders to the Azure BLOB container. Then it will create a Virtual machine with DSC subresource, Azure SQL database, and PowerShell script extension resource. Virtual Machine resource will wait until success deployment answer from Azure SQL with the database and Storage container. PowerShell script extension resource will wait until success deployment answer from Azure SQL with database and Virtual Machine. Virtual machine DSC resource copies scripts (`Install.ps1`, `IIS.ps1`, `Common.ps1`, `LogonAsService.ps1`, `TeamCity.ps1`), template files (`buildAgent.properties.template`, `partOfServer.xml`, `subinacl.msi`, `web.config`, `wrapper.conf.template`) and certificate (`build-digitalcommerce-volvocars-com.pfx`) from Azure Storage container to the inside of the VM. Then PowerShell script extension executes `Install.ps1` script with needed (SQL server URL, Database name, Username for SQL database, Paswsord for SQL database, Virtual Machine FQDN) parameters. At the end of the execution `Install.ps1` will be executed `Common.ps1`, `TeamCity.ps1`, `IIS.ps1` and `LogonAsService.ps1` (with OS system username as parameter) scripts.

## Explanation of the `Install.ps1` - TeamCity main PowerShell script

`Install.ps1` - PowerShell script takes the following parameters to install/configure TeamCity server and agents

1. `$sqlServerName` - Azure SQL server FQDN URL
2. `$sqlDBName` - Database name of Azure SQL server
3. `$sqlUsername` - Username of Azure SQL database
4. `$sqlPasswd` - Paswsord for Azure SQL database
5. `$vmDnsName` - Virtual Machine FQDN URL

After execution of the scripts inside of  the `Install.ps1` the script will call functions defined in these scrips.

## Explanation of the `Common.ps1` - Octopus API token creator PowerShell script

`Common.ps1` - PowerShell script contains functions which will be used from main `Install.ps1` and other scripts. Look at the following for explanation of this functions.

1. `Copy-WebConfig` - Copies `web.config` file to defined PATH. it is for IIS
2. `Initialize-Path` - Set source Scripts folder
3. `Receive-Item` - This function purpose is download something from Internet
4. `Expand-TarGz` - Function will be used to extract something from 'tar.gz'
5. `Install-7Zip` - Function install 7zip
6. `Install-SubinAclMsi` - Function install SubinACL msi package to the server
7. `Install-MSBuild` - Function install MSBuild package to the server
8. `Install-NodeJS` - Function install NodeJS to the server
9. `Install-Git` - Function install GIT to the server
10. `Get-BuildAgent` - Function download TeamCity build agent from server itself.
11. `Set-PremissionTcAgent` - Function gives permission for defined username to the folder where TeamCity build agent installed
12. `Initialize-TeamCityAgent` - Install and configure TeamCity Build agent with defined count of agents
13. `Start-Cleanup` - Remove everything which, used for the installation

## Explanation of the  `TeamCity.ps1` - Installation and configuration of TeamCity server PowerShell script

`TeamCity.ps1` - PowerShell script contains functions which, will donwload and install all needed components for TeamCity server.

1. `Install-Jre` - Function install and configure JRE server for the TeamCity server
2. `Install-TeamCity` - Function will download and extract TeamCity sevrer package
3. `Install-JDBC` - Function will download, extract and configure Java Database Connector
4. `Add-TeamCityDBCredetials` - Function configure Azure SQL database URL and credentials in the TeamCity database configuration file
5. `Add-ToEndXML` - Function append to `server.xml` from `partOfServer.xml` file. This will activate some HTTP headers which will be used in IIS
6. `Start-TeamCity` - Function will start TeamCity sevrer service
7. `Set-TeamCityUser` - Create TeamCity Administrator username and password with itself API

## Explanation of the  `IIS.ps1` - Installation and configuration of IIS server

`IIS.ps1` - PowerShell script contains functions which, will donwload and install all needed components for IIS server.

1. `Install-IIS` - Install IIS server with defined features
2. `Install-UrlRewrite` - Download and install URL rewrite packages for IIS server
3. `Set-ReverseProxy` - Configure Reverse proxy with HTTPS forwarding to defined certificate
4. `Set-FirewallRules` - Configure firewall rules to open ports `80` and `443`

## Explanation of the  `LogonAsService.ps1` - Installation and configuration of IIS server

`LogonAsService.ps1` - PowerShell script takes username argument which, will be granted access to be member of LogonAsService group.