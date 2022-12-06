param(
    [Parameter(Mandatory = $true)]
	$languageFile
)

Add-Type -AssemblyName 'sysglobl' 
Add-Type -AssemblyName 'System.Globalization' 

function Install-Culture {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $cultureCode,
        [Parameter(Mandatory = $true)]
        [string]
        $cultureName,
        [string]
        $baseCulture,
        [string]
        $baseRegion
    )
    
    if (!$baseCulture) {
        $baseCulture = 'en'
    }

    if (!$baseRegion) {
        $baseRegion = 'en-GB'
    }


    try {
        $cib = New-Object System.Globalization.CultureAndRegionInfoBuilder($cultureCode, [System.Globalization.CultureAndRegionModifiers]::None)
    } catch {
        $cib = New-Object System.Globalization.CultureAndRegionInfoBuilder($cultureCode, [System.Globalization.CultureAndRegionModifiers]::Replacement)
    }

    $templateCulture = New-Object System.Globalization.CultureInfo($baseCulture)
    $templateRegion = New-Object System.Globalization.RegionInfo($baseRegion)
    $cib.LoadDataFromCultureInfo($templateCulture)
    $cib.LoadDataFromRegionInfo($templateRegion)

    $cib.ConsoleFallbackUICulture = $templateCulture
    $cib.CultureEnglishName = $cultureName
    $cib.CultureNativeName = $cultureName
    $cib.RegionEnglishName = $cultureName
    $cib.RegionNativeName = $cultureName

    # Unregister the culture, in case it already exists
    try {
        [System.Globalization.CultureAndRegionInfoBuilder]::Unregister($cultureCode)
    } catch { }

    try {
        $cib.Register()
        Write-Host "Registered $($cib.CultureEnglishName)"
    } catch {
        throw;
    }
    
}

$culture = New-Object System.Globalization.CultureAndRegionInfoBuilder('nl-BE', [System.Globalization.CultureAndRegionModifiers]::Replacement)
$culture.NumberFormat.CurrencyPositivePattern = 2
$culture.NumberFormat.CurrencyNegativePattern = 12

try {
    [System.Globalization.CultureAndRegionInfoBuilder]::Unregister('nl-BE')
} catch { }
$culture.Register()
Write-Host 'Registered nl-BE replacement'


$culture_frCH = New-Object System.Globalization.CultureAndRegionInfoBuilder('fr-CH', [System.Globalization.CultureAndRegionModifiers]::Replacement)
$culture_frCH.NumberFormat.CurrencyGroupSeparator = "'"

try {
    [System.Globalization.CultureAndRegionInfoBuilder]::Unregister('fr-CH')
} catch { }
$culture_frCH.Register()
Write-Host 'Registered fr-CH replacement'


$config = [xml](Get-Content $languageFile)
$config.languages.language | ForEach-Object {
    Install-Culture -cultureCode $_.cultureCode -cultureName $_.cultureName -baseCulture $_.baseCulture -baseRegion $_.baseRegion
}