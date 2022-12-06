Param(
    [string] $OctopusURI,
    [string] $OctopusUsername,
    [string] $OctopusPassword
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
##CONFIGURATION##
$APIKeyPurpose = "ConnectAgents" #Brief text to describe the purpose of your API Key.

##PROCESS##
#Adding libraries. Make sure to modify these paths acording to your environment setup.
Add-Type -Path "C:\Program Files\Octopus Deploy\Octopus\Newtonsoft.Json.dll"
Add-Type -Path "C:\Program Files\Octopus Deploy\Octopus\Octopus.Client.dll"

#Creating a connection
$endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
$repository = new-object Octopus.Client.OctopusRepository $endpoint

#Creating login object
$LoginObj = New-Object Octopus.Client.Model.LoginCommand 
$LoginObj.Username = $OctopusUsername
$LoginObj.Password = $OctopusPassword

#Loging in to Octopus
$repository.Users.SignIn($LoginObj)

#Getting current user logged in
$UserObj = $repository.Users.GetCurrent()

#Creating API Key for user. This automatically gets saved to the database.
$ApiObj = $repository.Users.CreateApiKey($UserObj, $APIKeyPurpose)

#Returns the API Key in clear text
$ApiObj.ApiKey | Out-File -filepath 'C:\Octopus\api-cleartext.txt'
$apikey = (Get-Content 'C:\Octopus\api-cleartext.txt')

######Install tentacle and join to the server
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) | Out-File -Append C:\filename.txt
choco install octopustools | Out-File -Append C:\filename.txt
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

octo create-environment --name=Development --server="$OctopusURI" --apikey="$apikey" | Out-File -Append C:\filename.txt
netsh advfirewall firewall add rule "name=Octopus Deploy Inside" dir=in action=allow protocol=TCP localport=10943
netsh advfirewall firewall add rule "name=Octopus HTTPS selected port" dir=in action=allow protocol=TCP localport=11443
netsh advfirewall firewall add rule "name=Octopus HTTPS Inside" dir=in action=allow protocol=TCP localport=443

function Install-ConfigureTentacle([string]$arguments)
{
    $a = (get-date -Format hh-m-s) + "." +  (Get-Random) + ".tentacle.log"
    Start-Transcript -Path "C:\$a"

    Write-Output "Configuring Tentacle with $arguments" | Out-File -Append C:\filename.txt
    
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe"
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.CreateNoWindow = $true;
    $pinfo.UseShellExecute = $false;
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $arguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()

    Write-Host $stdout | Out-File -Append C:\filename.txt
    Write-Host $stderr | Out-File -Append C:\filename.txt

    if ($p.ExitCode -ne 0) {
        Write-Host "Exit code: " + $p.ExitCode | Out-File -Append C:\filename.txt
        throw "Configuration failed"
    }

    Stop-Transcript
}

function Get-ExternalIP {
    return (Invoke-WebRequest http://myexternalip.com/raw).Content.TrimEnd()
}

Write-Output "Beginning Tentacle installation" | Out-File -Append C:\filename.txt
Write-Output "Downloading Octopus Tentacle MSI..." | Out-File -Append C:\filename.txt
$downloader = new-object System.Net.WebClient
$downloader.DownloadFile("https://octopus.com/downloads/latest/OctopusTentacle64", "C:/Scripts/Tentacle.msi")

$a = (get-date -Format hh-m-s) + "." +  (Get-Random) + ".msiexec.log"
Start-Transcript -Path "C:\$a"
Push-Location
Set-Location "C:/Scripts"
Write-Output "Installing Tentacle" | Out-File -Append C:\filename.txt
$msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/i Tentacle.msi /quiet" -Wait -Passthru).ExitCode
if ($msiExitCode -ne 0) {
   Write-Output "Tentacle MSI installer returned exit code $msiExitCode" | Out-File -Append C:\filename.txt
   throw "Installation aborted"
}
Pop-Location
Stop-Transcript
$ipAddress = Get-ExternalIP
Write-Output "Detected IP address as $ipAddress" | Out-File -Append C:\filename.txt

Write-Output "Configuring Tentacle" | Out-File -Append C:\filename.txt
Install-ConfigureTentacle "create-instance --instance `"Tentacle`" --config `"C:\Octopus\Tentacle.config`" --console" 
Install-ConfigureTentacle "new-certificate --instance `"Tentacle`" --if-blank --console"
Install-ConfigureTentacle "configure --instance `"Tentacle`" --reset-trust --console"
Install-ConfigureTentacle "configure --instance `"Tentacle`" --app `"C:\Octopus\Applications`" --port `"10933`" --noListen `"True`" --console"
netsh advfirewall firewall add rule "name=Octopus Deploy Tentacle" dir=in action=allow protocol=TCP localport=10933
Install-ConfigureTentacle "polling-proxy --instance `"Tentacle`" --proxyEnable `"False`" --console"
Install-ConfigureTentacle "register-with --instance `"Tentacle`" --server `"$OctopusURI`" --name `"OctopusDeploy`" --comms-style `"TentacleActive`" --server-comms-port `"10943`" --force --apiKey `"$apikey`" --environment `"Development`" --role `"DevRole`" --console"
Install-ConfigureTentacle "service --instance `"Tentacle`" --install --stop --start --console"

Write-Output "Installation of Tentacle finished." | Out-File -Append C:\filename.txt