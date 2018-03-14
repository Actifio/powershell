####   This script should not require any changes unless you want to change email formatting
param([string]$configfile = "configfile")
. ./$configfile
$currentdate = (get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")
$data = Import-Csv -Path $appliancelist -Header "ApplianceName","ApplianceIP" -Delimiter ","
$mailbody = "<html> `n"
$mailbody += "<body> `n"
$mailbody += "<pre style=font: monospace> `n"
$mailbody += "Report created on $currentdate `n"
$mailbody += "############################################################################# `n"
$addresses = Get-content "iplist.txt"
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

