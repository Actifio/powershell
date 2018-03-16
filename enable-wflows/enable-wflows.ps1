# 
## File: disable-wflows.ps1
## Purpose: Disables the list of workflows listed in actparams.ps1 
#

param([string]$paramfile = $null)

if (! $paramfile) {
    write-host "Usage: .\disable-wflows.ps1 -paramfile [ full pathname of the parameter file ]"
    write-host "Example: .\disable-wflows.ps1 -paramfile c:\actifio\actparams.ps1"
    break
}

# Loads the parameter file in $paramfile
. $paramfile

# Ensure that the ActPowerCLI module is imported
$moduleins = get-module -listavailable -name ActPowerCLI
if ($moduleins -eq $null) {
    Import-Module ActPowerCLI
}

# Connect to the Actifio appliance
#
# Are we using passwordfile to authenticate to the Actifio appliance ?
if (Get-Variable -Name actpasswordfile -Scope Global -ErrorAction SilentlyContinue) { connect-act -acthost $acthost -actuser $actuser -passwordfile $actpasswordfile -ignorecerts -quiet }
# Are we using userID and password to authenticate to the Actifio appliance ?
if (Get-Variable -Name actpassword -Scope Global -ErrorAction SilentlyContinue) { connect-act -acthost $acthost -actuser $actuser -password $actpassword -ignorecerts -quiet }

write-host "Connected to $acthost"

# Are we using the list of workflows in $wflowlistFile file?
if (! (Get-Variable -Name wflowlistFile -Scope Global -ErrorAction SilentlyContinue)) {
  if (test-path $wflowlistFile) {
    $wflowlist = Get-Content $wflowlistFile
  } else {
    write-output "Unable to open workflow file - $wflowlistFile"
    exit 1
  }
} 

function Enable-WorkflowID(
[string]$workflowname)
{
    $workflow_id = $(udsinfo lsworkflow | where-object name -eq $workflowname).id
    $wflowstat = $(udsinfo lsworkflow | where-object id -eq $workflow_id).disabled
    if ($wflowstat -eq $true) {
        write-host "Enabling workflow id ( $workflow_id ) for $workflowname"
        write-host "udstask chworkflow -disable false $workflow_id"  
        udstask chworkflow -disable false $workflow_id | out-null
    } else {
        write-host "Workflow id ( $workflow_id ) for $workflowname is already enabled!!"    
    }
}

foreach ($wflowname in $wflowlist.split(",")) {
  Enable-WorkflowID $wflowname
}

Disconnect-Act
exit