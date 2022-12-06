# From Setup-Roles.ps1
[array]$xmlarray = 0..2
[array]$ziparray = 0..3
[array]$extrarray = 0..1
$randomPass='0_MVyu6tuygjdbehmsjhfIU.76tygfhjKdsfiuvsdghdkj90irgrjeoifvuhjIUIUolkvjc'
$zipFilesPath = @("C:\Software\sitecorenew.zip", "C:\Software\sitecoreold.zip", "C:\Software\unicorn.zip", "C:\Software\Install-Cultures.zip")
$localPath = 'C:\Software\'
$stcores = @("C:\inetpub\sitecorenew", "C:\inetpub\sitecoreold")
$dataConfigFolder = '\Website\App_Config\Include\'
$kamsarDLLps = @('MicroCHAP.dll', 'Unicorn.psm1')
$githubURL = 'https://raw.githubusercontent.com/kamsar/Unicorn/master/doc/PowerShell Remote Scripting/'
$psremoteConfigFiles = @('makecert.exe', 'ConfigureWinRM.ps1')
$psremoteGitUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-winrm-windows/'
$extractPaths = @("C:\Software\sitecorenew\", "C:\Software\sitecoreold\", "C:\Software\unicorn\", "C:\Software\Install-Cultures\")
$wcards = '*\*'
$dataFolder = "\Data"
$unicornConfigFolder = 'zzz'
$connStringFile = '\Website\App_Config\ConnectionStrings.config'
$dbNameArray = @("st_core", "st_master", "st_web")
$staticDBLink = '.database.windows.net'

$dbUrlSubdomainHash = @{
    $stcores[0] = $dbNewName
    $stcores[1] = $dbOldName
}