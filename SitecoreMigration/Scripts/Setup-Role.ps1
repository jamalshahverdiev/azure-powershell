Param(
    [string] $sqlAdministratorLogin,
    [string] $sqlAdministratorLoginPassword,
    [string] $dbNewName,
    [string] $dbOldName,
    [string] $fqdn,
    [string] $licenseFile,
    [string] $unicornConfig
)

Install-PackageProvider -Name NuGet -Force
Install-Module -Name SqlServer -AllowClobber -Force

[array]$xmlarray = 0..2
[array]$ziparray = 0..3
[array]$extrarray = 0..1
$randomPass='0_MVyu6tuygjdbehmsjhfIU.76tygfhjKdsfiuvsdghdkj90irgrjeoifvuhjIUIUolkvjc'
$zipFilesPath = @("C:\Software\sitecorenew.zip", "C:\Software\sitecoreold.zip", "C:\Software\unicorn.zip", "C:\Software\Install-Cultures.zip")
$localPath = 'C:\Software\'
$stcores = @("C:\inetpub\sitecorenew", "C:\inetpub\sitecoreold")
$dataConfigFolder = '\Website\App_Config\Include\'
$psremoteConfigFiles = @('makecert.exe', 'ConfigureWinRM.ps1')
$psremoteGitUrl = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-winrm-windows/'
$extractPaths = @("C:\Software\sitecorenew\", "C:\Software\sitecoreold\", "C:\Software\unicorn\", "C:\Software\Install-Cultures\")
$dataFolder = "\Data"
$unicornConfigFolder = 'zzz'
$connStringFile = '\Website\App_Config\ConnectionStrings.config'
$dbNameArray = @("st_core", "st_master", "st_web")
$staticDBLink = '.database.windows.net'

$dbUrlSubdomainHash = @{
    $stcores[0] = $dbNewName
    $stcores[1] = $dbOldName
}

function Expand-Archives ($arrayname, $zipFiles, $extractedPaths) {
    foreach ( $index in $arrayname ) {
        Expand-Archive -Force -Path $zipFiles[$index] -DestinationPath $extractedPaths[$index] 
    }    
} 

function Copy-SitecoreToPubHtml ($arrayname, $extractedPaths, $pubhtmlpaths) {
    foreach ( $index in $arrayname ) {
        Get-ChildItem -Path ("{0}{1}" -f $extractedPaths[$index], "*\*") -Directory | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $pubhtmlpaths[$index] -Recurse -Force
        }    
    }    
}

function Copy-UnicornToPubHtml ($arrayname, $extractedPaths, $pubhtmlpaths) {
    Get-ChildItem -Path ("{0}{1}" -f $extractedPaths[2], '*') -Directory | ForEach-Object {
        foreach ( $index in $arrayname) {
            Copy-Item -Path $_.FullName -Destination ("{0}{1}" -f $pubhtmlpaths[$index], '\Website') -Recurse -Force
        }
    }    
}

function Copy-LicenseUnicornEditSecretInXML ($pubhtmlpaths, $localPath, $licenseFile, $dataFolder, $dataConfigFolder, $unicornConfigFolder, $unicornConfig, $randomPass) {
    foreach ($dir in $pubhtmlpaths) {
        Copy-Item -Path "$localPath$licenseFile" -Destination ("{0}{1}" -f $dir, $dataFolder)
        New-Item -ItemType Directory -Path ("{0}{1}{2}" -f $dir, $dataConfigFolder, $unicornConfigFolder) -Force
        Copy-Item -Path "$localPath$unicornConfig" -Destination ("{0}{1}{2}" -f $dir, $dataConfigFolder, $unicornConfigFolder) -Force
        Rename-Item -Path ("{0}{1}{2}{3}" -f $dir, $dataConfigFolder, 'Unicorn\', 'Unicorn.zSharedSecret.config.example') -NewName "Unicorn.zSharedSecret.config" -Force
        $xml = [xml](Get-Content ("{0}{1}{2}{3}" -f $dir, $dataConfigFolder, 'Unicorn\', 'Unicorn.zSharedSecret.config'))
        $xml.configuration.sitecore.unicorn.authenticationProvider.SharedSecret = "$randomPass"
        $xml.Save(("{0}{1}{2}{3}" -f $dir, $dataConfigFolder, 'Unicorn\', 'Unicorn.zSharedSecret.config'))
    }    
}

function Set-DataFolderPathConfig ($pubhtmlpaths, $dataConfigFolder, $dataFolder) {
    foreach ($confFile in $pubhtmlpaths) {
        Rename-Item -Path ("{0}{1}{2}" -f $confFile, $dataConfigFolder, 'DataFolder.config.example') -NewName "DataFolder.config"
        $xml = [xml](Get-Content ("{0}{1}{2}" -f $confFile, $dataConfigFolder, 'DataFolder.config'))
        $xml.configuration.sitecore.'sc.variable'.attribute | ForEach-Object {$_.'#text' = ("{0}{1}" -f $confFile, $dataFolder)}
        $xml.Save(("{0}{1}{2}" -f $confFile, $dataConfigFolder, 'DataFolder.config'))
    }    
}

function Disable-SitecoreXDBLogging ($pubhtmlpaths, $dataConfigFolder) {
    $xml = [xml](Get-Content ("{0}{1}{2}" -f $pubhtmlpaths[0], $dataConfigFolder, 'Sitecore.Xdb.config'))
    ($xml.configuration.sitecore.settings.setting | Where-Object {$_.Name -eq 'Xdb.Enabled'}).Value = "false"
    $xml.Save(("{0}{1}{2}" -f $pubhtmlpaths[0], $dataConfigFolder, 'Sitecore.Xdb.config'))    
}

function Set-SitecoreDBConnectionString ($dbUrlSubdomainHash, $staticDBLink, $connStringFile, $arrayname, $sqlAdminLogin, $sqlAdminPass, $dbNameArray) {
    foreach ($confFile in $dbUrlSubdomainHash.Keys) {
        $dbConStr = ("{0}{1}" -f $dbUrlSubdomainHash.Item($confFile), $staticDBLink)
        $xml = [xml](Get-Content ("{0}{1}" -f $confFile, $connStringFile))
        foreach ( $index in $arrayname ) {
            $xml.SelectNodes("/connectionStrings/add")[$index] | ForEach-Object {$_.connectionString = ("{0}{1};{2}{3};{4}{5},{6};{7}{8}" -f 'user id=', $sqlAdminLogin, 'password=', $sqlAdminPass, 'Data Source=', $dbConStr, '1433', 'Database=', $dbNameArray[$index])}
        }
        $xml.Save(("{0}{1}" -f $confFile, $connStringFile))
    }    
}

function Get-PsRemoteModule ($arrayname, $psremoteGitUrl, $psremoteConfigFiles) {
    foreach ( $index in $arrayname ) {
        Invoke-WebRequest -Uri ("{0}{1}" -f $psremoteGitUrl, $psremoteConfigFiles[$index]) -OutFile ("{0}{1}" -f 'Scripts\', $psremoteConfigFiles[$index])
    }    
}

function Enable-WinRm ($fqdn) {
    Push-Location 
    Set-Location .\Scripts
    .\ConfigureWinRM.ps1 -HostName $fqdn
    Pop-Location    
}

function Install-SitecoreCultures ($extractedPaths) {
    Invoke-Expression ("{0}{1} {2} {3}{4}" -f $extractedPaths[3], 'Install-Cultures.ps1', '-languageFile', $extractedPaths[3], 'CultureDefinitions.xml')
    Invoke-Expression "iisreset.exe"    
}

Expand-Archives -arrayname $ziparray -zipFiles $zipFilesPath -extractedPaths $extractPaths 
Copy-SitecoreToPubHtml -arrayname $extrarray -extractedPaths $extractPaths -pubhtmlpaths $stcores
Copy-UnicornToPubHtml -arrayname $extrarray -extractedPaths $extractPaths -pubhtmlpaths $stcores   
Copy-LicenseUnicornEditSecretInXML -pubhtmlpaths $stcores -localPath $localPath -licenseFile $licenseFile -dataFolder $dataFolder -dataConfigFolder $dataConfigFolder -unicornConfigFolder $unicornConfigFolder -unicornConfig $unicornConfig -randomPass $randomPass
Set-DataFolderPathConfig -pubhtmlpaths $stcores -dataConfigFolder $dataConfigFolder -dataFolder $dataFolder
Disable-SitecoreXDBLogging -pubhtmlpaths $stcores -dataConfigFolder $dataConfigFolder
Set-SitecoreDBConnectionString -dbUrlSubdomainHash $dbUrlSubdomainHash -staticDBLink $staticDBLink -connStringFile $connStringFile -arrayname $xmlarray -sqlAdminLogin $sqlAdministratorLogin -sqlAdminPass $sqlAdministratorLoginPassword -dbNameArray $dbNameArray
Get-PsRemoteModule -arrayname $extrarray -psremoteGitUrl $psremoteGitUrl -psremoteConfigFiles $psremoteConfigFiles
Enable-WinRm -fqdn $fqdn
Install-SitecoreCultures -extractedPaths $extractPaths