# this script updates powershell and nuspec files found in the templates folder to the latest version of Infracost CLI v2.

$version = (Invoke-Webrequest https://api.github.com/repos/infracost/cli/releases/latest | convertfrom-json).name

# strip the leading v; the bare version is used as the chocolatey package version
$bareVersion = $version.Substring(1, ($version.Length-1))

$zip = "infracost-windows-amd64.zip"

Write-Host "$(get-date) - downloading release $version"
Invoke-WebRequest -uri "https://github.com/infracost/cli/releases/download/$($version)/$($zip)" -OutFile $zip

$sha = (Get-FileHash $zip).Hash

if (Test-Path -Path ".\tools") {
  Remove-Item .\tools -Recurse
}
New-Item .\tools -ItemType "directory"

function Get-ScriptDirectory { Split-Path $MyInvocation.ScriptName }
$templatePath = Join-Path (Get-ScriptDirectory) ".\templates"

Get-Content "$($templatePath)\chocolateyinstall.ps1" | %{$_ -replace "{PLACEHOLDER_VERSION}",$bareVersion} | %{$_ -replace "{PLACEHOLDER_SHA}", $sha} | Out-File .\tools\chocolateyinstall.ps1
Get-Content "$($templatePath)\infracost2.nuspec" | %{$_ -replace "{PLACEHOLDER_VERSION}",$bareVersion} | Out-File .\infracost2.nuspec

Write-Host "$(get-date) - Building choco pkg"
choco pack --version $bareVersion

Write-Host "$(get-date) - Testing choco pkg is valid"
choco install infracost2 -dv -s .

$out = (infracost --version)
if ("Infracost $($version)" -ne $out) {
  Write-Host "infracost output: $($out) from choco dry run install did not match expected: 'Infracost $($version)'"
  exit 1
}

Write-Host "$(get-date) - Test install of infracost passed --version check: $($out)"

Get-ChildItem *.nupkg
Write-Host "$(get-date) - Pushing to Chocolatey"
choco push -s https://push.chocolatey.org/ --api-key=$env:CHOCO_API_KEY