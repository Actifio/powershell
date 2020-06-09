# 
## File: Vdp-Helper.ps1
## Purpose: List of reusable functions that can simplify VDP related commands on a Windows server.
#
# Version 1.0 Initial Release
#
# Import-Module .\Vdp-Helper.psm1 -Verbose -Force
# Remove-Module .\Vdp-Helper.psm1
<#   
.SYNOPSIS   
   Download and include this script in your PowerShell script.
.DESCRIPTION 
   This is a powershell script that helps you simplify the VDP related operations.
.NOTES   
    Name: Vdp-Helper.ps1
    Author: Michael Chew
    DateCreated: 12-May-2020
    LastUpdated: 12-May-2020
.LINK
    https://github.com/Actifio/powershell/blob/master/Vdp-Helper
#>

Function Vdp-Disable-WorkflowName()
<#
.SYNOPSIS
    Disable workflow.
.DESCRIPTION
     Disable-WorkflowID is a Function Vdp-that is used to disable the workflow.
.EXAMPLE
     Disable-WorkflowID $wf-ID
#>
{
#    [CmdletBinding()]    
    param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()] 
        [string]$WorkflowName)

    $WorkflowID = $(udsinfo lsworkflow | where-object name -eq $WorkflowName).id
    if (! $WorkflowID ) {   
        return $null;
    }    
    $WorkflowStatus = $(udsinfo lsworkflow | where-object id -eq $WorkflowID).disabled
    if ($WorkflowStatus -eq $false) {
        write-host "Disabling workflow id ( $WorkflowID ) for $WorkflowName"
        write-host "udstask chworkflow -disable true $WorkflowID"  
        udstask chworkflow -disable true $WorkflowID | out-null
    } else {
        write-host "Workflow id ( $WorkflowID ) for $WorkflowName is already disabled!!"    
    }
    return $true
}

Function Vdp-Enable-WorkflowName()
{
#    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]        
        [ValidateNotNullOrEmpty()] 
        [string]$WorkflowName)

    $WorkflowID = $(udsinfo lsworkflow | where-object name -eq $WorkflowName).id
    if (! $WorkflowID ) {   
        return $null;
    }
    $WorkflowStatus = $(udsinfo lsworkflow | where-object id -eq $WorkflowID).disabled
    if ($WorkflowStatus -eq $true) {
        write-host "Enabling workflow id ( $WorkflowID ) for $WorkflowName"
        write-host "udstask chworkflow -disable false $WorkflowID"  
        udstask chworkflow -disable true $WorkflowID | out-null
    } else {
        write-host "Workflow id ( $WorkflowID ) for $WorkflowName is already enabled!!"    
    }
    return $true
}

Function Vdp-Run-WorkflowName()
{        
#    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]        
        [ValidateNotNullOrEmpty()] 
        [string]$WorkflowName)

    $WorkflowID = $(udsinfo lsworkflow | where-object name -eq $WorkflowName).id
    if (! $WorkflowID ) {   
        return $null;
    }
    $rc = udstask runworkflow $WorkflowID    
    if ($rc -eq $null) { 
        write-output "Unable to kickoff workflow $WorkflowID" 
    } else { 
        write-output "Successfully kickoff workflow $WorkflowID" 
    }
    return $rc
}

Function Vdp-Run-WorkflowName-Image()
{
    param (
        [Parameter(Mandatory=$True)]        
        [ValidateNotNullOrEmpty()] 
        [string]$WorkflowName,
        [Parameter(Mandatory=$True)]        
        [ValidateNotNullOrEmpty()] 
        [string]$ImageName        
        )

    $WorkflowID = $(udsinfo lsworkflow | where-object name -eq $WorkflowName).id
    if (! $WorkflowID ) {   
        return $null;
    }
   
    $TmpWorkflowID = $(udstask cloneworkflow $WorkflowID).result
    udstask addflowproperty -name image -value $ImageName $TmpWorkflowID
    $rc = udstask runworkflow $TmpWorkflowID 

    if ($rc -eq $null) { 
        write-output "Unable to kickoff workflow $WorkflowID" 
    } else { 
        write-output "Successfully kickoff workflow $WorkflowID" 
    }
    return $rc
}

Function Vdp-Remove-WorkflowName()
{
#    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]        
        [ValidateNotNullOrEmpty()] 
        [string]$WorkflowName)    

    $WorkflowID = $(udsinfo lsworkflow | where-object name -eq $WorkflowName).id 
    if (! $rc ) {   
        return $null;
    }
    write-output "Removing workflow $WorkflowName.." 
    udstask rmworkflow $WorkflowID
    return $rc
}

Function Vdp-Status-WorkflowName()
{        
#    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]        
        [ValidateNotNullOrEmpty()] 
        [string]$WorkflowName)

    # FAILED , RUNNING
    $rc = $(reportworkflows -s | where-object WorkflowName -eq $WorkflowName).status
    if (! $rc ) {   
        return $null;
    }
    return $rc
}

Function Vdp-Get-WorkflowID()
{    
#    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]        
        [ValidateNotNullOrEmpty()] 
        [string]$WorkflowName)

    $WorkflowID = $(udsinfo lsworkflow | where-object name -eq $WorkflowName).id    
    if (! $WorkflowID ) {       
        return 0;    
    } else {        
        return $WorkflowID    
    }    
}

Function Vdp-ConvertTo-HostID()
{
#    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$Host_Name,

        [Bool]$Is_VM=$False)

    $HostID = $(udsinfo lshost -filtervalue "hostname=$Host_Name&isvm=$Is_VM").id
    if (! $HostID ) {
        return 0;
    } else {
        return $HostID
    }
}

Function Vdp-ConvertTo-AppID()
{
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$HostID,
        [Parameter(Mandatory=$True)]    
        [string]$AppName )

    $AppId = $(udsinfo lsapplication -filtervalue "appname=$AppName&hostid=$HostID").id

    if (! $AppID ) {
        write-warning "`nInvalid Source App Not Found`n"
    }
    return $AppID
}

Function Vdp-ConvertTo-SlaID() 
{
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()]   
        [string]$AppID )

    $SlaID = $(udsinfo lssla -filtervalue "appid=$AppID").id
    return $SlaID
}

Function Vdp-Get-AppAware-JobID()
{
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$HostName,
        [Parameter(Mandatory=$True)]    
        [string]$AppName )

    $JobID = $(reportrunningjobs | where { $_.HostName -eq $HostName -And $_.AppName -eq $AppName -And $_.JobClass -eq 'mount(AppAware)' }).JobName
    return $JobID
}

Function Vdp-Get-Unmount-JobID()
{
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$HostName,
        [Parameter(Mandatory=$True)]    
        [string]$AppName )

    $JobID = $(reportrunningjobs | where { $_.HostName -eq $HostName -And $_.AppName -eq $AppName -And $_.JobClass -eq 'unmount-delete' }).JobName
    return $JobID
}

Function Vdp-List-Workflows()
{
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$AppID )

    [PSCustomObject[]] $Array = @()

    $WorkflowList = $(reportworkflows | where-object SourceAppID -eq $AppID)

    $WorkflowList | ForEach-Object {
        $myRec = New-Object PSCustomObject
        $myRec | Add-Member -type NoteProperty -name Name -Value $_.WorkflowName
        $myRec | Add-Member -type NoteProperty -name Type -Value $_.Type
        $myRec | Add-Member -type NoteProperty -name ID -Value $_.ID
        $myRec | Add-Member -type NoteProperty -name TgtHostName -Value $_.TargetHosts
        $myRec | Add-Member -type NoteProperty -name SrcHostName -Value $_.SourceHostName
        $myRec | Add-Member -type NoteProperty -name TgtAppName -Value $_.TargetApp

        if ($_.ScheduleTime -eq "n/a") {
            $myRec | Add-Member -type NoteProperty -name OnDemand -Value $true
        } else {
            $myRec | Add-Member -type NoteProperty -name OnDemand -Value $false
        }

        $Array += $myRec
    }

    return $Array
}

Function Vdp-List-Hosts()
{

    [PSCustomObject[]] $Array = @()

    $(udsinfo lshost) | ForEach-Object {
        $myRec = New-Object PSCustomObject
        $myRec | Add-Member -type NoteProperty -name ID -Value $_.id
        $myRec | Add-Member -type NoteProperty -name HostName -Value $_.hostname
        $myRec | Add-Member -type NoteProperty -name VMtype -Value $_.vmtype
        $myRec | Add-Member -type NoteProperty -name IPAddress -Value $_.ipaddress
        $myRec | Add-Member -type NoteProperty -name OsType -Value $_.ostype
        $Array += $myRec
    }
    return $Array
}

Function Vdp-List-Apps()
{
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$HostID )

    [PSCustomObject[]] $Array = @()

    $(udsinfo lsapplication -filtervalue "hostid=$HostID" ) | ForEach-Object {
        $myRec = New-Object PSCustomObject
        $myRec | Add-Member -type NoteProperty -name ID -Value $_.id
        $myRec | Add-Member -type NoteProperty -name AppName -Value $_.appname
        $myRec | Add-Member -type NoteProperty -name AppType -Value $_.apptype
        $myRec | Add-Member -type NoteProperty -name AppClass -Value $_.appclass
        $Array += $myRec
    }
    return $Array    
}

Function Vdp-Expire-Image()
{
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$ImageName )

    $rc = udstask expireimage -image $ImageName
}

Function Vdp-Change-Image-Expiration()
{
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$ImageName,
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [int]$NumHours )

    ## Add 18 hours to the expiration
    $ExpDate = (Get-Date).AddHours($NumHours)

    $ExpDateFormatted = $ExpDate.year.ToString() + "-" + $ExpDate.month.ToString() + "-" + $ExpDate.day.ToString() + " " + $ExpDate.hour.ToString() + ":" + $ExpDate.minute.ToString() + "00"
    $rc = udstask chbackup -expiration $ExpDateFormatted $ImageName

}
Function Vdp-List-Images()
{
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$AppID,
        [Parameter(Mandatory=$True)]  
        [ValidateSet('snapshot','dedup')] 
        [string]$ImageType = $null )

    [PSCustomObject[]] $Array = @()

    $(udsinfo lsbackup -filtervalue "appid=$AppID&jobclass=$ImageType") | ForEach-Object {
        $myRec = New-Object PSCustomObject
        $myRec | Add-Member -type NoteProperty -name ImageName -Value $_.backupname
        $myRec | Add-Member -type NoteProperty -name BackupDate -Value $_.backupdate
        $myRec | Add-Member -type NoteProperty -name AppType -Value $_.apptype
        $Array += $myRec
    }

    return $Array
}

Function Vdp-List-Job-Stats()
{
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$JobID,
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$AppID,
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()]
        [string]$AppName )

    $start = $(udsinfo lsjobhistory $JobID).startdate
    $duration = $(udsinfo lsjobhistory $JobID).duration
    $vsize = $(udsinfo lsjobhistory $JobID)."Application size (GB)"
    $tgthost = $(udsinfo lsjobhistory $JobID).targethost
    $usedGB = $(reportmountedimages | where { $_.SourceAppID -eq $AppID -And $_.MountedHost -eq $tgthost -And $_.MountedAppName -eq $AppName } )."ConsumedSize(GB)"

    write-output "Job started at $start , and took $duration to complete."
    write-output "The size of $AppName on $tgthost is $vsize GB, actual storage consumed in GB is $usedGB "
}

Function Vdp-Remove-Existing-Mount()
{
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$SrcAppName,
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$SrcHostName,
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$TgtAppName,
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$TgtHostName )

    $cmd = $(reportmountedimages | where-object { $_.SourceHost -eq $SrcHostName -And $_.SourceApp -eq $SrcAppName -And $_.MountedHost -eq $TgtHostName -And $_.MountedAppName -eq $TgtAppName }).UnmountDeleteCommand
    write-output "Unmounting the $TgtAppName DB on $TgtHostName `n"
    Invoke-Expression $cmd | out-null
}

Function Vdp-Get-Latest-App-Image()
{
    param ( 
        [Parameter(Mandatory=$True)]  
        [string]$AppID = $null ,
        [Parameter(Mandatory=$True)]  
        [string]$JobType = $null
        )

    $allJobs = @("snapshot","dedup")
    if ($allJobs -notcontains $JobType) {
        throw "JobType must be one of the following: $allJobs"
    }

    $Backups = $(udsinfo lsbackup -filtervalue "jobclass=$JobType&appid=$AppID")
    if (! $Backups){
        write-warning "`nNo Images for Source App`n"
        return $null
    }
    $ImageName = $Backups[-1].backupname
    return $ImageName
}

Function Vdp-Wait-For-JobID-End()
{
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$JobID )

    $JobStatus = $(reportrunningjobs | where { $_.JobName -eq $JobID }).status
    $PrevJobPct = "0"
    if ($JobStatus -eq 'running') {
        Write-Host "Job is now running.... "
        while ('running' -eq $JobStatus) {
            $JobPct = $(reportrunningjobs | where { $_.JobName -eq $JobID })."Progress%"
            if ($PrevJobPct -ne $JobPct) {
               $PrevJobPct = $JobPct
               sleep -Seconds 5
               Write-Host "- Progress% : $JobPct ..."
             }
             $JobStatus = $(reportrunningjobs | where { $_.JobName -eq $JobID }).status
             }
        }
}

Function Vdp-Login-VDP-Password ()
{
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$VdpIP,
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$VdpUser,
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$VdpPassword )

    $env:IGNOREACTCERTS = $true
    write-host "`nConnecting to VDP ($VdpIP)..." -nonewline
    if (! $env:ACTSESSIONID ){
        connect-act -acthost $VdpIP -actuser $VdpUser -password $VdpPassword -ignorecerts -quiet
    }

    if (! $env:ACTSESSIONID ){
        write-warning "Unable to login to VDP ($VdpIP)!!"
        return $false
    }
    return $true
}

Function Vdp-Login-VDP-PasswordFile ()
{
    param (
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$VdpIP,
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$VdpUser,
        [Parameter(Mandatory=$True)]   
        [ValidateNotNullOrEmpty()] 
        [string]$VdpPasswordFile )

    if ( ! (Test-Path -path $VdpPasswordFile)) {
        write-warning "Missing password file ($VdpPasswordFile) for appliance $VdpIP"
        return $false
    }

    $env:IGNOREACTCERTS = $true
    write-host "`nConnecting to VDP ($VdpIP)..." -nonewline
    if (! $env:ACTSESSIONID ){
        connect-act -acthost $VdpIP -actuser $VdpUser -passwordfile $VdpPasswordFile -ignorecerts -quiet
    }

    if (! $env:ACTSESSIONID ){
        write-warning "Unable to login to VDP ($VdpIP)!!"
        return $false
    }
    return $true
}

Function Vdp-Logoff-VDP ()
{
    if (! $env:ACTSESSIONID ){
        write-warning "Unable to logoff from VDP appliance"
        break
    } else {
        Disconnect-Act | Out-Null
    } 
}

Function Vdp-Load-Module()
{
    $ModuleName = "ActPowerCLI"
    if ( (Get-Module -ListAvailable -Name $ModuleName) -ne $null ) {
        Import-Module $ModuleName -ErrorVariable err -errorAction SilentlyContinue
    }
}

Export-ModuleMember Vdp-Disable-WorkflowName
Export-ModuleMember Vdp-Enable-WorkflowName
Export-ModuleMember Vdp-Run-WorkflowName
Export-ModuleMember Vdp-Run-WorkflowName-Image
Export-ModuleMember Vdp-Remove-WorkflowName
Export-ModuleMember Vdp-Status-WorkflowName
Export-ModuleMember Vdp-Get-WorkflowID
Export-ModuleMember Vdp-List-Workflows

Export-ModuleMember Vdp-ConvertTo-HostID
Export-ModuleMember Vdp-ConvertTo-AppID
Export-ModuleMember Vdp-ConvertTo-SlaID 

Export-ModuleMember Vdp-Get-AppAware-JobID
Export-ModuleMember Vdp-Get-Unmount-JobID

Export-ModuleMember Vdp-List-Hosts
Export-ModuleMember Vdp-List-Apps

Export-ModuleMember Vdp-Expire-Image
Export-ModuleMember Vdp-Change-Image-Expiration
Export-ModuleMember Vdp-List-Images
Export-ModuleMember Vdp-Get-Latest-App-Image

Export-ModuleMember Vdp-Remove-Existing-Mount

Export-ModuleMember Vdp-List-Job-Stats
Export-ModuleMember Vdp-Wait-For-JobID-End

Export-ModuleMember Vdp-Login-VDP-Password 
Export-ModuleMember Vdp-Login-VDP-PasswordFile 
Export-ModuleMember Vdp-Logoff-VDP 
Export-ModuleMember Vdp-Load-Module
