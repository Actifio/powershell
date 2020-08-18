# 
## File: AutoInstallActCLI.ps1
## Purpose: Script to automate the installation of ActPowerCLI on a Windows server.
#
# Version 1.0 Initial Release
# Version 1.1 Updated to handle new Github Locations
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
    Author: Michael Chew and Anthony Vandewerdt
    DateCreated: 30-March-2020
    LastUpdated: 16-August-2020
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

$ScriptVersion = "1.1"

##################################
# Function: Download-ActPowerCLI
#
# Download the ActPowerCLI from GitHub
# 
##################################
function Download-ActPowerCLI (
      [string]$Software )
{
  Write-Host "Downloading ActPowerCLI."

  $url = " https://github.com/Actifio/ActPowerCLI/archive/main.zip"
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
  [string]$Software )
{
    $modulebase = (get-module -listavailable -name ActPowerCLI).modulebase
    if ($modulebase) {
        Write-Host "`nActPowerCLI Module already installed in:"
        foreach ($base in $modulebase)
        {
            write-host "    $base"
        }
    }

    if (!($modulebase))
    {
        Write-Host "`nInstalling ActPowerCLI`n"
        #
        # Location of the ActPowerCLI modules
        #
        $hostVersionInfo = (get-host).Version.Major
        if ( $hostVersionInfo -lt "7" )
        {
            $targetondisk = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\Modules\ActPowerCLI"
        }
        else 
        {
            $targetondisk = "$($env:SystemDrive)\Program Files\PowerShell\Modules\ActPowerCLI"
        }
    }
    else {
        Write-Host "`nUpgrading ActPowerCLI"
    }

    $download_path = "$TmpDir" +"\main.zip" 
    #
    # Copies the module to the appropriate directory and cleanup the folders
    #
    $unziptarget = "$TmpDir" + "\ActDownload"
    Expand-Archive -Path $download_path -DestinationPath $unziptarget -Force

    
    Write-Host "Copying files" -ForegroundColor Cyan
    if (!($modulebase))
    {
        if ( $hostVersionInfo -lt "7" )
        {
            $WorkDir = $TmpDir + "\ActDownload\ActPowerCLI-main\ActPowerCLI_PS3"
            $null = New-Item -ItemType Directory -Path $targetondisk -Force -ErrorAction Stop
            $null = Copy-Item $WorkDir\* $targetondisk -Force -Recurse -ErrorAction Stop
            $null = Test-Path -Path $targetondisk -ErrorAction Stop
        }
        else 
        {
            $WorkDir = $TmpDir + "\ActDownload\ActPowerCLI-main"
            $null = New-Item -ItemType Directory -Path $targetondisk -Force -ErrorAction Stop
            $null = Copy-Item $WorkDir\ActPowerCLI* $targetondisk -Force -Recurse -ErrorAction Stop
            $null = Test-Path -Path $targetondisk -ErrorAction Stop
        }
        Write-Host "Module has been installed" -ForegroundColor Green
    }
    else 
    {
        if ( $hostVersionInfo -lt "7" )
        {
            foreach ($base in $modulebase)
            {   
                Write-host "Upgrading $base"
                $WorkDir = $TmpDir + "\ActDownload\ActPowerCLI-main\ActPowerCLI_PS3"
                $null = Copy-Item $WorkDir\* $base -Force -Recurse -ErrorAction Stop
                $null = Test-Path -Path $base -ErrorAction Stop
                Write-Host "Module has been upgraded" -ForegroundColor Green
            }
        }
        else 
        {
            foreach ($base in $modulebase)
            {
                Write-host "Upgrading $base"
                $WorkDir = $TmpDir + "\ActDownload\ActPowerCLI-main"
                $null = Copy-Item $WorkDir\ActPowerCLI* $base -Force -Recurse -ErrorAction Stop
                $null = Test-Path -Path $base -ErrorAction Stop
                Write-Host "Module has been upgraded" -ForegroundColor Green
            }
        }
    }

    Remove-Item -Recurse -Path ($TmpDir + "\ActDownload") 
    Remove-Item -Path ($download_path) 


    # 
    # Install the ActPowerCLI module
    #
    

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

$Software = "main.zip"

if ($download) {
  Download-ActPowerCLI  $Software
}

if ($Install) {
  $PSversion = $($host.version).major
  if ($PSversion -lt 5) {
    Write-Host "The minimal version of PowerShell for ActPowerCLI is 5.0 and above. Current version is $PSVersion ."
    Write-Host "Will not install ActPowerCLI. "
    exit
  } 
  ## source: https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed#to-find-net-framework-versions-by-querying-the-registry-in-code-net-framework-45-and-later
  ## 
  ## 394802 = .NET Framework 4.6.2
  ## 378389 = .NET Framework 4.5
  if ( (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release -ge 378388 ) {
    Install-ActPowerCLI $Version $Software
    } else {
      Write-Host "The minimal .NET Framework version required for ActPowerCLI is 4.5 and above. "
      Write-Host "Will not install ActPowerCLI. "    
      exit
    }
}

exit