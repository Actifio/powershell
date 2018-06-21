#
# act-protect-new-vms.ps1 -- OnVault version
#
# NOTE: This script requires the CDS or Sky appliances to be running 7.0.6+ or 7.1.2+ or higher.
#       If this is not possible, manual installation of "reporthealth" SARG report is required.
#
# This script will connect to the Actifio CDS or Sky systems specified in the appliances.txt
# file and will build a list of all protected VMware VMs.  It will then initiate a VM
# discovery (list) for all VMs in specified ESX clusters (based on protectionrules.txt file).
# Any previously undiscovered VMs will be added to one of the appliances and a template and
# profile will be applied, based on the configuration data in the protectionrules.txt file.
#
# New VM protection will use the following logic to determine which of the Actifio appliances
# will be used for the protection, and on all other appliances that same VM will be flagged
# as "ignored".
#
# Appliance with the lowest amount of MDL consumed, where:
#   - the appliance is not over the snap pool warning threshold
#   - the appliance is not over the Vdisk warning threshold
#
# It is designed to be called from a scheduled task on a Windows server, and expects that
# auto-discovery has been disabled on the desired vCenter servers using the CLI (udstask
# setautodiscovery -host <vcenterhost> -clear) or GUI (de-select auto-discover box on
# the host management page in Domain Manager).
#
# This script requires ActPowerCLI to be installed first on any server that will use it.
#
# User must generate a password file with Save-ActPassword command for each appliance, and
# reference this filename in the "appliances.txt" file.  Be aware that a file generated with
# Save-ActPassword is only readable when on the same server where generated, and only while
# logged in as the same user (i.e. service account) as the one who generated the file.
#

# Script Parameters
param([switch]$debug=$false)

###############################
# Login to appliance function #
###############################

function log-output {
    Param([Parameter(Mandatory=$true)][string]$logfile,[switch]$debugOnly=$false,[string]$message)

    if ($debugOnly -and !$debug)
    {
        return
    }
    $logstamp = Get-Date -format "yyyy-MM-dd_HH-mm-ss"
    ($logstamp + " - " + $message) | Out-File $logfile -append
}

function act-login {
    Param([string]$appliance,[string]$user,[string]$pwfile)

    if ($env:ACTSESSIONID )
    {
        Disconnect-Act | Out-Null
    }

    if (! $appliance )
    {
        log-output -logfile $logfile -message "WARNING: Missing appliance name"
        break
    }
    if (! $user )
    {
        log-output -logfile $logfile -message "WARNING: Missing user name for appliance $appliance"
        break
    }
    if ((! $pwfile ) -or (!(test-path $scriptPath\$pwfile)))
    {
        log-output -logfile $logfile -message "WARNING: Missing password file or file not found for appliance $appliance"
        break
    }

    connect-act $appliance $user -passwordfile $scriptPath\$pwfile -quiet -ignorecert
    if (! $env:ACTSESSIONID )
    {
        return 1
    } else {
        return 0
    }

}

####################################
# Select target appliance function #
####################################

function select-target {
    Param([string]$profile)
    foreach ($a in ($mdl | sort usedmdl).appliance)
    {
        # Verify this appliance is not ineligible due to a config error or offline
        if ( $ineligibleappliances.$a -eq "true")
        {
            log-output -logfile $logfile -debugonly -message ("Appliance $a is ineligible and cannot be the target.")
            continue
        }

        # Check snap pool is below warning threshold
        if (($pools.$a | where name -eq ($slps.$a | where name -eq $profile).performancepool).warnstate -eq "true")
        {
            log-output -logfile $logfile -debugonly -message ("Appliance $a snap pool is over warning threshold and therefore it cannot be the target.")
            continue
        }

        # Check vdisk count is below warning threshold
        if ($vdisksabovethreshold.$a -eq "true")
        {
            log-output -logfile $logfile -debugonly -message ("Appliance $a Vdisk count is over warning threshold and therefore it cannot be the target.")
            continue
        }
        return $a
    }
    return
}


#####################
# Setup Environment #
#####################

$pshost = get-host
$pswindow = $pshost.ui.rawui
$newsize = $pswindow.buffersize
$newsize.height = 3000
$newsize.width = 150
$pswindow.buffersize = $newsize
$newsize = $pswindow.windowsize
$newsize.height = 50
$newsize.width = 150
$pswindow.windowsize = $newsize

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = split-path -leaf $MyInvocation.MyCommand.Definition
$scriptBaseName = (get-childitem $MyInvocation.MyCommand.Definition).BaseName
$logstamp = Get-Date -format "yyyy-MM-dd_HH-mm-ss"
$logfile = $scriptPath + "\" + $scriptBaseName + "_" + $logstamp + ".log"
log-output -logfile $logfile -message "Started..."

$apps=@{}
$hosts=@{}
$slas=@{}
$slps=@{}
$slts=@{}
$pools=@{}
$vdisksabovethreshold=@{}
$ineligibleappliances=@{}
$mdl=@()
$protectedvms=@()
$ignoredvms=@()

###########################
# Read Configuration Data #
###########################

if (!(test-path $scriptPath\appliances.txt))
{
    log-output -logfile $logfile -message "WARNING: Cannot find appliances.txt file"
    break
}

if (!(test-path $scriptPath\protectionrules.txt))
{
    log-output -logfile $logfile -message "WARNING: Cannot find protectionrules.txt file"
    break
}

log-output -logfile $logfile -debugonly -message "Reading configuration files..."
$appliances = Import-csv $scriptPath\appliances.txt
$protectionrules = Import-csv $scriptPath\protectionrules.txt

#############################################################
# Loop through appliances and gather all needed information #
#############################################################

foreach ($a in $appliances)
{
    # Start out with a clean slate
    $ineligibleappliances.($a.appliance)="false"

    # Login to the appliance
    log-output -logfile $logfile -debugonly -message ("Logging in to appliance " + $a.appliance)
    if (act-login -appliance $a.appliance -user $a.user -pwfile $a.pwfile)
    {
        log-output -logfile $logfile -message ("WARNING: Login to " + $a.appliance + " failed")
        $ineligibleappliances.($a.appliance)="true"
        break
    }

    #############################################################################################
    # Build a table of VM apps, hosts, SLAs, Protected and Ignored VMs, Profiles, and Templates #
    #############################################################################################

    # First build tables of all VM apps, hosts, SLAs, SLPs, and SLTs stored per appliance
    log-output -logfile $logfile -debugonly -message ("Retrieving apps, hosts, slas for appliance " + $a.appliance)
    $apps.($a.appliance)=udsinfo lsapplication -filtervalue apptype=VMBackup
    $hosts.($a.appliance)=udsinfo lshost -filtervalue vmtype=vmware
    $slas.($a.appliance)=udsinfo lssla
    $slps.($a.appliance)=udsinfo lsslp
    $slts.($a.appliance)=udsinfo lsslt

    # And then validate specified vcenter, template, and profile in config files exist #
    $vc = udsinfo lshost -filtervalue isvcenterhost=true $a.vcenter
    if ( $vc.isvcenterhost -ne "true" )
    {
        log-output -logfile $logfile -message ("WARNING: vCenter " + $a.vcenter + " does not exist or is not a vCenter host on appliance " + $a.appliance)
        $ineligibleappliances.($a.appliance)="true"
    }

    foreach ($line in $protectionrules)
    {
        if (! ($slps.($a.appliance) | where name -ceq $line.profile))
        {
            log-output -logfile $logfile -message ("WARNING: Profile " + $line.profile + " does not exist on appliance " + $a.appliance)
            $ineligibleappliances.($a.appliance)="true"
        }
        if (! ($slts.($a.appliance) | where name -ceq $line.template))
        {
            log-output -logfile $logfile -message ("WARNING: Template " + $line.template + " does not exist on appliance " + $a.appliance)
            $ineligibleappliances.($a.appliance)="true"
        }
    }

    # Second, build tables of all protected VMs (merged across all appliances)
    log-output -logfile $logfile -debugonly -message ("Building protected and ignored VMs lists for appliance " + $a.appliance)
    foreach ($v in $apps.($a.appliance))
    {
        #  Add protected VMs to the master protected list
        if ($slas.($a.appliance) | where appid -eq $v.id)
        {
        log-output -logfile $logfile -debugonly -message ("Adding " + $v.appname + " to protected list for appliance " + $a.appliance)
            $protectedvms += ($hosts.($a.appliance) | where id -eq $v.hostid).uniquename
        }

        # Add ignored VMs to the master ignored list
        if ($v.ignore -eq "true")
        {
        log-output -logfile $logfile -debugonly -message ("Adding " + $v.appname + " to ignored list for appliance " + $a.appliance)
            $ignoredvms += ($hosts.($a.appliance) | where id -eq $v.hostid).uniquename
        }
    }

    #############################################################################
    # Get all system resource usage, including all needed disk pools and vdisks #
    #############################################################################
    $temppools = udsinfo lsdiskpool
    $localpools=@()

    # First, get snap pool status
    foreach ($t in ($temppools | where pooltype -eq "perf"))
    {
        log-output -logfile $logfile -debugonly -message ("Retrieving detail for pool " + $t.name)
        $pooldetail = udsinfo lsdiskpool $t.name
        $pool = New-Object System.Object
        $pool | Add-Member -type NoteProperty -name name -value $pooldetail.name
        $pool | Add-Member -type NoteProperty -name pooltype -value $pooldetail.pooltype
        $pool | Add-Member -type NoteProperty -name usedpct -value ($pooldetail.used / $pooldetail.capacity * 100)
        if ( $pool.usedpct -ge $pooldetail.warnpct )
        {
            $pool | Add-Member -type NoteProperty -name warnstate -value "true"
        } else {
            $pool | Add-Member -type NoteProperty -name warnstate -value "false"
        }
        $localpools += $pool
    }
    $pools.($a.appliance) = $localpools

    # Now get the status for VDisk usage (calculated by reporthealth, available in 7.0.3 and up)
    log-output -logfile $logfile -debugonly -message ("Retrieving vdisk status on appliance " + $a.appliance)
    if ( (reporthealth | where Checkname -eq "VDisk usage").Status -eq "Passed" )
    {
        $vdisksabovethreshold.($a.appliance)="false"
    } else {
        $vdisksabovethreshold.($a.appliance)="true"
    }

    # Finally, get the MDL for this appliance and add to sortable array
    log-output -logfile $logfile -debugonly -message ("Retrieving MDL usage on appliance " + $a.appliance)
    $usedmdl = (udsinfo lsmdlstat -filtervalue appid=0 | Select-Object -last 1).manageddata
    $mdlobj = New-Object System.Object
    $mdlobj | Add-Member -type NoteProperty -name appliance -value $a.appliance
    $mdlobj | Add-Member -type NoteProperty -name usedmdl -value $usedmdl
    $mdl += $mdlobj

    log-output -logfile $logfile -debugonly -message ("Done collecting information from appliance " + $a.appliance)

    log-output -logfile $logfile -debugonly -message ("Logging out of appliance " + $a.appliance)
    Disconnect-Act | Out-Null

}

######################################################
# Loop through ESX clusters specified in config file #
######################################################

foreach ($c in $protectionrules)
{
    # Select a taget appliance based on MDL consumed, but accounting for other limits in snap pool
    # specified in resource profile
    Remove-Variable -ErrorAction SilentlyContinue target
    $target = select-target($c.profile)
    if (! $target)
    {
        log-output -logfile $logfile -message ("WARNING: No valid target appliance for ESX cluster " + $c.esxcluster)
        continue
    }

    ####################################################
    # Get list of all VMs in the specified ESX cluster #
    ####################################################

    # First, login to the target appliance
    if (act-login -appliance $target -user ($appliances | where appliance -eq $target).user -pwfile ($appliances | where appliance -eq $target).pwfile)
    {
        log-output -logfile $logfile -message "WARNING: Login to $target failed"
        break
    }

    # Run a VM discovery of the specified ESX cluster to get a list of all VMs
    $discoveredvms = udstask vmdiscovery -discovervms -host ($appliances | where appliance -eq $target).vcenter -cluster $c.esxcluster

    # Check for each discovered VM if it is protected or ignored.  If neither, protect it
    foreach ($v in $discoveredvms)
    {
        # Skip VMs already protected (anywhere)
        if ($protectedvms -contains $v.uuid)
        {
            continue
        }
        # Skip VMs that are ignored (anywhere)
        if ($ignoredvms -contains $v.uuid)
        {
            continue
        }

        # If we made it here, we need to protect the VM

        # First we will discover it on the target appliance, only if needed, and add to apps and hosts list
        if (! ($hosts.$target | where uniquename -eq $v.uuid))
        {
            log-output -logfile $logfile -message ("Adding new VM " + $v.vmname + " on appliance $target.")
            udstask vmdiscovery -addvms -host ($appliances | where appliance -eq $target).vcenter -cluster $c.esxcluster -vms $v.vmname
            $hosts.$target += udsinfo lshost -filtervalue uniquename=($v.uuid)
            Remove-Variable -ErrorAction SilentlyContinue hostid
            $hostid=($hosts.$target | where uniquename -eq $v.uuid).id
            $apps.$target += udsinfo lsapplication -filtervalue apptype=VMBackup'&'hostid=$hostid
        }

        # And now protect it
        log-output -logfile $logfile -message ("Adding protection for VM " + $v.vmname + " on appliance $target.")
        $mkslaresult=udstask mksla -appid ($apps.$target | where hostid -eq ($hosts.$target | where uniquename -eq $v.uuid).id).id -slp $c.profile -slt $c.template
        if ($mkslaresult.result)
        {
            log-output -logfile $logfile -message ("VM " + $v.vmname + " protected with SLA ID " + $mkslaresult.result)
        } else {
            log-output -logfile $logfile -message ("WARNING: VM " + $v.vmname + " protection failed with error " + $mkslaresult.errorcode + " " + $mkslaresult.errormessage)
        }
    }

    Disconnect-Act | Out-Null
}
log-output -logfile $logfile -message "Finished"

