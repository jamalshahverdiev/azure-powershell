param(
 [string] $subscriptionId,
 [string] $resourceGroupLocation = 'westeurope',
 [string] $deploymentName = 'SonarDeploy',
 [string] $templateFilePath = ("{0}\{1}" -f "$PSScriptRoot", "azuredeploy.json"),
 [string] $parametersFilePath = ("{0}\{1}" -f "$PSScriptRoot", "azuredeploy.parameters.json")
)

Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"
$JSON = Get-Content $parametersFilePath | Out-String | ConvertFrom-Json
$resourceGroupName = $JSON.parameters.rgName.value
$linuxVMName = $JSON.parameters.virtualMachineName.value
$sonaradmin = $JSON.parameters.adminUsername.value
$sqFQDN = ("{0}.{1}.{2}" -f $JSON.parameters.networkDnsName.value, $resourceGroupLocation, 'cloudapp.azure.com')
$keyCerts = ("{0}\{1}" -f "$PSScriptRoot", '.\KeyCerts\id_rsa')

# sign in
Write-Host "Logging in...";

# select subscription
Write-Host "Selecting subscription '$subscriptionId'";
Select-AzureRmSubscription -SubscriptionID $subscriptionId;

# Register RPs
$resourceProviders = @("microsoft.compute","microsoft.storage","microsoft.network");
if($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if(!$resourceGroupLocation) {
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

# Start the deployment
Write-Host "Starting deployment...";
if(Test-Path $parametersFilePath) {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath;
} else {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath;
}

Start-Sleep -s 60
Get-AzureRmVMBootDiagnosticsData -ResourceGroupName $resourceGroupName -Name $linuxVMName -Linux | Out-File ("{0}\{1}" -f "$PSScriptRoot", 'diaglogs.txt')
$adminMySQLpass= (Get-Content ("{0}\{1}" -f "$PSScriptRoot", 'diaglogs.txt') | Select-String -Pattern 'application password' -CaseSensitive | ForEach-Object{($_ -split "'")[1]})
Remove-Item ("{0}\{1}" -f "$PSScriptRoot", 'diaglogs.txt')
Write-Host "SonarQube MySQL root and web Admin passsword:" $adminMySQLpass 
"SonarQube MySQL root and web Admin passsword: $adminMySQLpass" >  ("{0}\{1}" -f "$PSScriptRoot", 'mysqlRootwebAdminPass.txt')

$mycreds = New-Object System.Management.Automation.PSCredential ("$sonaradmin", (new-object System.Security.SecureString))
New-SSHSession -ComputerName $sqFQDN -Credential $mycreds -KeyFile $keyCerts -Force
Set-SCPFolder -LocalFolder ("{0}\{1}" -f "$PSScriptRoot", 'KeyCerts\') -RemoteFolder "/home/$sonaradmin/" -ComputerName $sqFQDN -Credential $mycreds -KeyFile $keyCerts -Force
Invoke-SSHCommand -Index 0 -Command "sudo chmod 777 code.sh && /home/$sonaradmin/code.sh $sonaradmin" -TimeOut 130