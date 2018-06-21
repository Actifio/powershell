
## Overview

This script will connect to the Actifio CDS or Sky systems specified in the appliances.txt file and will build a list of all protected VMware VMs.  It will then initiate a VM discovery (list) for all VMs in specified ESX clusters (based on protectionrules.txt file).  Any previously undiscovered VMs will be added to one of the appliances and a template and profile will be applied, based on the configuration data in the protectionrules.txt file.

New VM protection will use the following logic to determine which of the Actifio appliances will be used for the protection, and on all other appliances that same VM will be flagged as "ignored".

 Appliance with the lowest percentage of used space in the dedup pool, where:
   - the appliance is not over the dedup pool warning threshold
   - the DR partner appliance is not over the dedup pool warning threshold
   - the appliance is not over the snap pool warning threshold
   - the appliance is not over the Vdisk warning threshold

It is designed to be called from a scheduled task on a Windows server, and expects that auto-discovery has been disabled on the desired vCenter servers using the CLI (udstask setautodiscovery -host <vcenterhost> -clear) or GUI (de-select auto-discover box on the host management page in Domain Manager).

This script requires ActPowerCLI to be installed first on any server that will use it.

User must generate a password file with Save-ActPassword command for each appliance, and reference this filename in the "appliances.txt" file.  Be aware that a file generated with
Save-ActPassword is only readable when on the same server where generated, and only while logged in as the same user (i.e. service account) as the one who generated the file.
 
 _NOTE: This script requires the CDS or Sky appliances to be running 7.0.6+ or 7.1.2+ or higher._

