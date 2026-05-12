$ErrorActionPreference = 'Stop'

$url64 = "https://github.com/infracost/cli/releases/download/v{PLACEHOLDER_VERSION}/infracost-windows-amd64.zip"
$unzipLocation = Split-Path -Parent $MyInvocation.MyCommand.Definition

$packageParams = @{
  PackageName   = 'infracost'
  UnzipLocation = $unzipLocation
  Url64         = $url64
  Checksum64    = '{PLACEHOLDER_SHA}'
  ChecksumType  = 'sha256'
}

Install-ChocolateyZipPackage @packageParams