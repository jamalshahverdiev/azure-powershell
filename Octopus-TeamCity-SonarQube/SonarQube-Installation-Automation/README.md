# SonarQube installation and configuration

## To install and configure SonarQube we must execute the following script with  `-subscrID` parameter. But, don't forget it must be called only from `deploy-menu.ps1` main script. The reason is `Login-AzureRmAccount` is not configured inside of `deploy.ps1` script

```sh
deploy.ps1 -subscriptionId $subscrID
```

When `deploy.ps1` script will be called, it will read parameters from inside. The important parameters `$subscriptionId`, `$resourceGroupLocation`, `$templateFilePath`, `$parametersFilePath`.

## Explanation of the important parameters

1. `$subscriptionId` - The subscriptionID where will be deployed SonarQube
2. `$resourceGroupLocation` - Azure datacenter location where will be deployed all resources
3. `$templateFilePath` - ARM template file
4. `$parametersFilePath` - Parameters file which will be used from ARM `$templateFilePath` file

## Explanation of the `$templateFilePath` - azuredeploy.json

When this file will be executed firstly it is going to create new Ubuntu 16.04 LTS Linux machine from predfined image of SonarQube Bitnami. Don't forget to change your SSH public key inside of the `azuredeploy.parameters.json` file which, is defined as `adminPublicKey` variable. The private key of this public key will be used to connect to the Linux machine over SSH. Resource group, Linux username and SonarQube application username also defined in the `azuredeploy.parameters.json` file. SonarQube FQDN is defined in the `deploy.ps1` script as `$sqFQDN` variable.

## Explanation of the `deploy.ps1`

`deploy.ps1` - SonarQube Installer PowerShell script will call `azuredeploy.json` template and deploy it in Azure. Then it will read Azure diagnostics logs to get Linux MySQL `root` and appication `password` (default application username: `admin`). MySQL `root` and application `password` wil be written in the `mysqlRootwebAdminPass.txt` file. After that it will upload local content of the `KeyCerts` folder to the Linux user home folder and execute `code.sh` script with username parameter.

## Explanation of the `code.sh` script file

`code.sh` - Script takes argument which, is username. This Linux user already used via PoSH-SSH to upload `KeyCerts` folder with content and execute `code.sh` script file. Script copies `server.crt` and `server.key` files to the `/opt/bitnami/apache2/conf/` folder. Then script will change `/opt/bitnami/apache2/conf/bitnami/bitnami.conf` to redirect HTTP traffic to the HTTPS. At the end it will restart all services.

Note: To use these scripts, you need ssh access to the public.

To use SSH commands we need to install new module with name `PoSH-SSH` to our desktop environment (It is for SSH and SCP):

```sh
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")
```

Execute the following command from RUNAS(Administrator) powershell console just, to be sure everything installed successful:

```sh
Get-Command -Module Posh-SSH
Find-Module Posh-SSH | Install-Module -Scope CurrentUser
```

If you can execute some command in the remote Linux server, just execute the following commands (`$sonaradmin` - username of Linux, `$keyCerts` - private key file to connect with SSH, `$sqFQDN` - Linux server FQDN):

```sh
$mycreds = New-Object System.Management.Automation.PSCredential ("$sonaradmin", (new-object System.Security.SecureString))
New-SSHSession -ComputerName $sqFQDN -Credential $mycreds -KeyFile $keyCerts -Force
Invoke-SSHCommand -Index 0 -Command "df -h"
```

Download file from Linux server to my Desktop:

```sh
Get-SCPFile -LocalFile .\bitnami_sonarqube.sql -RemoteFile "/home/sonaradmin/bitnami_sonarqube.sql" -ComputerName $sqFQDN -Credential $mycreds -KeyFile $keyCerts -Force
```

Upload local 'upload.txt' file to the remote /home/sonaradmin/ folder:

```sh
Set-SCPFile -LocalFile .\upload.txt -RemotePath "/home/$sonaradmin/" -ComputerName $sqFQDN -Credential $mycreds -KeyFile $keyCerts -Force
```

Upload local folder `KeyCerts` to the remote username home folder:

```sh
Set-SCPFolder -LocalFolder .\KeyCerts\ -RemoteFolder "/home/$sonaradmin/" -ComputerName $sqFQDN -Credential $mycreds -KeyFile $keyCerts -Force
```

Convert PFX to PEM with PowerShell script:

```sh
.\PfxToPem.ps1 -PFXFile .\KeyCerts\quality-digitalcommerce-volvocars-com.pfx -Passphrase 'pass-for-certificate' -PEMFile .\KeyCerts\qd-vvo-com.pem
```

Convert PFX to PEM with OpenSSL:

```sh
openssl pkcs12 -in quality-digitalcommerce-volvocars-com.pfx -nocerts -out server-encrypted.key
openssl pkcs12 -in quality-digitalcommerce-volvocars-com.pfx -clcerts -nokeys -out server.crt
openssl rsa -in server-encrypted.key -out server.key
```

Script usage:

```sh
.\deploy.ps1 -subscriptionId 7999e5e8-222a-46c5-b26f-5d7191b4e5b6 -resourceGroupLocation westeurope -deploymentName sqDep
```