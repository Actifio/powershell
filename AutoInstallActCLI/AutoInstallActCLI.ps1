# 
## File: AutoInstallActCLI.ps1
## Purpose: Script to automate the installation of ActPowerCLI on a Windows server.
#
# Version 1.0 Initial Release
#

<#   
.SYNOPSIS   
   Download and install ActPowerCLI on a Windows host.
.DESCRIPTION 
   This is a powershell script that helps you auomate the process of installing ActPowerCLI modules from the Actifio github site. It can automate the download and installation process.
.PARAMETER action
    To enable the download of ActPowerCLI software, use -download. To install it, use the -install switch. Use the -TmpDir directory if you want to specify a working temporary directory for the zipped file.
.EXAMPLE
    PS > .\AutoInstallActCLI.ps1 -download -install

    To download and install the ActPowerCLI
.EXAMPLE
    PS > .\AutoInstallActCLI.ps1 -download 

    To download the ActPowerCLI modules
.EXAMPLE 
    PS > .\AutoInstallActCLI.ps1 -install -TmpDir c:\temp

    To install the ActPowerCLI modules using the zip file c:\temp
.NOTES   
    Name: AutoInstallActCLI.ps1
    Author: Michael Chew
    DateCreated: 30-March-2020
    LastUpdated: 30-March-2020
.LINK
    https://github.com/Actifio/powershell/blob/master/AutoInstallActCLI   
#>

[CmdletBinding()]
Param
( 
  # To download the software
  [switch]$Download = $false, 
  # To install the software
  [switch]$Install = $false,
  # Location of the directory of the zip file
  [string]$TmpDir = ""
)  ### Param

$Version = "10.0.0.227"
$ScriptVersion = "1.0"

##################################
# Function: Download-ActPowerCLI
#
# Download the ActPowerCLI from GitHub
# 
##################################
function Download-ActPowerCLI (
      [string]$Version,
      [string]$Software )
{
  Write-Host "I will be downloading ActPowerCLI version $Version. Yippee!"

  $url = "https://github.com/Actifio/powershell/raw/master/" + $Software 
  $download_path = "$TmpDir\" + $Software 
  
  ## Change the security protocol to use TLSv1.2
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  Write-Host "Downloading latest version of ActPowerCLI from $url" -ForegroundColor Cyan
  Invoke-WebRequest -Uri $url -OutFile $download_path

  Write-Host "File saved to $download_path" -ForegroundColor Green

  Write-Host "Unblocking the downloaded file - $url" -ForegroundColor Cyan
  Get-Item $download_path | Unblock-File

}

##################################
# Function: Install-ActPowerCLI
#
##################################
function Install-ActPowerCLI ( 
  [string]$Version,
  [string]$Software )
{
  Write-Host "I will be installing ActPowerCLI version $Version . Yippee!"
#
# Location of the ActPowerCLI modules
#
  $targetondisk = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\Modules"
  $download_path = "$TmpDir\" + $Software 
  #
  # Copies the module to the appropriate directory and cleanup the folders
  #
  
  $shell = New-Object -ComObject shell.application
  $zip = $shell.NameSpace($download_path)
  foreach ($item in $zip.items()) {
    $shell.Namespace("$TmpDir").CopyHere($item)
  }
  
  Write-Host "Renaming folder" -ForegroundColor Cyan

  $WorkDir = $TmpDir + "\ActPowerCLI-" + $Version + "\ActPowerCLI"
  if (Test-Path -Path $WorkDir) {
    Move-Item -Path ($WorkDir) -Destination $targetondisk -Force
    Remove-Item -Path ($TmpDir + "\ActPowerCLI-" + $Version) 
  } else {
    Move-Item -Path ($TmpDir + "\ActPowerCLI") -Destination $targetondisk -Force
  }

  ### PowerShell v5.1
  ## Expand-Archive -Path $download_path -DestinationPath $targetondisk -Force

#  Remove-Item -Path $download_path 

# 
# Install the ActPowerCLI module
#
  Write-Host "Module has been installed" -ForegroundColor Green

  Import-Module -Name ActPowerCLI
  Get-Command -Module ActPowerCLI

  (Get-Module ActPowerCLI).Version

  # Get-Module ActPowerCLI -ListAvailable | Remove-Module
  # Get-Module ActPowerCLI -ListAvailable
  # Remove-Module -Name ActPowerCLI -Force
}

##################################
# Function: Display-Usage
#
##################################
function Display-Usage ()
{
    write-host "Usage: .\AutoInstallActCLI.ps1 [ -download -install | -download | -install ] [ -TmpDir <directory name> ] `n"
    write-host " get-help .\AutoInstallActCLI.ps1 -examples"
    write-host " get-help .\AutoInstallActCLI.ps1 -detailed"
    write-host " get-help .\AutoInstallActCLI.ps1 -full"    
}     ### end of function

##############################
#
#  M A I N    B O D Y
#
##############################

if ($download -eq $false -And $install -eq $false) {
  Display-Usage
  exit
}

if ($TmpDir -eq $null -or $TmpDir -eq "") {
  $TmpDir = $($env:TEMP)
  }

$Software = "ActPowerCLI-" + $Version + ".zip"

if ($download) {
  Download-ActPowerCLI $Version $Software
}

if ($Install) {
  Install-ActPowerCLI $Version $Software
}

exit