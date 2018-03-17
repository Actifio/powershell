# 
## File: mail.ps1
## Purpose: Emails output of command defined in config.ps1 for a list of appliances
## This script should not require any changes unless you want to change email formatting
#

param([string]$paramfile = $null)

if (! $paramfile) {
    write-host "You did not specify a paramater file which is needed for this script to work"
    write-host "Usage: .\mail.ps1 -paramfile [ full pathname of the parameter file ]"
    write-host "Example: .\mail.ps1 -paramfile c:\actifio\actparams.ps1"
    break
}

# Loads the parameter file in $paramfile
. $paramfile

# grabs the current date to use in the email body
$currentdate = (get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")

# parse the appliance list and load into an array
$data = Import-Csv -Path $appliancelist -Header "ApplianceName","ApplianceIP" -Delimiter ","

#  the html is used to format the mail body nicely with monospace font
$mailbody = "<html> `n"
$mailbody += "<body> `n"
$mailbody += "<pre style=font: monospace> `n"
$mailbody += "Report created on $currentdate `n"
$mailbody += "############################################################################# `n"

#  this loop logs into each appliance using either plain text password or password key file and then run the defined command
foreach ($item in $data){
  if (!$item.ApplianceIP) { 
    write-host "The appliancelist is not formatted correctly, there is a blank IP address"
    continue
  }
  if (!$keyfile) { Connect-Act -acthost $item.ApplianceIP -actuser $user -password $password -ignorecerts }
  if (!$password) { Connect-Act -acthost $item.ApplianceIP -actuser $user -passwordfile $keyfile -ignorecerts }
  $mailbody += "Appliance:  "
  $mailbody += $item.ApplianceName 
  $mailbody += "`n"
  $mailbody += Invoke-Expression $command | format-table | out-string
  $mailbody += "---------------------------------- `n"
  disconnect-act
}
$mailbody += "</pre> `n"
$mailbody += "</body> `n"
$mailbody += "</html> `n"

# we now mail out the file
Send-MailMessage -From $fromaddr -To $dest -Body $mailbody -SMTP $mailserver -subject $subject -BodyAsHtml 

# if mail is not working and you want to see the output of the mail body unhash the following line
# $mailbody

