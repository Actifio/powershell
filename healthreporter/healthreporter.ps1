####   This script should not require any changes
param([string]$configfile = "configfile")
. ./$configfile
$cleanlist = ""
$badoutput = ""
[int]$total = 0
[int]$clean = 0
$currentdate = (get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")
$data = Import-Csv -Path $appliancelist -Header "ApplianceName","ApplianceIP" -Delimiter ","
foreach ($item in $data){
  if (!$keyfile) { Connect-Act -acthost $item.ApplianceIP -actuser $user -password $password -ignorecerts }
  if (!$password) { Connect-Act -acthost $item.ApplianceIP -actuser $user -passwordfile $keyfile -ignorecerts }
  $healthcheck = reporthealth -flnm | select  CheckName,Result,Status
  if (@($healthcheck).count -eq 1) { $cleanlist += $item.ApplianceName  
  $cleanlist += "`n"
  $clean = $clean +1 }
  if (@($healthcheck).count -ne 1) { $badoutput += $healthcheck | out-string
  $badoutput += "`n"}
  $total = $total +1
  disconnect-act
}
$mailbody = "<html> `n"
$mailbody += "<body> `n"
$mailbody += "<pre style=font: monospace> `n"
$mailbody += "Report created on $currentdate `n"
$mailbody += "#################################### `n"
$mailbody += Write-Output "$total Appliances were checked and $clean Clean Appliances were found.  Appliances with messages are displayed below: `n"
$mailbody += "-------------------------------------------------------------------------------- `n"
$mailbody += $badoutput
$mailbody += "`n"
$mailbody += "-------------------------------------------------------------------------------- `n"
$mailbody += "The following Appliances were clean: `n"
$mailbody += $cleanlist
$mailbody += "`n"
$mailbody += "</pre> `n"
$mailbody += "</body> `n"
$mailbody += "</html> `n"
Send-MailMessage -From $fromaddr -To $dest -Body $mailbody -SMTP $mailserver -subject $subject -BodyAsHtml 
