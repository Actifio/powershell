# 
## File: ManageDB.ps1
## Purpose: Refreshes the Oracle database listed in actparams.ps1 
#
# Version 1.0 Initial Release
# Version 1.1 Added additional operations: bookmark, rewind, unmount, remount
#

<#   
.SYNOPSIS   
   Manages the lifecycle of the virtual Oracle and SQL database.
.DESCRIPTION 
   This is a powershell script that helps you manage the lifecycle of virtual SQL or Oracle database. It allows the user to remove the virtual database, provision a copy of the virtual database, and also refresh an existing mount with the latest image stored in VDP. This script can be used if user is not interested in using the VDP workflow feature.
.PARAMETER action
    The action or commands that can be performed against the virtual database. This include config, cleanup, refresh, provision and genparamfile.
.PARAMETER paramfile
    The parameter file holding all the configurations related to the virtual database and VDP appliance.    
.EXAMPLE
    .\ManageDB.ps1 -action genparamfile

    To generate a sample parameterfile. Customise the value in this generated and use it as input to other commands.
.EXAMPLE
    PS > .\ManageDB.ps1 -action config -paramfile .\actparams.ps1

    To create an encrypted password file ($vdppasswordfile in the paramfile) using the values stored in parameterfile (-paramfile) or enter the password when prompt for it. Once created, you can remove the $vdppassword entry from the parameterfile to secure the credentials.
.EXAMPLE 
    PS > .\ManageDB.ps1 -action cleanup -paramfile .\actparams.ps1

    To remove a mounted application defined in the parameterfile (-paramfile). If the application is unmounted, you will need to remount and run cleanup to remove the application.
.EXAMPLE
    .\ManageDB.ps1 -action refresh -paramfile .\actparams.ps1

    To unmount an existing application and mount the new application using the latest VDP image and values defined in the parameterfile (-paramfile) 
.EXAMPLE
    .\ManageDB.ps1 -action provision -paramfile .\actparams.ps1

    To mount the new application using the latest VDP image and values defined in the parameterfile (-paramfile)
.EXAMPLE 
    PS > .\ManageDB.ps1 -action unmount -paramfile .\actparams.ps1

    To unmount but not remove the application defined in the parameterfile (-paramfile).
.EXAMPLE 
    PS > .\ManageDB.ps1 -action remount -paramfile .\actparams.ps1

    To remount the application that was unmounted earlier. All the AppAware mount settings is specified in the parameterfile (-paramfile).
.NOTES   
    Name: ManageDB.ps1
    Author: Michael Chew
    DateCreated: 25-March-2020
    LastUpdated: 30-March-2020
.LINK
    https://github.com/Actifio/powershell/blob/master/ManageDB     
#>

[CmdletBinding()]
Param
( 
  # Parameter File with all the configurations to the script
  [string]$paramfile = $null, 
  # What action and operation you want to perform using this script
  [string]$action = ""
)  ### Param

$ManageDBversion = "1.1"
$ActionList =@("config","cleanup","refresh","provision","unmount","remount","bookmark","rewind", "genparamfile")

##################################
# Function: Display-Usage
#
##################################
function Display-Usage ()
{
    write-host "Usage: .\ManageDB.ps1 -action [ config | cleanup | refresh | provision | unmount | remount ] -paramfile [ full pathname of the parameter file ] | -action genparamfile `n"
    write-host " get-help .\ManageDB.ps1 -examples"
    write-host " get-help .\ManageDB.ps1 -detailed"
    write-host " get-help .\ManageDB.ps1 -full"    
}     ### end of function

##################################
# Function: Gen-Sample-ParamFile
#
##################################

function Gen-Sample-ParamFile ()
{
  $sampleFile = ".\vdpSampleParam.ps1"
  $currdate = (Get-Date -Format "dd-MM-yyyy")

  Write-Host "Generating all the parameters in $sampleFile file"

  "## File: $sampleFile" | Out-File $sampleFile -Encoding Ascii

  "## Purpose: Sets the parameters required for the ManageDB.ps1 v $ManageDBversion PowerShell script" | Out-File $sampleFile -Append  -Encoding Ascii
  "## Last Updated: $currdate" | Out-File $sampleFile -Append  -Encoding Ascii
  "#" | Out-File $sampleFile -Append  -Encoding Ascii
  "`n## " | Out-File $sampleFile -Append  -Encoding Ascii
  "### VDP related parameters " | Out-File $sampleFile -Append  -Encoding Ascii
  "## " | Out-File $sampleFile -Append  -Encoding Ascii
  "[string] `$vdphost = " + [char]34 + "10.10.10.1" + [char]34 + "           ##  This is the VDP appliance we will be connecting to.  " | Out-File $sampleFile -Append  -Encoding Ascii
  "[string] `$vdpuser = " + [char]34 + "johndoe" + [char]34 + "              ##  This is the user we will connect to the Appliance with.  " | Out-File $sampleFile -Append  -Encoding Ascii  
  "#[string] `$vdppassword = " + [char]34 + "secret" + [char]34 + "          ##  Store the password in clear text. Uncomment to define the password.   "     | Out-File $sampleFile -Append  -Encoding Ascii  
  "#[string] `$vdppasswordfile = " + [char]34 + ".\pass.key" + [char]34 + "  ##  Store the password in encrypted format. Uncomment to use the passwordfile " | Out-File $sampleFile -Append  -Encoding Ascii  
  
  "`n[bool] `$oracle_app = `$False                ## Is this an Oracle or SQL database? " | Out-File $sampleFile -Append  -Encoding Ascii
  "[bool] `$debug = `$False              " | Out-File $sampleFile -Append  -Encoding Ascii
  
  "`n## " | Out-File $sampleFile -Append  -Encoding Ascii
  "### Oracle database related parameters " | Out-File $sampleFile -Append  -Encoding Ascii
  "## " | Out-File $sampleFile -Append  -Encoding Ascii
  "[string] `$src_appname = " + [char]34 + "acmedb" + [char]34 + "          ## Source application name - database name" | Out-File $sampleFile -Append  -Encoding Ascii 
  "[string] `$src_hostname = " + [char]34 + "prodsrvr" + [char]34 + "       ## Source hostname - where did we captured from?" | Out-File $sampleFile -Append  -Encoding Ascii        
  "[string] `$tgt_hostname = " + [char]34 + "testsrvr" + [char]34 + "       ## Mounted to which host?" | Out-File $sampleFile -Append  -Encoding Ascii 
  "[string] `$tgt_appname = " + [char]34 + "demodb" + [char]34 + "          ## Mounted application name = Oracle SID (demodb) for Oracle database" | Out-File $sampleFile -Append  -Encoding Ascii 
  "[string] `$tgt_orauser = " + [char]34 + "oracle" + [char]34 + "          ## Oracle OS user            oracle" | Out-File $sampleFile -Append  -Encoding Ascii 
  "[string] `$tgt_orahome = " + [char]34 + "/home/oracle/app/oracle/product/12.2.0/dbhome_1" + [char]34 + "    ## Oracle Home Directory  /u01/oracle/product/12.1.0.2" | Out-File $sampleFile -Append  -Encoding Ascii 
  "[string] `$tgt_tnsorahome = " + [char]34 + "/home/oracle/app/oracle/product/12.2.0/dbhome_1/network/admin" + [char]34 + "    ## Oracle Home Directory  /u01/oracle/product/12.1.0.2" | Out-File $sampleFile -Append  -Encoding Ascii 
  "[string] `$tgt_sgasize = " + [char]34 + "1536" + [char]34 + "            ## Oracle SGA size in MB          1024" | Out-File $sampleFile -Append  -Encoding Ascii 
  "[string] `$tgt_sgapct = " + [char]34 + "80" + [char]34 + "               ## Oracle SGA size percentage     80" | Out-File $sampleFile -Append  -Encoding Ascii 
  "[string] `$tgt_numprocs = " + [char]34 + "100" + [char]34 + "            ## Oracle number of processes     100" | Out-File $sampleFile -Append  -Encoding Ascii 
  "[string] `$tgt_archmode = " + [char]34 + "false" + [char]34 + "          ## Oracle archive mode            true / false" | Out-File $sampleFile -Append  -Encoding Ascii 
  "[string] `$tgt_diskgrp = " + [char]34 + "" + [char]34 + "                ## Oracle ASM diskgroupname" | Out-File $sampleFile -Append  -Encoding Ascii 
  "[string] `$tgt_asmracnodelist = " + [char]34 + "" + [char]34 + "         ## ASM RAC node IP separated by comma" | Out-File $sampleFile -Append  -Encoding Ascii 
  "[bool] `$tgt_force = `$False                ## Force unmount when unmounting the database   True/False" | Out-File $sampleFile -Append  -Encoding Ascii 
  "`n##" | Out-File $sampleFile -Append  -Encoding Ascii
  "### SQL database related parameters" | Out-File $sampleFile -Append  -Encoding Ascii
  "##" | Out-File $sampleFile -Append  -Encoding Ascii
  "[string] `$tgt_sqlinstance = " + [char]34 + "MASKING-PRO\MSSQL2014" + [char]34 + "       ## SQL Server Instance : SQL-SERVER\MSSQL2014" | Out-File $sampleFile -Append  -Encoding Ascii
  
  "`n## " | Out-File $sampleFile -Append  -Encoding Ascii
  "### pre and post scripts " | Out-File $sampleFile -Append  -Encoding Ascii
  "## " | Out-File $sampleFile -Append  -Encoding Ascii
  "#[string] `$pre_scriptfile = " + [char]34 + "p1.sh" + [char]34   | Out-File $sampleFile -Append  -Encoding Ascii
  "#[string] `$pre_timeout = " + [char]34 + "180" + [char]34       | Out-File $sampleFile -Append  -Encoding Ascii
  "#[string] `$post_scriptfile = " + [char]34 + "p2.sh" + [char]34 | Out-File $sampleFile -Append  -Encoding Ascii
  "#[string] `$post_timeout = " + [char]34 + "200" + [char]34      | Out-File $sampleFile -Append  -Encoding Ascii
}     ### end of function

##################################
# Function: Unmount-App
#
##################################
function Unmount-App (
  [string]$srcappname,
  [string]$srchostname,
  [string]$tgtappname,
  [string]$tgthostname,
  [bool]$force, 
  [bool]$ToDelete )
{
  $cmdline = $( reportmountedimages -c | where { $_.MountedAppName -eq $tgtappname -And $_.MountedHost -eq $tgthostname -And $_.SourceApp -eq $srcappname -And $_.SourceHost -eq $srchostname } ).UnmountDeleteCommand

  if ($cmdline -ne $Null) {
    Write-Host "`nUnnmounting the $tgtappname application ..... `n"

    if ($force) {
      $cmdline = $cmdline + " -force"
      }
    $cmdline = $cmdline.Replace("-nowait ","")
    if ($ToDelete -eq $False) {
      $cmdline = $cmdline.Replace("-delete ","")
    }
    $cmdline = $cmdline + " | Out-Null "

    if ($debug) {
      Write-Host "DEBUG: To execute: $cmdline"
    } else {
      write-host "Executing: $cmdline " 
      Invoke-Expression $cmdline   ####  Job_1234 to unmount Image_1234 completed
    }


  } else {
    write-host "`nThere is nothing to unmount !! "  
  }
}     ### end of function

##################################
# Function: Monitor-Mount
#
##################################
function Monitor-Mount ( 
  [string]$srcappname,
  [string]$srchostname,
  [string]$tgthostname )
{
  sleep -Seconds 20
  $JobID = $(reportrunningjobs | where { $_.HostName -eq $srchostname -And $_.AppName -eq $srcappname -And $_.Target -eq $tgthostname }).JobName

  $JobStatus = $(reportrunningjobs | where { $_.JobName -eq $JobID }).status
  $PrevJobPct = "0"
  if ($JobStatus -eq 'running') {
     Write-Host "`nJob is now running.... "
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
  sleep -Seconds 30
  return $JobID
}     ### end of function

##################################
# Function: Build-PrePostScript
#
##################################
function Build-PrePostScript () 
{
  $UseScript = $False
  if ($pre_scriptfile -eq $null -or $pre_scriptfile -eq "") {
    $localScript = $null
  } else {
    $localScript = "phase=PRE:name=" + $pre_scriptfile 
    if (! ($pre_timeout -eq $null -or $pre_timeout -eq "")) {
      $localScript += ":timeout=" + $pre_timeout      
    }
    $UseScript = $True
  }
  
  if ($post_scriptfile -ne $null -and $post_scriptfile -ne "") {
    if ($localScript -ne $null) {
      $localScript += ";"
    }
    $localScript += "phase=POST:name=" + $post_scriptfile 
    if (! ($post_timeout -eq $null -or $post_timeout -eq "")) {
      $localScript += ":timeout=" + $post_timeout      
    }
    $UseScript = $True
  }

  return $UseScript, $localScript
}     ### end of function

##################################
# Function: BuildOraXml
#
##################################
function BuildOraXml (
  [string]$vdpversion,
  [string]$tgtorasid,
  [string]$tgtorauser,
  [string]$tgtorahome,
  [string]$tgtsgasize,  
  [string]$tgtsgapct,  
  [string]$tgtarchmode,  
  [string]$tgtdiskgrp,
  [string]$tgtnodeip )
{
  if ($tgtdiskgrp -ne "") {
    $volstr = "volgroupname=" + $tgtdiskgrp 
    if ($tgtdiskgrp -ne "") {
      $volstr = $volstr + ",asmracnodelist=" + $tgtnodeip 
      }
    $volstr = $volstr + ","  
  } else {
    $volstr = ""    
  }

  $subxmlstring = $null
  if ( [version]::Parse($vdpversion) -ge [version]::Parse('10.0') ) {
    $subxmlstring += "<noarchivemode>$tgtarchmode</noarchivemode>" 
    if ($tgt_tnsorahome -ne $null) {
      $subxmlstring += "<tnsadmindir>$tgt_tnsorahome</tnsadmindir>"
      }
  } elseif ( [version]::Parse($vdpversion) -ge [version]::Parse('9.0') ) {  
    $subxmlstring += "<noarchivemode>$tgtarchmode</noarchivemode>" 
    if ($tgt_tnsorahome -ne $null) {
      $subxmlstring += "<tnsadmindir>$tgt_tnsorahome</tnsadmindir>"
      }
  } else {
    if ($tgt_tnsorahome -eq $null) {
      Write-Host "please specify `$tgt_tnsorahome in the config file. It's required for $vdpversion"
      }
    else {
      $subxmlstring += "<tnsadmindir>$tgt_tnsorahome</tnsadmindir>"
    }
  }

  $xmlstring = "-restoreoption " + [char]34 + $volstr + ` 
       "provisioningoptions=<provisioningoptions>" + "<databasesid>$tgtorasid</databasesid>" + `
       "<username>$tgtorauser</username>"+ "<orahome>$tgtorahome</orahome>" + `
       "<totalmemory>$tgtsgasize</totalmemory>" + "<sgapct>$tgtsgapct</sgapct>" + `
       "<nonid>false</nonid>" + $subxmlstring + `
       "<notnsupdate>false</notnsupdate>" + "<rrecovery>true</rrecovery>" `
       + "<standalone>true</standalone></provisioningoptions>,reprotect=false" + [char]34

  return $xmlstring
}     ### end of function

##################################
# Function: Mount-Ora-App
#
##################################
function Mount-Ora-App ( 
  [string]$srcappname,
  [string]$srchostname,
  [string]$tgthostname,
  [string]$tgtorasid,
  [string]$tgtorauser,
  [string]$tgtorahome,
  [string]$tgtsgasize,  
  [string]$tgtsgapct,  
  [string]$tgtarchmode,  
  [string]$tgtdiskgrp,
  [string]$tgtnodeip )
{
  $appid = $(reportapps | where-object { $_.HostName -eq $srchostname -and $_.AppName -eq $srcappname }).AppID
  $hostid = $(udsinfo lshost -filtervalue "hostname=$tgthostname").id

  $xmlstring = BuildOraXml $vdpversion $tgtorasid $tgtorauser $tgtorahome $tgtsgasize $tgtsgapct $tgtarchmode $tgtdiskgrp $tgtnodeip
  $UseScript, $localScript = Build-PrePostScript

   write-host "`nMounting $srcappname to $tgthostname as $tgtorasid...`n" 
   if ( $UseScript ) {
     $cmd = "udstask mountimage -appid " + $appid + " -host " + $hostid + " -appaware " + $xmlstring + `
        " -script " + [char]34 + $localScript + [char]34 + " -nowait | Out-Null" 
   } else {
     $cmd = "udstask mountimage -appid " + $appid + " -host " + $hostid + " -appaware " + $xmlstring + " -nowait | Out-Null"
   }

    if ($debug) {
      Write-Host "DEBUG: To execute: $cmd"
    } else {
      write-host "Executing: $cmd"
      Invoke-Expression $cmd 
    }
   write-host "`n"
}     ### end of function

##################################
# Function: Remount-Ora-App
#
##################################
function Remount-Ora-App (
  [string]$srcappname,
  [string]$srchostname,
  [string]$tgthostname,
  [string]$tgtorasid,
  [string]$tgtorauser,
  [string]$tgtorahome,
  [string]$tgtsgasize,  
  [string]$tgtsgapct,  
  [string]$tgtarchmode,  
  [string]$tgtdiskgrp,
  [string]$tgtnodeip )

{
  $cmdline = $( reportmountedimages -c | where { $_.SourceApp -eq $srcappname -And $_.SourceHost -eq $srchostname } ).UnmountDeleteCommand
  
  if ($cmdline -ne $Null) {         ## ####  udstask expireimage -nowait -image Image_123  
    Write-Host "`nRemounting the Oracle database $tgtorasid ..... `n"

    $cmdline = $cmdline.Replace("expireimage","mountimage")
    $cmdline = $cmdline.Replace("-nowait ","")

    $hostid = $(udsinfo lshost -filtervalue "hostname=$tgthostname").id
    $xmlstring = BuildOraXml $vdpversion $tgtorasid $tgtorauser $tgtorahome $tgtsgasize $tgtsgapct $tgtarchmode $tgtdiskgrp $tgtnodeip
    $UseScript, $localScript = Build-PrePostScript

    write-host "`nRemounting $srcappname database to $tgthostname as $tgtorasid...`n" 
    if ( $UseScript ) {
      $cmd = $cmdline + " -host " + $hostid + " -appaware " + $xmlstring + `
        " -script " + [char]34 + $localScript + [char]34 + " -nowait | Out-Null" 
    } else {
      $cmd = $cmdline + " -host " + $hostid + " -appaware " + $xmlstring + " -nowait | Out-Null"
    }
   
    if ($debug) {
      Write-Host "DEBUG: To execute: $cmd"
    } else {
      write-host "Executing: $cmd" 
      Invoke-Expression $cmd   ####  Job_1234 to unmount Image_1234 completed
    }

  } else {
    write-host "There is nothing to remount "  
  }
}     ### end of function

##################################
# Function: BuildSqlXml
#
##################################
function BuildSqlXml (
  [string]$tgtappname,
  [string]$tgtsqlinstance )
{
  $xmlstring = "-restoreoption " + [char]34 + ` 
  "provisioningoptions=<provisioningoptions>" + "<sqlinstance>$tgtsqlinstance</sqlinstance>" + `
  "<dbname>$tgtappname</dbname>" + "<recover>true</recover>" + `
  "</provisioningoptions>,reprotect=false" + [char]34

  return $xmlstring
}     ### end of function

##################################
# Function: Mount-Sql-App
#
##################################
function Mount-Sql-App ( 
  [string]$srcappname,
  [string]$srchostname,
  [string]$tgthostname,
  [string]$tgtappname,
  [string]$tgtsqlinstance )
{
  $appid = $(reportapps | where-object { $_.HostName -eq $srchostname -and $_.AppName -eq $srcappname }).AppID
  $hostid = $(udsinfo lshost -filtervalue "hostname=$tgthostname").id

  $xmlstring = BuildSqlXml $tgtappname $tgtsqlinstance

  $UseScript, $localScript = Build-PrePostScript

   write-host "`nMounting $srcappname to $tgthostname as $tgtorasid...`n" 
   if ( $UseScript ) {
     $cmd = "udstask mountimage -appid " + $appid + " -host " + $hostid + " -appaware " + $xmlstring + `
        " -script " + [char]34 + $localScript + [char]34 + " -nowait | Out-Null" 
   } else {
     $cmd = "udstask mountimage -appid " + $appid + " -host " + $hostid + " -appaware " + $xmlstring + " -nowait | Out-Null"
   }
   
  if ($debug) {
    Write-Host "DEBUG: To execute: $cmd"
  } else {
    write-host "Executing: $cmd"
    $out = Invoke-Expression $cmd | Out-Null      
  }
   write-host "`n"
}     ### end of function

##################################
# Function: Remount-Sql-App
#
##################################
function Remount-Sql-App ( 
  [string]$srcappname,
  [string]$srchostname,
  [string]$tgthostname,
  [string]$tgtappname,
  [string]$tgtsqlinstance )
{
  $cmdline = $( reportmountedimages -c | where { $_.SourceApp -eq $srcappname -And $_.SourceHost -eq $srchostname } ).UnmountDeleteCommand
  
  if ($cmdline -ne $Null) {         ## ####  udstask expireimage -nowait -image Image_123  
    Write-Host "`nRemounting the SQL database $tgtappname ..... `n"

    $cmdline = $cmdline.Replace("expireimage","mountimage")
    $cmdline = $cmdline.Replace("-nowait ","")

    $xmlstring = BuildSqlXml $tgtappname $tgtsqlinstance

    $hostid = $(udsinfo lshost -filtervalue "hostname=$tgthostname").id
  
    $UseScript, $localScript = Build-PrePostScript
  
    write-host "`nRemounting $srcappname database to $tgthostname as $tgtappname...`n" 
    if ( $UseScript ) {
       $cmd = $cmdline + " -host " + $hostid + " -appaware " + $xmlstring + `
          " -script " + [char]34 + $localScript + [char]34 + " -nowait | Out-Null" 
    } else {
       $cmd = $cmdline + " -host " + $hostid + " -appaware " + $xmlstring + " -nowait | Out-Null"
    }

    if ($debug) {
      Write-Host "DEBUG: To execute: $cmd"
    } else {
      write-host "Executing: $cmd"
      $out = Invoke-Expression $cmd | Out-Null      
    }
    write-host "`n"
  } #### end main if
}     ### end of function

##################################
# Function: Report-AppUsage
#
##################################
function Report-AppUsage ( 
  [string]$jobid,
  [string]$srcappname,
  [string]$srchostname,
  [string]$tgthostname,
  [string]$tgtorasid )
{
   write-host "`nDisplaying the statistics for $jobid "
   $appid = $(reportapps | where-object { $_.HostName -eq $srchostname -and $_.AppName -eq $srcappname }).AppID

   write-host "`nKicking off an on-demand provision of virtual database $tgtorasid on $tgthostname using images from $srcappname database `n"
   $start = $(udsinfo lsjobhistory $jobid).startdate
   $duration = $(udsinfo lsjobhistory $jobid).duration
   $vsize = $(udsinfo lsjobhistory $jobid)."Application size (GB)"
   $tgthost = $(udsinfo lsjobhistory $jobid).targethost
   $usedGB = $(reportmountedimages | where { $_.SourceAppID -eq $appid -And $_.MountedAppName -eq $tgtorasid } )."ConsumedSize(GB)"

   write-host "$tgtorasid database is successfully provisioned on $tgthostname !!"
   write-host "Job started at $start , and took $duration to complete."
   write-host "The size of $tgtorasid on $tgthostname is $vsize GB, and actual storage consumed is $usedGB GB"

}     ### end of function

##############################
#
#  M A I N    B O D Y
#
##############################

if (! $action) {
    Display-Usage
    exit
}

if ( ! ($ActionList -contains $action) ) {
  Write-Host "`n$action is not a valid action after the -action argument !! "
  $strlist = $Null
  $ActionList | ForEach-Object { if ($_ -eq $ActionList[-1]) { $strlist += $_ + " " } else { $strlist += $_ + " , " } }
  Write-Host "Valid action supported: $strlist`n"
  Display-Usage
  exit
}

if ((! $paramfile) -And ($action -ne "genparamfile")) {
    Display-Usage
    exit
}

## genparamfile: to generate a sample parameterfil
if ($action -eq "genparamfile") {
    Gen-Sample-ParamFile
    exit
}

if ((!(Test-Path $paramfile)) -And ($action -ne "config")) { 
    Write-Warning "$paramfile is missing !!"
    exit
} 


# Loads the parameter file in $paramfile
if (Test-Path $paramfile) {
  . $paramfile

  $tgt_orasid = $tgt_appname  
}

## config : to create a password file ($vdppasswordfile in the paramfile) using the values stored in parameterfile (-paramfile) or entered values
if ($action -eq "config") {

  if (! $vdppasswordfile) {
    $vdppasswordfile = read-host -prompt "Enter the full filename (e.g. c:\vdp\password.key): "    
    }

  if (! $vdppassword) {
    (Get-Credential).Password | ConvertFrom-SecureString | Out-File $vdppasswordfile
    }
  else {
    $vdppassword | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File $vdppasswordfile
    }  
  exit
}

if (! $vdppasswordfile) {
  if (! $vdppassword) {
    Write-Host "No VDP password defined in the parameter file $paramfile"
    exit
    }
  }

if (! $vdpuser) {
  Write-Host "No VDP user defined in the parameter file $paramfile"
  exit
}

if (! $vdphost) {
  Write-Host "No VDP host defined in the parameter file $paramfile"
  exit
}

## Ensure that the ActPowerCLI module is imported
#
$moduleins = get-module -listavailable -name ActPowerCLI
if ($moduleins -eq $null) {
    Import-Module ActPowerCLI
}

############################################
##
### Connect to the Actifio appliance
##
############################################
if ($vdppasswordfile) {
  if ($debug) {
    write-host "Connecting to $vdphost VDP appliance as username $vdpuser using the passwordfile $vdppasswordfile"  
  }
  $connectattempt=$(connect-act -acthost $vdphost -actuser $vdpuser -passwordfile $vdppasswordfile -ignorecerts)
} else {
  if ($debug) {
    write-host "Connecting to $vdphost VDP appliance as username $vdpuser using the password in $paramfile"  
  }
  $connectattempt=$(connect-act -acthost $vdphost -actuser $vdpuser -password $vdppassword -ignorecerts)  
}

if ($connectattempt -ne "Login Successful!") {
  write-host "Failed to login to $vdphost with username $vdpuser"
  exit
  }

$vdpversion = $(udsinfo lsversion | where-object { $_.component -eq "Sky" }).version
if ($vdpversion -eq $null) {
  $vdpversion="9.0"
  write-host "Unable to find out the version when connecting to $vdphost . Setting it to $vdpversion "
}

write-host "`nConnected to VDP appliance $vdphost , running version $vdpversion "

if (($action -eq "cleanup") -Or ($action -eq "refresh")) {
  Unmount-App $src_appname $src_hostname $tgt_appname $tgt_hostname $tgt_force $True
  }   ### end of if-action

if (($action -eq "provision") -Or ($action -eq "refresh")) {  
  if ( $oracle_app ) {  
    Mount-Ora-App $src_appname $src_hostname $tgt_hostname $tgt_orasid $tgt_orauser $tgt_orahome $tgt_sgasize `
      $tgt_sgapct $tgt_archmode $tgt_diskgrp $tgt_asmracnodelist
  } else {
    Mount-Sql-App $src_appname $src_hostname $tgt_hostname $tgt_appname $tgt_sqlinstance  
    }  
  }  ### end of if-action

if ($action -eq "remount") {
  if ( $oracle_app ) {
      Remount-Ora-App $src_appname $src_hostname $tgt_hostname $tgt_orasid $tgt_orauser $tgt_orahome $tgt_sgasize `
      $tgt_sgapct $tgt_archmode $tgt_diskgrp $tgt_asmracnodelist
    }
  else {
      Remount-Sql-App $src_appname $src_hostname $tgt_hostname $tgt_appname $tgt_sqlinstance 
    }
  }   ### end of if-action
    
if (($action -eq "provision") -Or ($action -eq "refresh") -Or ($action -eq "remount")) {  
	if (! $debug) {
    $job_id = Monitor-Mount $src_appname $src_hostname $tgt_hostname
    Report-AppUsage $job_id $src_appname $src_hostname $tgt_hostname $tgt_orasid    
    }
	}
	
if ($action -eq "unmount") {
    Unmount-App $src_appname $src_hostname $tgt_appname $tgt_hostname $tgt_force $False
  }   ### end of if-action

Disconnect-Act
exit

