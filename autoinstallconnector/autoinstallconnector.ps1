## Perform a silent install Actifio connector
##

param (
[string]$ActifioIP = ""
)

if ($ActifioIP -eq "") {
    $ActifioIP    = Read-Host -Prompt 'Please enter the Actifio IP address '
}

# Path for the temporary workdir
$workdir = $env:TEMP

# Download the Actifio connector software fromt the Actifio appliance
$source = "http://$ActifioIP/connector-Win32-latestversion.exe"
$destination = "$workdir\connector.exe"

# Check if Invoke-Webrequest exists otherwise execute WebClient
if (Get-Command 'Invoke-Webrequest') {
     Invoke-WebRequest $source -OutFile $destination
} else {
    $WebClient = New-Object System.Net.WebClient
    $webclient.DownloadFile($source, $destination)
}

# Kick off the installation of the Actifio connector
# /type=compact is to not install the Filter Driver
# Start-Process -FilePath "$workdir\connector.exe" -ArgumentList "/silent /type=compact "

# /type=full is to install the Filter Driver
Start-Process -FilePath "$workdir\connector.exe" -ArgumentList "/silent /type=full "

# Wait XX Seconds for the installation to finish
Start-Sleep -s 35

# Remove the installer directory
Remove-Item $workdir\connector.exe -Force
