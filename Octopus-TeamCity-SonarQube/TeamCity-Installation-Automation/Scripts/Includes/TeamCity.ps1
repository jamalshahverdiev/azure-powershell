function Install-Jre() {
    $jdkUrl = 'http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/server-jre-8u131-windows-x64.tar.gz'
    $jdkInstaller = $jdkUrl.Substring($jdkUrl.LastIndexOf("/") + 1)
    $jdkPath = Join-Path $downloadDir $jdkInstaller

    if (!(Test-Path $jdkPath)) {
        $client = New-Object Net.WebClient
        $cookie = "oraclelicense=accept-securebackup-cookie"
        $client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie) 
        $client.DownloadFile($jdkUrl, $jdkPath)
        Write-Host "JRE downloaded"
    }

    Expand-TarGz $jdkPath $downloadDir
    $jrePath = Join-Path $downloadDir 'jdk1.8.0_131\jre'
    Move-Item $jrePath 'C:\TeamCity'
    [Environment]::SetEnvironmentVariable('TEAMCITY_SERVER_MEM_OPTS', '-Xmx2g -XX:MaxPermSize=270m -XX:ReservedCodeCacheSize=350m', 'Machine')
}

function Install-TeamCity() {
    $teamcityUrl = 'https://download.jetbrains.com/teamcity/TeamCity-2017.2.3.tar.gz'
    #$teamcityUrl = 'https://download.jetbrains.com/teamcity/TeamCity-2017.1.tar.gz'
    $teamcityPath = Receive-Item $teamcityUrl

    Expand-TarGz $teamcityPath 'C:\'
    & cmd "/C C:\TeamCity\bin\teamcity-server.bat service install /runAsSystem"
}

function Install-JDBC() {
    $jdbcUrl = 'https://download.microsoft.com/download/0/2/A/02AAE597-3865-456C-AE7F-613F99F850A8/enu/sqljdbc_6.0.8112.100_enu.tar.gz'
    $jdbcPath = Receive-Item $jdbcUrl
    Expand-TarGz $jdbcPath $downloadDir
    $sourcePath = Join-Path $downloadDir 'sqljdbc_6.0\enu\jre8\sqljdbc42.jar'
    $targetPath = 'C:\ProgramData\JetBrains\TeamCity\lib\jdbc'
    Initialize-Path $targetPath
    Move-Item $sourcePath $targetPath
}

function Add-TeamCityDBCredetials($sqlServerName, $sqlDBName, $sqlUsername, $sqlPasswd) {
    $startupConf = @"
teamcity.data.path=C\:\\ProgramData\\JetBrains\\TeamCity
teamcity.installation.completed=true
"@
    New-Item -ItemType File -Path 'C:\TeamCity\conf\teamcity-startup.properties' -Value $startupConf -Force

    $sqlConf = @"
connectionProperties.user=$sqlUsername
connectionProperties.password=$sqlPasswd
connectionUrl=jdbc\:sqlserver\://$sqlServerName\:1433;databaseName\=$sqlDBName
"@
#connectionProperties.user=admin-avanade
#connectionProperties.password=SenjaVanja69
#connectionUrl=jdbc\:sqlserver\://dc-sql-all-test.database.windows.net\:1433;databaseName\=TeamCityDB

    #$internalDbConf = 'connectionUrl=jdbc\:hsqldb\:file\:$TEAMCITY_SYSTEM_PATH/buildserver'
    #New-Item -ItemType File -Path 'C:\ProgramData\JetBrains\TeamCity\config\database.properties' -Value $internalDbConf -Force
    New-Item -ItemType File -Path 'C:\ProgramData\JetBrains\TeamCity\config\database.properties' -Value $sqlConf -Force
}

function Add-ToEndXML($srcFile, $partOfXmlFile) {
    $xml = [xml] (Get-Content $srcFile)
    [xml]$valveSettingsXml = (Get-Content $partOfXmlFile)
    $xml.Server.Service.Engine.Host.AppendChild($xml.ImportNode($valveSettingsXml.valve, $true))
    $xml.Save($srcFile)
}

function Start-TeamCity() {
    Start-Service -Name TeamCity

    $retrycount = 0
    $completed = $false
    $eulaUrl = 'http://localhost:8111/showAgreement.html'
    while (-not $completed) {
        try {
            Invoke-WebRequest -Uri $eulaUrl -UseBasicParsing | Out-Null
            $completed = $true
        }
        catch {
            if ($retrycount -ge 6) {
                throw
            }
            else {
                Start-Sleep 60
                $retrycount++
            }
        }
    }

    $authConfig = 'C:\ProgramData\JetBrains\TeamCity\config\auth-config.xml'
    (Get-Content $authConfig).replace('true', 'false') | Set-Content $authConfig
    Invoke-WebRequest -Uri $eulaUrl -UseBasicParsing -Method POST | Out-Null
}

function Set-TeamCityUser([string]$login, [string]$pass) {
    $s = Get-Content "C:\TeamCity\logs\teamcity-server.log" `
        | Select-String "Super user authentication token" `
        | select -Last 1

    $token = [regex]::matches($s, '(?<=\").+?(?=\")').Value
    $su = ''

    $pair = "$($su):$($token)"
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
    $basicAuthValue = "Basic $encodedCreds"

    $headers = @{
        Authorization = $basicAuthValue
    }

    $hashSet = @{username = $login; password = $pass; }

    $json = $hashSet | ConvertTo-Json

    Invoke-RestMethod -Headers $headers -Uri http://localhost:8111/httpAuth/app/rest/users -Method Post -UseBasicParsing -Body $json -ContentType "application/json"
    Invoke-RestMethod -Headers $headers -Uri "http://localhost:8111/httpAuth/app/rest/users/username:$login/roles/SYSTEM_ADMIN/g/" -Method Put -UseBasicParsing
}


