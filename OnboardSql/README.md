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
PS C:\users\johndoe\Desktop> .\OnboardSQL.ps1 -srcsql -tgtvdp -vdpip 10.10.10.1 -vdpuser johndoe -vdppassword TopSecret
Missing ToExec value is False
I will be gathering information on Windows Host.
I will be gathering information on Sql Server Host.

--------- S T A T U S      R E P O R T      P A R T 1 ----------------------------------

            Computer Name: WIN2K12R2
               IP Address: 10.10.10.55
                     FQDN: Win2k12R2.acme.com
                       OS: Microsoft Windows Server 2012 R2 Datacenter

---------------------------------------------------------------------------

          Domain Firewall: False
         Private Firewall: False
          Public Firewall: False
   iSCSI FireWall Inbound: False
  iSCSI FireWall Outbound: False

Actifio Vdp Ip Pingable  : True
            SQL Server SW: Not Installed
             SQL Instance: No Instances Created
              VSS Writers: Not Installed

---------------------------------------------------------------------------

I will be gathering information on Vdp Appliance.

--------- S T A T U S      R E P O R T      P A R T 2 ----------------------------------

Testing the connection from Vdp appliance to SQL Server 10.10.10.55 on port 5106 (connector port)
> udstask testconnection -type tcptest -targetip 10.10.10.55 -targetport 5106
Passed: Vdp is able to communicate with the SQL Server 10.10.10.55 on port 5106

Testing the connection from Vdp appliance to SQL Server 10.10.10.55 on port 443
> udstask testconnection -type tcptest -targetip 10.10.10.55 -targetport 443
---> Failed: Vdp unable to communicate with the SQL Server 10.10.10.55 on port 443

> udsinfo lsconfiguredinterface
The network interface on the Vdp appliance = 10.10.10.1

WIN2K12R2 is already defined earlier in the Vdp appliance . No registration required!

Performing an application discovery on WIN2K12R2 and updating the information in Vdp appliance 10.10.10.1

> udstask appdiscovery -host 19898905

Performing an iSCSI test on WIN2K12R2 from Vdp appliance 10.10.10.1 (optional) :

> udstask iscsitest -host 19898905

Listing all applications discovered on WIN2K12R2 stored in Vdp appliance 10.10.10.1 :

> udsinfo lsapplication | where { $_.HostId -eq 19898905 } | Select-Object AppName, AppType

---------------------------------------------------------------------------

Success!
```

**Perform an actual run on application discovery on the SQL Server and VDP appliance (use the -TopExec switch):**
```
PS C:\users\johndoe\Desktop> .\OnboardSQL.ps1 -srcsql -tgtvdp -vdpip 10.10.10.1 -vdpuser johndoe -vdppassword TopSecret -ToExec
ToExec value is True
I will be gathering information on Windows Host.
I will be gathering information on Sql Server Host.

--------- S T A T U S      R E P O R T      P A R T 1 ----------------------------------

            Computer Name: WIN2K12R2
               IP Address: 10.10.10.55
                     FQDN: Win2k12R2.acme.com
                       OS: Microsoft Windows Server 2012 R2 Datacenter

---------------------------------------------------------------------------

          Domain Firewall: False
         Private Firewall: False
          Public Firewall: False
   iSCSI FireWall Inbound: False
  iSCSI FireWall Outbound: False

Actifio Vdp Ip Pingable  : True
            SQL Server SW: Not Installed
             SQL Instance: No Instances Created
              VSS Writers: Not Installed

---------------------------------------------------------------------------

I will be gathering information on Vdp Appliance.

--------- S T A T U S      R E P O R T      P A R T 2 ----------------------------------

Testing the connection from Vdp appliance to SQL Server 10.10.10.55 on port 5106 (connector port)
> udstask testconnection -type tcptest -targetip 10.10.10.55 -targetport 5106
Passed: Vdp is able to communicate with the SQL Server 10.10.10.55 on port 5106

Testing the connection from Vdp appliance to SQL Server 10.10.10.55 on port 443
> udstask testconnection -type tcptest -targetip 10.10.10.55 -targetport 443
---> Failed: Vdp unable to communicate with the SQL Server 10.10.10.55 on port 443

> udsinfo lsconfiguredinterface
The network interface on the Vdp appliance = 10.10.10.1

WIN2K12R2 is already defined earlier in the Vdp appliance . No registration required!

Performing an application discovery on WIN2K12R2 and updating the information in Vdp appliance 10.10.10.1

> udstask appdiscovery -host 19898905

new     : false
appname : true
missing : true
exists  : false
id      : 19898932 Win2k12R2.acme.com

new     : false
appname : false
missing : true
exists  : true
id      : 21562741 C:\

Performing an iSCSI test on WIN2K12R2 from Vdp appliance 10.10.10.1 (optional) :

> udstask iscsitest -host 19898905
iSCSIport : iqn.1991-05.com.microsoft:win2k12r2.acme.com
Status    : Passed
Test      : Host iSCSI initiator installed and configured

iSCSIport : iqn.1991-05.com.microsoft:win2k12r2.acme.com
Status    : Passed
Test      : Appliance has valid IQN

iSCSIport : iqn.1991-05.com.microsoft:win2k12r2.acme.com
Status    : Passed
Test      : Host has logged into the Appliance iSCSI target

iSCSIport : iqn.1991-05.com.microsoft:win2k12r2.acme.com
Status    : Passed
Test      : Mapping disk from Appliance to host

Listing all applications discovered on WIN2K12R2 stored in Vdp appliance 10.10.10.1 :

> udsinfo lsapplication | where { $_.HostId -eq 19898905 } | Select-Object AppName, AppType
appname : C:\
apptype : FileSystem

---------------------------------------------------------------------------

Success!
```

**Perform a test run on application discovery on the SQL Server with SQL Instance and software installed and VDP appliance:**
```
PS C:\Users\johndoe\Desktop> .\OnboardSql.ps1 -srcsql -tgtvdp -vdpip 10.10.10.1 -vdpuser johndoe -vdppassword 12!pass345
I will be gathering information on Windows Host.
I will be gathering information on Sql Server Host.

--------- S T A T U S      R E P O R T      P A R T 1 ----------------------------------

            Computer Name: DEMO-SQL-2
               IP Address: 10.10.10.22
                     FQDN: demo-sql-2.acme.com
                       OS: Microsoft Windows Server 2019 Standard

---------------------------------------------------------------------------

          Domain Firewall: False
         Private Firewall: False
          Public Firewall: False
   iSCSI FireWall Inbound: False
  iSCSI FireWall Outbound: False

  Actifio Vdp Ip Pingable: True
            SQL Server SW: Installed
             SQL Instance: MSSQLSERVER.InstanceName
     VSS Writer [ State ]: Task Scheduler Writer [ Stable ] ( No error )
     VSS Writer [ State ]: VSS Metadata Store Writer [ Stable ] ( No error )
     VSS Writer [ State ]: Performance Counters Writer [ Stable ] ( No error )
     VSS Writer [ State ]: System Writer [ Stable ] ( No error )
     VSS Writer [ State ]: SqlServerWriter [ Stable ] ( No error )
     VSS Writer [ State ]: WMI Writer [ Stable ] ( No error )
     VSS Writer [ State ]: Shadow Copy Optimization Writer [ Stable ] ( No error )
     VSS Writer [ State ]: Registry Writer [ Stable ] ( No error )
     VSS Writer [ State ]: ASR Writer [ Stable ] ( No error )
     VSS Writer [ State ]: COM+ REGDB Writer [ Stable ] ( No error )

---------------------------------------------------------------------------

I will be gathering information on Vdp Appliance.

--------- S T A T U S      R E P O R T      P A R T 2 ----------------------------------

Testing the connection from Vdp appliance to SQL Server 10.10.10.22 on port 5106 (connector port)
> udstask testconnection -type tcptest -targetip 10.10.10.22 -targetport 5106
Passed: Vdp is able to communicate with the SQL Server 10.10.10.22 on port 5106

Testing the connection from Vdp appliance to SQL Server 10.10.10.22 on port 443
> udstask testconnection -type tcptest -targetip 10.10.10.22 -targetport 443
---> Failed: Vdp unable to communicate with the SQL Server 10.10.10.22 on port 443

> udsinfo lsconfiguredinterface
The network interface on the Vdp appliance = 10.10.10.1

Registering the DEMO-SQL-2 with Actifio Vdp appliance 10.10.10.1

> udstask mkhost -hostname DEMO-SQL-2 -ipaddress 10.10.10.22 -type generic -appliance 10.10.10.1

Updating the description for the DEMO-SQL-2 entry in Actifio Vdp appliance 10.10.10.1

> udstask chhost 19095901 -description "Added by OnboardSql script"

Performing an application discovery on DEMO-SQL-2 and updating the information in Vdp appliance 10.10.10.1

> udstask appdiscovery -host 19095901

Performing an iSCSI test on DEMO-SQL-2 from Vdp appliance 10.10.10.1 (optional) :

> udstask iscsitest -host 19095901

Listing all applications discovered on DEMO-SQL-2 stored in Vdp appliance 10.10.10.1 :

> udsinfo lsapplication | where { $_.HostId -eq 19095901 } | Select-Object AppName, AppType

---------------------------------------------------------------------------

InstanceName
------------
MSSQLSERVER
Success!
```

**Perform a test run on application discovery on the SQL Server with SQL Instance and software installed:**
```
PS C:\Users\johndoe\Desktop> .\OnboardSql.ps1 -srcsql
I will be gathering information on Windows Host.
I will be gathering information on Sql Server Host.

--------- S T A T U S      R E P O R T      P A R T 1 ----------------------------------

            Computer Name: DEMO-SQL-2
               IP Address: 10.10.10.22
                     FQDN: demo-sql-2.acme.com
                       OS: Microsoft Windows Server 2019 Standard


---------------------------------------------------------------------------

          Domain Firewall: False
         Private Firewall: False
          Public Firewall: False
   iSCSI FireWall Inbound: False
  iSCSI FireWall Outbound: False

            SQL Server SW: Installed
             SQL Instance: MSSQLSERVER.InstanceName
     VSS Writer [ State ]: Task Scheduler Writer [ Stable ] ( No error )
     VSS Writer [ State ]: VSS Metadata Store Writer [ Stable ] ( No error )
     VSS Writer [ State ]: Performance Counters Writer [ Stable ] ( No error )
     VSS Writer [ State ]: System Writer [ Stable ] ( No error )
     VSS Writer [ State ]: SqlServerWriter [ Stable ] ( No error )
     VSS Writer [ State ]: WMI Writer [ Stable ] ( No error )
     VSS Writer [ State ]: Registry Writer [ Stable ] ( No error )
     VSS Writer [ State ]: ASR Writer [ Stable ] ( No error )
     VSS Writer [ State ]: Shadow Copy Optimization Writer [ Stable ] ( No error )
     VSS Writer [ State ]: COM+ REGDB Writer [ Stable ] ( No error )

---------------------------------------------------------------------------

InstanceName
------------
MSSQLSERVER

PS C:\Users\johndoe\Desktop>
```
