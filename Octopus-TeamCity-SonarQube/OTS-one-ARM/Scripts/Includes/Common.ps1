$7zipDestination = Join-Path $downloadDir '7Zip'
$7zipTool = Join-Path $7zipDestination '7za.exe'

function Copy-WebConfig($downloadDir, $publicHtmlFolder) {
    Copy-Item -Path ("{0}{1}{2}" -f "$downloadDir", '\temps\', 'web.config') -Destination ("{0}{1}" -f "$publicHtmlFolder", 'web.config')
}

function Initialize-Path([string]$path) {
    if (!(Test-Path $path)) {
        New-Item -ItemType Directory -Force -Path $path
    }
}

function Receive-Item([string]$url) {
    $urlFile = $url.Substring($url.LastIndexOf("/") + 1)
    $targetPath = Join-Path $downloadDir $urlFile
    if (!(Test-Path $targetPath)) {
        (New-Object Net.WebClient).DownloadFile($url, $targetPath)
        Write-Host "$urlFile downloaded"
    }

    return $targetPath
}

function Expand-TarGz([string]$path, [string]$destination) {
    $cmdLine = "/C $7zipTool x $path -so | $7zipTool x -aoa -si -ttar -o$destination"
    & 'cmd.exe' $cmdLine
}

function Install-7Zip() {
    $7zipUrl = 'http://www.7-zip.org/a/7za920.zip'
    $7zipPath = Receive-Item $7zipUrl

    Expand-Archive -Path $7zipPath -DestinationPath $7zipDestination
}

function Install-SubinAclMsi ($downloadDir) {
    Write-Host "Install SubInAcl"
    Start-Process -FilePath msiexec -ArgumentList /i, "$downloadDir\Temps\subinacl.msi", /qn, /l, "$downloadDir\subiacl.log" -wait
}

function Install-MSBuild($downloadDir) {
    Write-Host "Install MSBuild"
    $outFile = ("{0}{1}{2}" -f $downloadDir, '\', "vs_BuildTools.exe")
    $vsBuildUrl = 'https://download.microsoft.com/download/5/A/8/5A8B8314-CA70-4225-9AF0-9E957C9771F7/vs_BuildTools.exe'
    Invoke-WebRequest -Uri $vsBuildUrl -OutFile $outFile
    Start-Process -FilePath $outFile -ArgumentList "--add Microsoft.VisualStudio.Component.NuGet.BuildTools --add Microsoft.Net.ComponentGroup.TargetingPacks.Common --add Microsoft.VisualStudio.Workload.MSBuildTools --add Microsoft.VisualStudio.Workload.WebBuildTools --passive --norestart" -wait
}

function Install-NodeJS($nodeJSversion, $downloadDir) {
    Write-Host "Install Node" 
    $outFile = ("{0}{1}{2}" -f $downloadDir, '\', "node-$nodeJSversion-x64.msi")
    $nodejsUrl="https://nodejs.org/download/release/$nodeJSversion/node-$nodeJSversion-x64.msi"
    Invoke-WebRequest -Uri $nodejsUrl -OutFile $outFile
    Start-Process -FilePath msiexec -ArgumentList /i, $outFile, /qn, /l, node-$nodeJSversion-x64.log -wait 
}

function Install-Git($gitVersion, $downloadDir) {
    Write-Host "Install Git"
    $outFile = ("{0}{1}{2}" -f $downloadDir, '\', "Git-$gitVersion-64-bit.exe")
    $gitUrl = "https://github.com/git-for-windows/git/releases/download/v$gitVersion.windows.1/Git-$gitVersion-64-bit.exe"
    (New-Object System.Net.WebClient).DownloadFile($gitUrl, $outFile)
    Start-Process -FilePath $outFile -ArgumentList /verysilent, /norestart, /restartapplications, /l, "Git-$gitVersion-bit.log" -wait 
}

# function Install-Choco($package) {
#     Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) | Out-File -Append C:\filename.txt
#     choco install -y $package -force
#     refreshenv
# }


function Get-BuildAgent($vmDnsName, $downloadDir) {
    write-host "Install TeamCity Build Agent"
    $url = "https://$vmDnsName/update/agentInstaller.exe"
    $output = "$downloadDir\agentInstaller.exe"
    $start_time = Get-Date
    (New-Object System.Net.WebClient).DownloadFile($url, $output)
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
    Start-Process -Wait -FilePath "$downloadDir\agentInstaller.exe" -ArgumentList "/S" -PassThru
}

function Set-PremissionTcAgent($number, $userName) {
    New-Item "C:\BuildAgent$number" -type directory
    Copy-Item -Path "C:\BuildAgent\*" -Destination "C:\BuildAgent$number" -Recurse
    $Acl = Get-Acl "C:\BuildAgent$number"
    $Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("$userName","FullControl","ContainerInherit,ObjectInherit", "None", "Allow")
    $Acl.SetAccessRule($Ar)
    Set-Acl "C:\BuildAgent$number" $Acl
}

function Initialize-TeamCityAgent($count, $downloadDir, $vmDnsName) {
    $origBuildPropertiesFile = "$downloadDir\Temps\buildAgent.properties.template"
    $origBuildWrapperFile = "$downloadDir\Temps\wrapper.conf.template"
    Get-Content 'C:\TeamCity\logs\teamcity-server.log' | Select-String 'Super user authentication token' | Tee-Object -Variable outLine
    $teamcityToken = [regex]::matches($outLine, '(?<=\").+?(?=\")').value
    ForEach ($number in 1..$count ) {
        Set-PremissionTcAgent $number 'BuildUser'        
        $buildProperiesDestFile = "C:\BuildAgent$number\conf\buildAgent.properties"
        (Get-Content $origBuildPropertiesFile) | Foreach-Object {
            $_ -replace "localhost", "$vmDnsName" `
               -replace "BuildName", "build$number" `
               -replace "BuildAgent", "BuildAgent$number" `
               -replace "AuthTokenID", "$teamcityToken" `
               -replace "AgentPort", "909$number"
            } | Set-Content $buildProperiesDestFile -Force
        $buildWrapperDestFile = "C:\BuildAgent$number\launcher\conf\wrapper.conf"
        (Get-Content $origBuildWrapperFile) | Foreach-Object {
            $_ -replace "TCBuildAgentName", "TCBuildAgent$number" `
               -replace "TeamCity Build Agent", "TeamCity Build Agent$number"
            } | Set-Content $buildWrapperDestFile -Force
        Set-Location "c:\BuildAgent$number\bin"
        write-host "install the agent service"
        & 'cmd.exe' /C service.install.bat    
        write-host "start the service"
        & 'sc.exe' config "TCBuildAgent$number" obj= ".\BuildUser" password= "P@ssW0rD!12" TYPE= own
        & 'C:\Program Files (x86)\Windows Resource Kits\Tools\subinacl.exe' /service "TCBuildAgent$number" /GRANT=BuildUser=STOE
        & 'cmd.exe' /C service.start.bat    
    }
}


function Start-Cleanup() {
    Remove-Item $downloadDir -Force -Recurse
}