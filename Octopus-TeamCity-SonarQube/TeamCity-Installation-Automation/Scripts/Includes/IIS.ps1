function Install-IIS() {
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools
    Install-WindowsFeature -Name Web-WebSockets
}

function Install-UrlRewrite() {
    $urlRewriteUrl = 'http://download.microsoft.com/download/C/9/E/C9E8180D-4E51-40A6-A9BF-776990D8BCA9/rewrite_amd64.msi'
    $urlRewritePath = Receive-Item $urlRewriteUrl
    Start-Process -FilePath msiexec -ArgumentList /i, $urlRewritePath, /quiet, /norestart -Wait

    $arrUrl = 'http://download.microsoft.com/download/E/9/8/E9849D6A-020E-47E4-9FD0-A023E99B54EB/requestRouter_amd64.msi'
    $arrPath = Receive-Item $arrUrl
    Start-Process -FilePath msiexec -ArgumentList /i, $arrPath, /quiet, /norestart -Wait
}

function Set-ReverseProxy([string]$thumbprint) {
    Import-Module ServerManager
    Add-WindowsFeature Web-Scripting-Tools
    Import-Module WebAdministration
    Push-Location
    Set-Location IIS:\SslBindings
    Get-Item cert:\LocalMachine\MY\$thumbprint | New-Item 0.0.0.0!443
    Pop-Location
    New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol HTTPS
	
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/proxy" -name "enabled" -value "True"
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/proxy" -name "reverseRewriteHostInResponseHeaders" -value "False"
}

function Set-FirewallRules() {
    New-NetFirewallRule -DisplayName 'HTTP(S) Inbound' -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('80', '443')
}