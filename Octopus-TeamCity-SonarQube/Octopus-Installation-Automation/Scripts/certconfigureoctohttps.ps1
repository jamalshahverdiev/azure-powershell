Param(
    [string] $OctopusURI
)

$appid = [guid]::NewGuid().Guid
$localhttp = 'http://localhost/'
$localhttps = $localhttp.Replace("http://", "https://")
$volvoUri = 'http://deploy.digitalcommerce.volvocars.com/'
$volvoUriHttps = $volvoUri.Replace("http://", "https://")
$OctopusURIHttps = $OctopusURI.Replace("http://", "https://")
$password = "dcom786" | convertto-securestring -asplaintext -force
Import-PfxCertificate -FilePath "C:\Scripts\deploy-digitalcommerce-volvocars-com.pfx" cert:\localMachine\my -Password $password
$certhash = (Get-ChildItem -path cert:\LocalMachine\My -DnsName "*volvocars*").Thumbprint

#"Application ID:" + $appid + " ***** VolvoHttp:" + $volvoUri + " ***** VolvoHttps:" + $volvoUriHttps + " ***** OctopusHttp:" + $OctopusURI + " ***** OctopusHttps:" + $OctopusURIHttps + " ***** CertificateHash:" + $certhash + " ***** Password:" + $password >> C:\certvariables.txt
#$intipadd = (gwmi win32_networkadapterconfiguration | where {$_.ipaddress -ne $null -and $_.defaultipgateway -ne $null}).IPAddress[0]
#New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $domainname
#### Export with password
#$pwd = ConvertTo-SecureString -String "Pa$$w0rd" -Force -AsPlainText
#Export-PfxCertificate -cert cert:\localMachine\my\3DCF9F7D13D19E43913B9DF175B481E1D2F553AC -FilePath D:\cert.pfx -Password $pwd
#$mypwd = Get-Credential -UserName 'Enter password below' -Message 'Enter password below'
#Import-PfxCertificate -FilePath C:\mypfx.pfx -CertStoreLocation Cert:\LocalMachine\My -Password $mypwd.Password

netsh http delete sslcert ipport=0.0.0.0:443
netsh http add sslcert ipport=0.0.0.0:443 certhash=$certhash appid=`{$appid`} certstorename=my 
& 'C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe' configure --instance "OctopusServer" --webForceSSL "True" --console
#& 'C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe' configure --instance "OctopusServer" --webListenPrefixes "$localhttp,$localhttps,$volvoUri,$volvoUriHttps,$OctopusURI,$OctopusURIHttps" --console
& 'C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe' configure --instance "OctopusServer" --webListenPrefixes "$localhttp,$localhttps,$volvoUri,$volvoUriHttps" --console
& 'C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe' service --instance "OctopusServer" --stop --start --console

#####Delete by thumbprint and certificate
#Get-ChildItem Cert:\LocalMachine\My\$certhash | Remove-Item
#Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -match 'volvocars' } | Remove-Item