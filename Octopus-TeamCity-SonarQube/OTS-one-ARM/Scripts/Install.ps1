Param(
    [string] $sqlServerName,
    [string] $sqlDBName,
    [string] $sqlUsername,
    [string] $sqlPasswd,
    [string] $vmDnsName
)

$downloadDir = 'C:\Scripts'
$publicHtmlFolder = 'c:\inetpub\wwwroot\'
$serverXMLpath = 'C:\TeamCity\conf\server.xml'
$partOfXmlFilePath = 'C:\Scripts\Temps\partOfServer.xml'
$password = "dcom786" | convertto-securestring -asplaintext -force
Import-PfxCertificate -FilePath "C:\Scripts\build-digitalcommerce-volvocars-com.pfx" cert:\localMachine\my -Password $password
$certhash = (Get-ChildItem -path cert:\LocalMachine\My -DnsName "*volvocars*").Thumbprint
$nodeJSversion = 'v6.9.3'
$gitVersion = '2.16.2'
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$SecureStringPwd = ConvertTo-SecureString "P@ssW0rD!12" -AsPlainText -Force
New-LocalUser -Name "BuildUser" -Description "TeamCity Agent Account" -Password $SecureStringPwd -UserMayNotChangePassword -PasswordNeverExpires
mkdir "C:\Windows\system32\config\systemprofile\AppData\Local\Temp"
. "$downloadDir\Includes\Common.ps1"
. "$downloadDir\Includes\TeamCity.ps1"
. "$downloadDir\Includes\IIS.ps1"
. "$downloadDir\Includes\LogonAsService.ps1" "BuildUser"

Initialize-Path $downloadDir
Install-7Zip
Install-TeamCity
Install-Jre
Install-JDBC
Install-SubinAclMsi $downloadDir
Install-MSBuild $downloadDir
Install-NodeJs $nodeJSversion $downloadDir
Install-Git $gitVersion $downloadDir
Add-TeamCityDBCredetials $sqlServerName $sqlDBName $sqlUsername $sqlPasswd
Add-ToEndXML $serverXMLpath $partOfXmlFilePath
Start-TeamCity
Set-TeamCityUser 'teamcity.user' 'Alpaka44'
Install-IIS
Copy-WebConfig $downloadDir $publicHtmlFolder 
Install-UrlRewrite
Set-ReverseProxy $certhash
Set-FirewallRules
Get-BuildAgent $vmDnsName $downloadDir
Initialize-TeamCityAgent '3' $downloadDir $vmDnsName
#Start-Cleanup