#
## File: import-wflow.ps1
## Extracts all the workflow definitions to separate files - $pfx_oracle.csv $pfx_sqlserver.csv and $pfx_sqlinstance.csv
## import-wflow.ps1 -help
## import-wflow.ps1 -ssvfile c:\temp\x.csv
# Last Updated: May-14-2018
#

# Function Import-Workflow ([string]$csvdir = $null,[switch]$help, [switch]$confirm)

param ( [string]$ssvfile = "input.csv",[switch]$help, [switch]$confirm)

if ($help) {
  $helpstring = @"
    NAME
      Import-wflow
    SYNOPSIS
      Creates all the workflow definitions from an Actifio appliance
    SYNTAX
      Import-Wflow [[-ssvfile] [filename]] [-help]
    EXAMPLE
      C:\ > Import-Wflow -ssvfile c:\temp\oracle.csv
      This command extracts all the Oracle workflows
      C:\ > Import-Wflow -help
"@
    
    $helpString
    break  # Exits the function early
    }

if (Test-Path $ssvfile) {
    $csv = Import-Csv $csvfile -delimiter ";"
} else {
    write-output "Unable to open SSV file - $ssvfile"
    write-output "Use -ssvfile to specify the name of the CSV file"
    exit 1
}

# ----------------------------------------------------------------
## Adds an Oracle workflow
#
# ----------------------------------------------------------------
function add-Oracle-wflow
{

write-output " Adding an Oracle workflow "
$rc1 = udstask mkworkflow -name $args[0] -appid $args[1] -frequency $args[2] -day $args[3] -time $args[4]
if ($rc1.result -ne $null) {
  write-output "Successfully created workflow $args[0] - tresult $($rc1.result)"
}

udstask addflowproperty -name policy -value snap $($rc1.result)
$rc3 = udstask mkflowitem -workflow $($rc1.result) -type mount

$rc4 = udstask addflowitemproperty -workflow $($rc1.result) -itemid $rc3.result -name label -value $args[5] 
$rc6 = udstask addflowitemproperty -workflow $($rc1.result) -itemid $rc3.result -name appaware -value $args[6]

$rst_options = "volgroupname=" +  $args[16] + "," + "asmracnodelist=" +  $args[17]
$rc7 = udstask addflowitemproperty -workflow $($rc1.result) -itemid $rc3.result -name restoreoption -value $rst_options


#$rc3 = udstask mkflowitem -workflow $rc1.result -type restoreoption
#$rc6 = udstask addflowitemproperty -workflow $($rc1.result) -itemid $rc3.result -name volgroupname -value $args[16]
#$rc6 = udstask addflowitemproperty -workflow $($rc1.result) -itemid $rc3.result -name asmracnodelist -value $args[17]

## $rc6 = udstask addflowitemproperty -workflow $rc1.result -itemid $rc3.result -name appaware -value $args[6]

# restoreoption
#$rf1 = udstask mkflowitem -workflow $($rc1.result) -type restoreoption -depends $rc3.result
#$rf2 = udstask mkflowitem -workflow $($rc1.result) -type volgroupname -depends $rf1.result
#$rf3 = udstask addflowitemvalue -workflow $($rc1.result) -itemid $rf2.result -value $args[16]

#$rf2 = udstask mkflowitem -workflow $($rc1.result) -type asmracnodelist -depends $rf1.result
#$rf3 = udstask addflowitemvalue -workflow $($rc1.result) -itemid $rf2.result -value $args[17]


# 
# $args[18] = prescript , $args[19] = postscript 

$UseScript = $False
if ($args[18] -eq $null -or $args[18] -eq "") {
  $localScript = $null
} else {
  $localScript = $args[18]
  $UseScript = $True    
}

if ($args[19] -ne $null -and $args[19] -ne "") {
  if ($localScript -ne $null) {
    $localScript += ";"
    }

  $localScript += $args[19]
  $UseScript = $True
}

if ($UseScript -eq $True) {
  $rc5 = udstask addflowitemproperty -workflow $($rc1.result) -itemid $rc3.result -name script -value $localScript
}

$localTmpHost = udsinfo lshost | where-object hostname -eq $args[7]
if ($localTmpHost -ne $null) {
$rc8 = udstask mkflowitem -workflow $rc1.result -type host -depends $rc3.result
$rc9 = udstask addflowitemproperty -workflow $rc1.result -itemid $rc8.result -name hostid -value $localTmpHost.id
}

# provisioning-options
$rf1 = udstask mkflowitem -workflow $rc1.result -type provisioning-options -depends $rc3.result
$rf2 = udstask mkflowitem -workflow $rc1.result -type databasesid -depends $rf1.result
$rf3 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf2.result -value $args[8]

$rf2 = udstask mkflowitem -workflow $rc1.result -type username -depends $rf1.result
$rf3 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf2.result -value $args[9]

$rf2 = udstask mkflowitem -workflow $rc1.result -type orahome -depends $rf1.result
$rf3 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf2.result -value $args[10]

$rf2 = udstask mkflowitem -workflow $rc1.result -type tnsadmindir -depends $rf1.result
$rf3 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf2.result -value $args[11]

$rf2 = udstask mkflowitem -workflow $rc1.result -type totalmemory -depends $rf1.result
$rf3 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf2.result -value $args[12]

$rf2 = udstask mkflowitem -workflow $rc1.result -type sgapct -depends $rf1.result
$rf3 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf2.result -value $args[13]

$rf2 = udstask mkflowitem -workflow $rc1.result -type processes -depends $rf1.result
$rf3 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf2.result -value $args[14]

$rf2 = udstask mkflowitem -workflow $rc1.result -type rrecovery -depends $rf1.result
$rf3 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf2.result -value $args[15]

$rf2 = udstask mkflowitem -workflow $rc1.result -type standalone -depends $rf1.result
$rf3 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf2.result -value $args[20]



}  ### add-Oracle-wflow

# ----------------------------------------------------------------
## Adds a SQL Server workflow
#
# ----------------------------------------------------------------
function add-SQLServer-wflow
{
write-output " Adding a SQL Server workflow "

$rc1 = udstask mkworkflow -name $args[0] -appid $args[1] -frequency $args[2] -day $args[3] -time $args[4]
if ($rc1.result -ne $null) {
  write-output "Successfully created workflow $args[0]"
}

# 
udstask addflowproperty -name policy -value snap $rc1.result
$rc3 = udstask mkflowitem -workflow $rc1.result -type mount

$rc4 = udstask addflowitemproperty -workflow $($rc1.result) -itemid $rc3.result -name label -value $args[5] 
$rc6 = udstask addflowitemproperty -workflow $rc1.result -itemid $rc3.result -name appaware -value $args[6]

$rst_options = "mountpointperimage=" +  $args[13] + "," + "mountdriveperimage=" +  $args[14]
$rc7 = udstask addflowitemproperty -workflow $($rc1.result) -itemid $rc3.result -name restoreoption -value $rst_options

# 
# $args[10] = prescript , $args[11] = postscript 
$UseScript = $False
if ($args[10] -eq $null -or $args[10] -eq "") {
  $localScript = $null
} else {
  $localScript = $args[10]
  $UseScript = $True    
}

if ($args[11] -ne $null -and $args[11] -ne "") {
  if ($localScript -ne $null) {
    $localScript += ";"
    }

  $localScript += $args[11]
  $UseScript = $True
}

if ($UseScript -eq $True) {
  $rc5 = udstask addflowitemproperty -workflow $($rc1.result) -itemid $rc3.result -name script -value $localScript
}

# $args[7] = targethostname
$localTmpHost = udsinfo lshost | where-object hostname -eq $args[7]
if ($localTmpHost -ne $null) {
$rc8 = udstask mkflowitem -workflow $rc1.result -type host -depends $rc3.result
$rc9 = udstask addflowitemproperty -workflow $rc1.result -itemid $rc8.result -name hostid -value $localTmpHost.id
}

# provisioning-options
$rf1 = udstask mkflowitem -workflow $rc1.result -type provisioning-options -depends $rc3.result

# $args[8] = dbname
$rf2 = udstask mkflowitem -workflow $rc1.result -type dbname -depends $rf1.result
$rf3 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf2.result -value $args[8]

# $args[9] = sqlinst
$rf4 = udstask mkflowitem -workflow $rc1.result -type sqlinstance -depends $rf1.result
$rf5 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf4.result -value $args[9]

# $args[12] = recover
$rf4 = udstask mkflowitem -workflow $rc1.result -type recover -depends $rf1.result
$rf5 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf4.result -value $args[12]

# $rf6 = udstask mkflowitem -workflow $rc1.result -type username -depends $rf1.result
# $rf7 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf6.result -value administrator

# $rf8 = udstask mkflowitem -workflow $rc1.result -type password -depends $rf1.result
# $rf9 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf8.result -value secret

}  ### add-SQLServer-wflow

# ----------------------------------------------------------------
## Adds a SQL Server Instance workflow
#
# ----------------------------------------------------------------
function add-SQLInstance-wflow
{
  write-output " Adding a SQL Server instance workflow "

$rc1 = udstask mkworkflow -name $args[0] -appid $args[1] -frequency $args[2] -day $args[3] -time $args[4]
if ($rc1.result -ne $null) {
  write-output "Successfully created workflow $args[0]"
}

# 
udstask addflowproperty -name policy -value snap $rc1.result
$rc3 = udstask mkflowitem -workflow $rc1.result -type mount

$rc4 = udstask addflowitemproperty -workflow $($rc1.result) -itemid $rc3.result -name label -value $args[5] 
$rc6 = udstask addflowitemproperty -workflow $rc1.result -itemid $rc3.result -name appaware -value $args[6]

$rst_options = "mountpointperimage=" +  $args[14] + "," + "mountdriveperimage=" +  $args[15]
$rc7 = udstask addflowitemproperty -workflow $($rc1.result) -itemid $rc3.result -name restoreoption -value $rst_options

# 
# $args[10] = prescript , $args[11] = postscript 
$UseScript = $False
if ($args[10] -eq $null -or $args[10] -eq "") {
  $localScript = $null
} else {
  $localScript = $args[10]
  $UseScript = $True    
}

if ($args[11] -ne $null -and $args[11] -ne "") {
  if ($localScript -ne $null) {
    $localScript += ";"
    }

  $localScript += $args[11]
  $UseScript = $True
}

if ($UseScript -eq $True) {
  $rc5 = udstask addflowitemproperty -workflow $($rc1.result) -itemid $rc3.result -name script -value $localScript
}


#$rc7 = udstask addflowitemproperty -workflow $rc1.result -itemid $rc3.result -name restoreoption -value "mountpointperimage=$localMountpt"

# $args[7] = targethostname
$localTmpHost = udsinfo lshost | where-object hostname -eq $args[7]
if ($localTmpHost -ne $null) {
$rc8 = udstask mkflowitem -workflow $rc1.result -type host -depends $rc3.result
$rc9 = udstask addflowitemproperty -workflow $rc1.result -itemid $rc8.result -name hostid -value $localTmpHost.id
}

# provisioning-options
$rf1 = udstask mkflowitem -workflow $rc1.result -type provisioning-options -depends $rc3.result

# $args[8] = dbnameprefix
$rf2 = udstask mkflowitem -workflow $rc1.result -type dbnameprefix -depends $rf1.result
$rf3 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf2.result -value $args[8]

# $args[9] = sqlinst
$rf4 = udstask mkflowitem -workflow $rc1.result -type sqlinstance -depends $rf1.result
$rf5 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf4.result -value $args[9]

# $args[12] = recover
$rf4 = udstask mkflowitem -workflow $rc1.result -type recover -depends $rf1.result
$rf5 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf4.result -value $args[12]

# $args[13] = ConsistencyGroupName
$rf4 = udstask mkflowitem -workflow $rc1.result -type ConsistencyGroupName -depends $rf1.result
$rf5 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf4.result -value $args[13]

# $rf6 = udstask mkflowitem -workflow $rc1.result -type username -depends $rf1.result
# $rf7 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf6.result -value administrator

# $rf8 = udstask mkflowitem -workflow $rc1.result -type password -depends $rf1.result
# $rf9 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf8.result -value secret

}  ### add-SQLInstance-wflow


###
#  M A I N    B O D Y
###

foreach ($item in $csv) {

  $localWFname = $($item.wfname)
  $myApptype = $($item.AppType)
  $localHostname = $($item.sourcehostname)
  $localAppname = $($item.appname)

  write-output "`nAdding workflow $localWFname"
  $localHost = udsinfo lshost | where-object hostname -eq $localHostname

if ($localHost -ne $null) {
    write-host "Host ID is $($localHost.id)"
    $localApp = udsinfo lsapplication | where-object hostid -eq $($localHost.id) | where-object appname -eq $localAppname
    write-host "App ID is $($localApp.id)"
} else {
    write-output "Invalid host $localHostname"
}

$rc = udsinfo lsworkflow $localWFname | select id
if ($rc.id -ne $null) {
    write-output "$localWFname is already defined in the Actifio appliance"
    continue
}

  if ($($item.schedtype) -eq 30) {
    $wfsched = "monthly"
  } elseif ($($item.schedtype) -eq 20) {
    $wfsched = "weekly"
  } if ($($item.schedtype) -eq 10) {
    $wfsched = "daily"
  }

  if ($myApptype -eq "Oracle") {
    add-Oracle-wflow $localWFname $($localApp.id) $wfsched $($item.schedday) $($item.schedtime) $($item.label) $($item.appaware) `
    $($item.targethostname) $($item.dbsid) $($item.username) $($item.orahome) $($item.tnsadmindir) $($item.totalmemory) $($item.sgapct) `
    $($item.processes) $($item.rrecovery) $($item.volgroupname) $($item.asmracnodelist) $($item.prescript) $($item.postscript) $($item.standalone)
  } elseif ($myApptype -eq "SQLServer") {
    add-SQLServer-wflow $localWFname $($localApp.id) $wfsched $($item.schedday) $($item.schedtime) $($item.label) $($item.appaware) $($item.targethostname) `
    $($item.dbname) $($item.sqlinstance) $($item.prescript) $($item.postscript) $($item.recover) $($item.mountpoint) $($item.mountdrive)
  } elseif ($myApptype -eq "sqlinstance") {
    add-SQLInstance-wflow $localWFname $($localApp.id) $wfsched $($item.schedday) $($item.schedtime) $($item.label) $($item.appaware) $($item.targethostname) `
     $($item.dbprefix) $($item.sqlinstance) $($item.prescript) $($item.postscript) $($item.recover) $($item.cgname) $($item.mountpoint) $($item.mountdrive)
  } else {
    write-output "Invalid application type $myApptype"
  }  ## end if myApptype

}  ### end foreach
