## What does this do?

This is a powershell script that helps on-board a SQL Server to the VDP appliance. This script is to be run on the source SQL server. It can perform a discovery of the both the SQL Windows server and VDP appliance environment. After the discovery process, it will report on all the SQL Server prerequisites for VDP appliance.

## How does this work?

It relies on two switches i.e. -srcsql or -tgtvdp . Either switch or both switches need to be specified when using the script.

## Supported PowerShell versions

This script has been tested with PowerShell 4, 5 and 7.  Note that to run this script on PowerShell 7,  you also need PowerShell 5 to be installed.  This is because PowerShell 7 needs to call some PowerShell 5 functions.  Also note that the firewall status values shown in PowerShell 7 may be numbers rather than words.  They translate as follows:

* 0 = False (not enabled)
* 1 = True (enabled)
* 2 = False or NotConfigured (not enabled)

## Usage

The following are options supported:
* _-srcsql_  This wll performs a discovery on the components required on the SQL Server i.e. iSCSI services, firewalls, and etc.
* _-tgtvdp_  This wll performs all checks on the VDP appliance i.e. connectivity from VDP to SQL Server host, registering the SQL server host, and etc
* _-ToExec_  This registers the SQL Server with the host and performs an iSCSI test.

## Sample output:
The following are sample of the different operations supported:

**Getting help on usage:**
```
PS C:\users\johndoe\Desktop> .\OnboardSQL.ps1
Usage: .\OnboardSql.ps1 [ -srcql ] [ -tgtvdp ] [ -ToExec ] [ -vdpip <Vdp IP appliance> [ -vdpuser <Vdp CLI user> ] [ -vdppassword <Vdp password> ]

 get-help .\OnboardSql.ps1 -examples
 get-help .\OnboardSql.ps1 -detailed
 get-help .\OnboardSql.ps1 -full
```

**Perform a test run on application discovery on the SQL Server and VDP appliance:**
```
PS C:\Users\av> .\OnboardSQL.ps1 -srcsql -tgtvdp -vdpip 10.10.10.1 -vdpuser johndoe -vdppassword TopSecret
Gathering information on Windows Host.
Gathering information on Sql Server Host.
Gathering information on Disk Usage.

--------- S T A T U S      R E P O R T      P A R T 1 ----------------------------------

            Computer Name: SYDWINSQLC3
               IP Address: 10.65.10.20
                     FQDN: sydwinsqlc3.au.actifio.com
                       OS: Microsoft Windows Server 2016 Standard
       PowerShell Version: 5.1
        Actifio Connector: 10.0.1.3663


---------------------------------------------------------------------------

Drive Information:

name label                  FreeSpacePerc FreeSpaceGiB CapacityGiB vssdiff vss_usedspaceGiB vss_allocspaceGiB vss_maxsp
                                                                                                                 aceGiB
---- -----                  ------------- ------------ ----------- ------- ---------------- ----------------- ---------
C:\                                  48.7        28.98       59.51                        0                 0         0
D:\  Data                           99.73       199.46         200                        0                 0         0
E:\  Logs                           99.02        99.01         100                        0                 0         0
X:\  Actifio-Backup-AAGDB03          99.9       119.87      119.99                        0                 0         0
Y:\  Actifio-Backup-AAGDB03         99.95       239.86      239.99                        0                 0         0

---------------------------------------------------------------------------

          Domain Firewall: False
         Private Firewall: False
          Public Firewall: False
   iSCSI FireWall Inbound: False
  iSCSI FireWall Outbound: False

            SQL Server SW: Installed
             SQL Instance: MSSQLSERVER
     VSS Writer [ State ]: Task Scheduler Writer [ Stable ] ( No error )
     VSS Writer [ State ]: VSS Metadata Store Writer [ Stable ] ( No error )
     VSS Writer [ State ]: Performance Counters Writer [ Stable ] ( No error )
     VSS Writer [ State ]: System Writer [ Stable ] ( No error )
     VSS Writer [ State ]: SqlServerWriter [ Stable ] ( No error )
     VSS Writer [ State ]: ASR Writer [ Stable ] ( No error )
     VSS Writer [ State ]: Shadow Copy Optimization Writer [ Stable ] ( No error )
     VSS Writer [ State ]: COM+ REGDB Writer [ Stable ] ( No error )
     VSS Writer [ State ]: Registry Writer [ Stable ] ( No error )
     VSS Writer [ State ]: WMI Writer [ Stable ] ( No error )
     VSS Writer [ State ]: Cluster Database [ Stable ] ( No error )
     VSS Writer [ State ]: Cluster Shared Volume VSS Writer [ Stable ] ( No error )

---------------------------------------------------------------------------

Gathering information on VDP Appliance.

--------- S T A T U S      R E P O R T      P A R T 2 ----------------------------------

* TEST:  Testing the connection from VDP appliance to SQL Server 10.65.10.20 on port 5106 (connector port)
Passed: VDP is able to communicate with the SQL Server 10.65.10.20 on port 5106

* TEST:  Checking if this host is already defined to the VDP Appliance
Passed:  SYDWINSQLC3.au.actifio.com is already defined in the VDP appliance as host ID 3471819. No registration required
!

* TEST:  Performing an iSCSI test on SYDWINSQLC3 from VDP appliance 10.65.5.35 :


iSCSIport                                            Status Test
---------                                            ------ ----
iqn.1991-05.com.microsoft:sydwinsqlc3.au.actifio.com Passed Host iSCSI initiator installed and configured
iqn.1991-05.com.microsoft:sydwinsqlc3.au.actifio.com Passed Appliance has valid IQN
iqn.1991-05.com.microsoft:sydwinsqlc3.au.actifio.com Passed Host has logged into the Appliance iSCSI target
iqn.1991-05.com.microsoft:sydwinsqlc3.au.actifio.com Passed Mapping disk from Appliance to host



* TEST:  Listing all applications discovered on SYDWINSQLC3 stored in VDP appliance 10.65.5.35 :


appname                    apptype
-------                    -------
C:\                        FileSystem
D:\                        FileSystem
E:\                        FileSystem
SYDWINSQLC3                SqlInstance
avtest112                  SqlServerWriter
db1                        SqlServerWriter
DevDB1test                 SqlServerWriter
DevDB2test                 SqlServerWriter
master                     SqlServerWriter
model                      SqlServerWriter
msdb                       SqlServerWriter
SimpleDB                   SqlServerWriter
sydwinsqlc3.au.actifio.com SystemState



* TEST:  Checking Connector version of SYDWINSQLC3 compared to latest available on VDP appliance 10.65.5.35
Passed:  Connector is on the Current Release 10.0.1.3663

---------------------------------------------------------------------------

PS C:\Users\av>

```

**Perform an actual run on application discovery on the SQL Server and VDP appliance (use the -TopExec switch):**
```
Gathering information on Windows Host.

--------- S T A T U S      R E P O R T      P A R T 1 ----------------------------------

            Computer Name: SYDWINSQLC3
               IP Address: 10.65.10.20
                     FQDN: sydwinsqlc3.au.actifio.com
                       OS: Microsoft Windows Server 2016 Standard
       PowerShell Version: 5.1
        Actifio Connector: 10.0.1.3663


---------------------------------------------------------------------------

Gathering information on VDP Appliance.

--------- S T A T U S      R E P O R T      P A R T 2 ----------------------------------


* TEST:  Testing the connection from VDP appliance to SQL Server 10.65.10.20 on port 5106 (connector port)
Passed: VDP is able to communicate with the SQL Server 10.65.10.20 on port 5106

* TEST:  Checking if this host is already defined to the VDP Appliance
Passed:  SYDWINSQLC3.au.actifio.com is already defined in the VDP appliance as host ID 3471819. No registration required!

* TEST:  Performing an iSCSI test on SYDWINSQLC3 from VDP appliance 10.65.5.35 :

iSCSIport                                            Status Test
---------                                            ------ ----
iqn.1991-05.com.microsoft:sydwinsqlc3.au.actifio.com Passed Host iSCSI initiator installed and configured
iqn.1991-05.com.microsoft:sydwinsqlc3.au.actifio.com Passed Appliance has valid IQN
iqn.1991-05.com.microsoft:sydwinsqlc3.au.actifio.com Passed Host has logged into the Appliance iSCSI target
iqn.1991-05.com.microsoft:sydwinsqlc3.au.actifio.com Passed Mapping disk from Appliance to host



Performing an application discovery on SYDWINSQLC3 and updating the information in VDP appliance 10.65.5.35


new   appname                                               saved missing exists id
---   -------                                               ----- ------- ------ --
false SimpleDB                                              true  false   true   6092657
false model                                                 true  false   true   3472253
false E:\                                                   true  false   true   3472231
false avtest112                                             true  false   true   9198918
false sydwinsqlc3.au.actifio.com                            true  false   true   3472241
false D:\                                                   true  false   true   3472235
false C:\                                                   true  false   true   3472237
false DevDB2test                                            true  true    true   8371083
false DevDB1test                                            true  true    true   8371085
false master                                                true  false   true   3472254
false msdb                                                  true  false   true   3472252
false db1                                                   true  true    true   8369276
false SYDWINSQLC3                                           true  false   true   3472251
true  C:\cmp1\                                              true  false   false  9619904
true  X:\                                                   true  false   false  9619906
true  C:\Windows\act\Job_9198881_mountpoint_15951294935132\ true  false   false  9619901
true  C:\Windows\act\Job_9198881_mountpoint_15951294934971\ true  false   false  9619902
true  Y:\                                                   true  false   false  9619905
true  C:\tmp\                                               true  false   false  9619903
true  sydwinsqlcx                                           false false   false  3471821
true  AAGDB07-CG                                            false false   false  3471822
true  AAGDB06-CG                                            false false   false  3471842
true  AAGDB04                                               false false   false  3472226
true  AAGDB03                                               false false   false  3472236
true  AAGDB02                                               false false   false  3472230
true  AAGDB01                                               false false   false  3472242



* TEST:  Listing all applications discovered on SYDWINSQLC3 stored in VDP appliance 10.65.5.35 :


appname                                               apptype
-------                                               -------
C:\                                                   FileSystem
C:\cmp1\                                              FileSystem
C:\tmp\                                               FileSystem
C:\Windows\act\Job_9198881_mountpoint_15951294934971\ FileSystem
C:\Windows\act\Job_9198881_mountpoint_15951294935132\ FileSystem
D:\                                                   FileSystem
E:\                                                   FileSystem
X:\                                                   FileSystem
Y:\                                                   FileSystem
SYDWINSQLC3                                           SqlInstance
avtest112                                             SqlServerWriter
db1                                                   SqlServerWriter
DevDB1test                                            SqlServerWriter
DevDB2test                                            SqlServerWriter
master                                                SqlServerWriter
model                                                 SqlServerWriter
msdb                                                  SqlServerWriter
SimpleDB                                              SqlServerWriter
sydwinsqlc3.au.actifio.com                            SystemState

* TEST:  Checking Connector version of SYDWINSQLC3 compared to latest available on VDP appliance 10.65.5.35
Passed:  Connector is on the Current Release 10.0.1.3663

---------------------------------------------------------------------------

PS C:\Users\av>
```


