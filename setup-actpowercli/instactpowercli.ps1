#
## File: setup-actpowercli.ps1
## Automatically download and install ActPowerCLI on the Windows server
#

#
# Download the ActPowerCLI from GitHub
# 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$webclient = New-Object System.Net.WebClient
$url = "https://github.com/Actifio/powershell/raw/master/ActPowerCLI-7.0.0.6.zip"
Write-Host "Downloading latest version of ActPowerCLI from $url" -ForegroundColor Cyan

$file = "$($env:TEMP)\ActPowerCLI-7.0.0.6.zip"
$webclient.DownloadFile($url,$file)
Write-Host "File saved to $file" -ForegroundColor Green

#
# Location of the ActPowerCLI modules
#
$targetondisk = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\Modules"

#
# Copies the module to the appropriate directory and cleanup the folders
#
$shell_app=new-object -com shell.application
$zip_file = $shell_app.namespace($file)
Write-Host "Uncompressing the Zip file to $($targetondisk)" -ForegroundColor Cyan
$destination = $shell_app.namespace($targetondisk)
$destination.Copyhere($zip_file.items(), 0x10)

Write-Host "Renaming folder" -ForegroundColor Cyan
Move-Item -Path ($targetondisk+"\ActPowerCLI-7.0.0.6\ActPowerCLI") -Destination $targetondisk -Force
Remove-Item -Path ($targetondisk+"\ActPowerCLI-7.0.0.6") 

# 
# Install the ActPowerCLI module
#
Write-Host "Module has been installed" -ForegroundColor Green
Import-Module -Name ActPowerCLI
Get-Command -Module ActPowerCLI

(Get-Module ActPowerCLI).Version
