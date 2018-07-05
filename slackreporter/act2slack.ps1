# 
## File: act2slack2.ps1
## Purpose: Sends a post to slack
## This script should not require any changes unless you want to change report formatting
#

param([string]$paramfile = $null,[string]$runcommand = $null)

if (! $paramfile) {
    write-host "You did not specify a paramater file which is needed for this script to work"
    write-host "Usage: .\act2slack.ps1 -paramfile [ full pathname of the parameter file ]"
    write-host "Example: .\act2slack.ps1 -paramfile c:\actifio\slackparams.ps1"
    break
}

# Loads the parameter file in $paramfile
. $paramfile

# we either run the command specified in the param file or a manual one specified with -runcommand
if ($runcommand) { 
    $command = $runcommand 
    $reportname = $runcommand 
}

# parse the appliance list and load into an array
$data = Import-Csv -Path $appliancelist -Header "ApplianceName","ApplianceIP" -Delimiter ","

# grabs the current date to use in the email body
$currentdate = (get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")

# now go through each appliance and run the required command against it
foreach ($item in $data){
  if (!$item.ApplianceIP) { 
    write-host "The appliancelist is not formatted correctly, there is a blank IP address"
    continue
  }	
  if (!$keyfile) { $connectattempt=$(Connect-Act -acthost $item.ApplianceIP -actuser $user -password $password -ignorecerts) }
  if (!$password) { $connectattempt=$(Connect-Act -acthost $item.ApplianceIP -actuser $user -passwordfile $keyfile -ignorecerts) }
    
  if ($connectattempt -ne "Login Successful!") {
	write-host "Failed to login to $item with username $user"
	exit
  }


  $report = "$reportname from:  "
  $report += $item.ApplianceName 
  $report += " on $currentdate `n"
  $report += "-------------------------------------------- `n"
  $report += '```'
  $report += Invoke-Expression $command | format-table | out-string
  $report += '```'
    
  $body = @{ text=$report; channel=$Channel; username=$Username; icon_emoji=$Emoji; icon_url=$IconUrl } | ConvertTo-Json
  Invoke-WebRequest -Method Post -SslProtocol 'Tls11, Tls12' -Uri $Url -Body $body
}
