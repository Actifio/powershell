act-protect-new-vms.ps1 -- Tags/OnVault version

NOTE: This script requires the CDS or Sky appliances to be running 7.0.6+ or 7.1.2+ or higher.
      If this is not possible, manual installation of "reporthealth" SARG report is required.

This script will connect to the Actifio CDS or Sky systems specified in the appliances.txt
file and will build a list of all protected VMware VMs.  It will then initiate a VM
discovery (list) for all VMs under the specified vCenter server.  It will then look for all
VMs matching tags specified in the protectionrules.txt file, that are not already protected
or ignored, and will add them to an appliance and protect them with the template/profile
specified in the protectionrules.txt file for that tag.

New VM protection will use the following logic to determine which of the Actifio appliances
will be used for the protection:

Appliance with the lowest amount of MDL consumed, where:
  - the appliance is not over the snap pool warning threshold
  - the appliance is not over the Vdisk warning threshold

It is designed to be called from a scheduled task on a Windows server, and expects that
auto-discovery has been disabled on the desired vCenter servers using the CLI (udstask
setautodiscovery -host <vcenterhost> -clear) or GUI (de-select auto-discover box on
the host management page in Domain Manager).

NOTE: Hard coded exclusion -- any VM with a name ending in _NB (case insensitive) will
      be excluded from auto protection.

This script requires ActPowerCLI to be installed first on any server that will use it.

User must generate one or more password files with the Save-ActPassword command. These
files are used for logins to each appliance, and to vCenter.
Reference these filenames in the "appliances.txt" file and protectionrules.txt file.  Be
aware that a file generated with Save-ActPassword is only readable when on the same server
where generated, and only while logged in as the same user (i.e. service account) as the
one who generated the file.
