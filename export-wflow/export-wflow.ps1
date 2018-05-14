#
## File: export-wflow.ps1
## Extracts all the workflow definitions to separate files - $pfx_oracle.csv $pfx_sqlserver.csv and $pfx_sqlinstance.csv
## export-wflow.ps1 -help
## export-wflow.ps1 -pfx v -afx v2
# Last Updated: May-11-2018
#

# Function Export-Workflow ([string]$targetdir = $null,[switch]$help, [string]$pfx = "v")

param([string]$targetdir = $null, [switch]$help, [string]$pfx = "v", [string]$afx = "v2")

$debug_flag = $True
# ----------------------------------------------------------------
## Outputs the $label & $val if ($val is not null/empty)
#
# ----------------------------------------------------------------
function write-not-null ($val, $label)
{
    if (($val -ne $null) -or ($val -ne "")) {
        write-host "$label $val"
    }
}

function write-if-debug ($label, $value)
{
    if ($debug_flag -eq $True) {
        write-host "$label $value"
    }
}

if ($help) {
  $helpstring = @"
    NAME
      Export-Wflow
    SYNOPSIS
      Exports all the workflow definitions from an Actifio appliance
    SYNTAX
      Export-Wlow [[-targetdir] [directoryname]] [-help]
    EXAMPLE
      C:\ > Export-Wflow -targetdir c:\temp\ 
      This command extracts all the workflows with each filename with a default prefix - v : v_oracle, v_sqlserver and v_sqlinstance respectively.
      C:\ > Export-Wflow -targetdir c:\temp\ -pfx w -afx v3
      This command extracts all the workflows with the w_oracle.csv, w_sqlserver.csv and w_sqlinstance.csv respectively. Each workflow will start
      with the afx character, v3 in this case. wf1 will be v3_wf1 , the default is v2.
      C:\ > Export-Wflow -help
"@
    
    $helpString
    break  # Exits the function early
    }

if (($targetdir -eq $null) -or ($targetdir -eq "")) {
    $targetdir = "c:\users\actifio\desktop\"
}

If(!(test-path $targetdir)) {
  New-Item -ItemType Directory -Force -Path $targetdir | out-null
  }


$WorkFlows = udsinfo lsworkflow         # Get the list of workflows
$ii = 0
$table = @()
foreach ($wf_Item in $WorkFlows) {
    $myObject = New-Object System.Object

    $app_type = $($(reportapps -a $($wf_Item.appid)).AppType)

    $ii ++
    write-if-debug "`ncounter: " $ii
    $curApp = reportapps -a $($wf_Item.appid)

    write-if-debug "AppType: " $app_type
    write-if-debug "WF Name: " $($wf_Item.name)

    $myObject | Add-Member -type NoteProperty -name AppType -value $app_type
    
    if ($afx -ne $null -or $afx -ne "") {
        $tmpwfname = $afx + $($wf_Item.name)
        $myObject | Add-Member -type NoteProperty -name WfName -value $tmpwfname
    } else {
        $myObject | Add-Member -type NoteProperty -name WfName -value $($wf_Item.name)
    }

    $myObject | Add-Member -type NoteProperty -name AppId -value $($wf_Item.appid)
    $myObject | Add-Member -type NoteProperty -name AppName -value $($curApp.AppName)
    $myObject | Add-Member -type NoteProperty -name Disabled -value $($wf_Item.disabled)
    $myObject | Add-Member -type NoteProperty -name SchedType -value $($wf_Item.scheduletype)
    $myObject | Add-Member -type NoteProperty -name SchedDay -value $($wf_Item.scheduleday)    
    $myObject | Add-Member -type NoteProperty -name SchedTime -value $($wf_Item.scheduletime)                  

    write-if-debug "App ID: " $($wf_Item.appid)
    write-if-debug "SrcHostName: " $($curApp.HostName)
    write-if-debug "App Name: " $($curApp.AppName)
    write-if-debug "Disabled: " $($wf_Item.disabled)

    $myObject | Add-Member -type NoteProperty -name SourceHostname -value $($curApp.HostName)

# 30 = scheduled, (monthly) ; 20 = weekly ; 10 = daily    
    write-if-debug "SchedType: " $($wf_Item.scheduletype)
# if 10, it's null    
    write-if-debug "SchedDay: " $($wf_Item.scheduleday)
    write-if-debug "SchedTime: " $($wf_Item.scheduletime)

    $curWorkFlow = udsinfo lsworkflow $($wf_Item.id)
    write-if-debug "Workflow Id: " $($curWorkFlow.id)


    if ($($curWorkFlow.tasks) -ne $null) {
        [xml]$TaskXML = $($curWorkFlow.tasks) 
# $TaskXML
#    write-Host "WF Name : $($TaskXML.workflow.name)"
#    write-Host "xApp ID : $($TaskXML.workflow.appid)"
      
        write-not-null $($TaskXML.workflow.policy)              "policy : "
        write-not-null $($TaskXML.workflow.mount.appaware)      "appaware : "
        write-not-null $($TaskXML.workflow.mount.label)         "label : "


        $myObject | Add-Member -type NoteProperty -name Label -value $($TaskXML.workflow.mount.label)
        $myObject | Add-Member -type NoteProperty -name Policy -value $($TaskXML.workflow.policy)
        $myObject | Add-Member -type NoteProperty -name AppAware -value $($TaskXML.workflow.mount.appaware)

        if ($app_type -eq "Oracle") {
            write-not-null $($TaskXML.workflow.mount.restoreoption.volgroupname)         "volgroupname : "
            write-not-null $($TaskXML.workflow.mount.restoreoption.asmracnodelist)       "asmracnodelist : "

            $myObject | Add-Member -type NoteProperty -name volgroupname -value $null
            $myObject | Add-Member -type NoteProperty -name asmracnodelist -value $null 
        } elseif (($app_type -eq "SQLServer") -Or ($app_type -eq "SqlInstance") -Or ($app_type -eq "ConsistGrp")) {
            write-not-null $($TaskXML.workflow.mount.restoreoption.mountpointperimage)         "mountptperimage : "
            write-not-null $($TaskXML.workflow.mount.restoreoption.mountdriveperimage)       "mountdriveperimage : "

            $myObject | Add-Member -type NoteProperty -name mountpoint -value $null
            $myObject | Add-Member -type NoteProperty -name mountdrive -value $null 
        }


        if ($($TaskXML.workflow.mount.restoreoption) -ne $null) {

            write-if-debug "script: " $($TaskXML.workflow.mount.restoreoption)

            $($TaskXML.workflow.mount.restoreoption) -split "," | foreach-object { 
            write-host $_ 
            if ( $_ -like "*volgroup*" ) {
                $aa, $myObject.volgroupname = $_.split('=')
            } elseif ( $_ -like "*asmracnode*" ) {
                $bb, $myObject.asmracnodelist = $_.split('=')
            } elseif ( $_ -like "*mountpoint*" ) {
                $bb, $myObject.mountpoint = $_.split('=')
            } elseif ( $_ -like "*mountdrive*" ) {
                $bb, $myObject.mountdrive = $_.split('=')            
                }   

            } ## foreach-object
            write-host "`n"
            } ## end-if


        $myObject | Add-Member -type NoteProperty -name prescript -value $null
        $myObject | Add-Member -type NoteProperty -name postscript -value $null  

        if ($($TaskXML.workflow.mount.script) -ne $null) {

            write-if-debug "script: " $($TaskXML.workflow.mount.script)

            $($TaskXML.workflow.mount.script) -split ";" | foreach-object { 
            write-host $_ 
            if ( $_ -like "*PRE*" ) {
                $myObject.prescript = $_
            } elseif ( $_ -like "*POST*" ) {
                $myObject.postscript = $_
                }  ## end if $_
            }   ## foreach-object
            write-host "`n"
            } ## end-if

        ## $curHostId = 

        $curHost = udsinfo lshost | where { $_.id -eq $($TaskXML.workflow.mount.host.hostid) } 
        write-Host "hostid : $($TaskXML.workflow.mount.host.hostid) , Hostname = $($curHost.hostname)"
        $myObject | Add-Member -type NoteProperty -name TargetHostname -value $($curHost.hostname)

        if ($app_type -eq "Oracle") {

            write-not-null $TaskXML.workflow.mount."provisioning-options".databasesid."#text"   "db sid : "
            write-not-null $TaskXML.workflow.mount."provisioning-options".username."#text"      "username : " 
            write-not-null $TaskXML.workflow.mount."provisioning-options".orahome."#text"       "oracle home : " 
            write-not-null $TaskXML.workflow.mount."provisioning-options".tnsadmindir."#text"   "tns admindir : "  

            write-not-null $TaskXML.workflow.mount."provisioning-options".totalmemory."#text"   "total memory : " 
            write-not-null $TaskXML.workflow.mount."provisioning-options".sgapct."#text"        "sga pct : " 
            write-not-null $TaskXML.workflow.mount."provisioning-options".processes."#text"     "processes : " 
            write-not-null $TaskXML.workflow.mount."provisioning-options".rrecovery."#text"     "rrecovery : " 

            $myObject | Add-Member -type NoteProperty -name dbsid -value $TaskXML.workflow.mount."provisioning-options".databasesid."#text"
            $myObject | Add-Member -type NoteProperty -name username -value $TaskXML.workflow.mount."provisioning-options".username."#text"
            $myObject | Add-Member -type NoteProperty -name orahome -value $TaskXML.workflow.mount."provisioning-options".orahome."#text"
            $myObject | Add-Member -type NoteProperty -name tnsadmindir -value $TaskXML.workflow.mount."provisioning-options".tnsadmindir."#text"
            $myObject | Add-Member -type NoteProperty -name processes -value $TaskXML.workflow.mount."provisioning-options".processes."#text"
            $myObject | Add-Member -type NoteProperty -name totalmemory -value $TaskXML.workflow.mount."provisioning-options".totalmemory."#text"
            $myObject | Add-Member -type NoteProperty -name sgapct -value $TaskXML.workflow.mount."provisioning-options".sgapct."#text"
            $myObject | Add-Member -type NoteProperty -name rrecovery -value $TaskXML.workflow.mount."provisioning-options".rrecovery."#text"
            $myObject | Add-Member -type NoteProperty -name standalone -value $TaskXML.workflow.mount."provisioning-options".standalone."#text"

        } elseif ($app_type -eq "SQLServer") {


            $myObject | Add-Member -type NoteProperty -name sqlinstance -value $TaskXML.workflow.mount."provisioning-options".sqlinstance."#text"
            $myObject | Add-Member -type NoteProperty -name dbname -value $TaskXML.workflow.mount."provisioning-options".dbname."#text"
            $myObject | Add-Member -type NoteProperty -name recover -value $TaskXML.workflow.mount."provisioning-options".recover."#text"
        } else {

            ### SqlInstance
            $members = $TaskXML.workflow.members
            
            write-host "List of members = $members" 
            $myObject | Add-Member -type NoteProperty -name members -value $members

            $myObject | Add-Member -type NoteProperty -name sqlinstance -value $TaskXML.workflow.mount."provisioning-options".sqlinstance."#text"
            $myObject | Add-Member -type NoteProperty -name cgname -value $TaskXML.workflow.mount."provisioning-options".ConsistencyGroupName."#text"
            $myObject | Add-Member -type NoteProperty -name recover -value $TaskXML.workflow.mount."provisioning-options".recover."#text"
            $myObject | Add-Member -type NoteProperty -name dbprefix -value $TaskXML.workflow.mount."provisioning-options".dbnameprefix."#text"
            }  ## end-if app_type

        $table += $myObject
      
        }   ## end-if curWorkFlow.tasks
    

        
}   ## end-foreach


$outfile = $targetdir + "\" + $pfx + "_oracle.csv"
write-host "Creating output file $outfile"
$table | where-object { $_.AppType -eq "Oracle" } | export-csv $outfile -NoTypeInformation -Delimiter ";"

$outfile = $targetdir + "\" + $pfx + "_sqlserver.csv"
write-host "Creating output file $outfile"
$table | where-object { $_.AppType -eq "SQLServer" } | export-csv $outfile -NoTypeInformation -Delimiter ";"

$outfile = $targetdir + "\" + $pfx + "_sqlinstance.csv"
write-host "Creating output file $outfile" 
$table | where-object { $_.AppType -eq "SqlInstance" } | export-csv $outfile -NoTypeInformation -Delimiter ";"
