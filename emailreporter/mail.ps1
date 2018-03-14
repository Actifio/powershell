####   This script should not require any changes
param([string]$configfile = "configfile")
. ./$configfile
$data = Import-Csv -Path $appliancelist -Header "ApplianceName","ApplianceIP" -Delimiter ","
$mailbody = "<html>"
$mailbody += "<body>"
$mailbody += "<pre style=font: monospace>"
$addresses = Get-content "iplist.txt"
foreach ($item in $data){
  if (!$keyfile) { Connect-Act -acthost $item.ApplianceIP -actuser $user -password $password -ignorecerts }
  if (!$password) { Connect-Act -acthost $item.ApplianceIP -actuser $user -passwordfile $keyfile -ignorecerts }
  $mailbody += "##################     "
  $mailbody += $item.ApplianceName
  $mailbody += "     ##################"
  $mailbody += "`n"
  $mailbody += Invoke-Expression $command | format-table | out-string
  disconnect-act
}
$mailbody += "</pre>"
$mailbody += "</body>"
$mailbody += "</html>"
$mailbody
Send-MailMessage -From $fromaddr -To $dest -Body $mailbody -SMTP $mailserver -subject $subject -BodyAsHtml 
