# 
## File: mail.ps1
## Purpose: Emails output of command defined in config.ps1 for a list of appliances
## This script should not require any changes unless you want to change email formatting
#

param([string]$configfile = $null)

if (! $configfile) {
    write-host "Usage: .\mail.ps1 -configfile [ full pathname of the config file ]"
    write-host "Example: .\mail.ps1 -configfile c:\actifio\config.ps1"
    break
}

. ./$configfile
$currentdate = (get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")
$data = Import-Csv -Path $appliancelist -Header "ApplianceName","ApplianceIP" -Delimiter ","
$mailbody = "<html> `n"
$mailbody += "<body> `n"
$mailbody += "<pre style=font: monospace> `n"
$mailbody += "Report created on $currentdate `n"
$mailbody += "############################################################################# `n"
foreach ($item in $data){
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
Send-MailMessage -From $fromaddr -To $dest -Body $mailbody -SMTP $mailserver -subject $subject -BodyAsHtml 

