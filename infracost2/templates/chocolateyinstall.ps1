$ErrorActionPreference = 'Stop'

$url64 = "https://github.com/infracost/cli/releases/download/v{PLACEHOLDER_VERSION}/infracost_{PLACEHOLDER_VERSION}_windows_amd64.zip"
$unzipLocation = Split-Path -Parent $MyInvocation.MyCommand.Definition

$packageParams = @{
  PackageName   = 'infracost2'
  UnzipLocation = $unzipLocation
  Url64         = $url64
  Checksum64    = '{PLACEHOLDER_SHA}'
  ChecksumType  = 'sha256'
}

Install-ChocolateyZipPackage @packageParams