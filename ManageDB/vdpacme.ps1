## File: .\vdpacme.ps1
## Purpose: Sets the parameters required for the ManageDB.ps1 PowerShell script
## Last Updated: 25-03-2020
#

## 
### VDP related parameters 
## 
[string] $vdphost = "172.27.24.96"         ##  This is the VDP appliance we will be connecting to.  
[string] $vdpuser = "cliuser"              ##  This is the user we will connect to the Appliance with.  
#[string] $vdppassword = "12!pass345"          ##  Store the password in clear text. Uncomment to define the password.   
[string] $vdppasswordfile = "c:\keys\cliuser.key"  ##  Store the password in encrypted format. Uncomment to use the passwordfile 

[bool] $oracle_app = $True                ## Is this an Oracle or SQL database? 
[bool] $debug = $False              

## 
### Oracle database related parameters 
## 
[string] $src_appname = "ACMESA"          ## Source application name - database name
[string] $src_hostname = "acme-ora01"       ## Source hostname - where did we captured from?
[string] $tgt_hostname = "acme-ora01"       ## Mounted to which host?
[string] $tgt_appname = "demodb"          ## Mounted application name = Oracle SID (demodb) for Oracle database
[string] $tgt_orauser = "oracle"          ## Oracle OS user            oracle
[string] $tgt_orahome = "/u01/app/oracle"    ## Oracle Home Directory  /u01/oracle/product/12.1.0.2
[string] $tgt_sgasize = "1536"            ## Oracle SGA size in MB          1024
[string] $tgt_sgapct = "80"               ## Oracle SGA size percentage     80
[string] $tgt_numprocs = "100"            ## Oracle number of processes     100
[string] $tgt_archmode = "false"          ## Oracle archive mode            true / false
[string] $tgt_diskgrp = ""                ## Oracle ASM diskgroupname
[string] $tgt_asmracnodelist = ""         ## ASM RAC node IP separated by comma
[bool] $tgt_force = $False                ## Force unmount when unmounting the database   True/False

##
### SQL database related parameters
##
[string] $tgt_sqlinstance = "MASKING-PRO\MSSQL2014"       ## SQL Server Instance : SQL-SERVER\MSSQL2014

## 
### pre and post scripts 
## 
[string] $pre_scriptfile = "p1.sh"
[string] $pre_timeout = "180"
[string] $post_scriptfile = "p2.sh"
[string] $post_timeout = "200"
