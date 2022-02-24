# this script updates powershell and nuspec files found in the the templates folder to the latest version of Infracost.

$zip = "infracost-windows-amd64.zip"
$shafile = "$($zip).sha256"
$version = (Invoke-Webrequest https://api.github.com/repos/infracost/infracost/releases/latest | convertfrom-json).name

Write-Host "$(get-date) - downloading release $version"
Invoke-WebRequest -uri "https://github.com/infracost/infracost/releases/download/$($version)/$($zip)" -OutFile $zip
Invoke-WebRequest -uri "https://github.com/infracost/infracost/releases/download/$($version)/$($shafile)" -OutFile $shafile

$sha = (Get-FileHash $zip).Hash
$contents = (Get-Content $shafile)
if ("$($sha)  $($zip)" -ne $contents) {
  Write-Host "sha of $($sha) mismatched for downloaded artefact contents: $($contents)"
  exit 1
}

if (Test-Path -Path ".\tools") {
  Remove-Item .\tools -Recurse
}
New-Item .\tools -ItemType "directory"

# removing the first v as chocolatey doesnt like this version
$chocoVersion = $version.Substring(1, ($version.Length-1));

function Get-ScriptDirectory { Split-Path $MyInvocation.ScriptName }
$templatePath = Join-Path (Get-ScriptDirectory) ".\templates"

Get-Content "$($templatePath)\chocolateyinstall.ps1" | %{$_ -replace "{PLACEHOLDER_VERSION}",$version} | %{$_ -replace "{PLACEHOLDER_SHA}", $sha} | Out-File .\tools\chocolateyinstall.ps1
Get-Content "$($templatePath)\infracost.nuspec" | %{$_ -replace "{PLACEHOLDER_VERSION}",$chocoVersion} | Out-File .\infracost.nuspec

Write-Host "$(get-date) - Building choco pkg"
choco pack --version $chocoVersion

Write-Host "$(get-date) - Testing choco pkg is valid"
choco install infracost -dv -s .

$out = (infracost --version)
if ("Infracost $($version)" -ne $out) {
  Write-Host "infracost output: $($out) from choco dry run install did not match expected: 'Infracost $($version)'"
  exit 1
}

Write-Host "$(get-date) - Test install of infracost passed --version check: $($out)"

Get-ChildItem *.nupkg
Write-Host "$(get-date) - Pushing to Chocolatey"
choco push -s https://push.chocolatey.org/ --api-key=$env:CHOCO_API_KEY