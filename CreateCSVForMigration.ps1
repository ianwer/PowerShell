$Wrapper = @()       
$Rows = Import-Csv 1026INTVMMigrationCommands.csv

ForEach ($computer in (Get-Content list.txt)) 
{
	$vm = $computer

	foreach($row in $Rows) 
	{
		if ($row.DIRECTORYName -eq $vm) 
		{	
			
			#assign values to the variable 
			$vmname 	= $row.DIRECTORYName
			$newhost 	= $row.New_VM_Host
			$hypervhost = $row.LegacyCluster
			$cpus 		= $row.Processor
			$Memory 	= "4"
			$minMemory	= "3"
			$maxMemory 	= "8"
			$adminnaname = "ADMIN Network Adapter"
			$swname 	= "Trunked Switch"
			$adminnicname  = "ADMIN"
			$adminvlan 	= $row.TargetAdminVLAN
			$adminip 	= $row.New_ADMIN_IP
			$adminsn 	= $row.New_ADMIN_Mask
			$admingw 	= $row.New_ADMIN_Gateway
			$admindns1 	= $row.DNS1
			$admindns2 	= $row.DNS2
			$admindns3 	= $row.DNS3
			$admindns4 	= $row.DNS4
			$dmznaname 	= "DMZ Network Adapter"
			$dmznicname 	= "DMZ"
			$dmzvlan 	= $row.TargetDMZVLAN
			$dmzip 		= $row.New_DMZ_IP1
			$dmzsn 		= $row.New_DMZ_Mask
			$dmzgw 		= $row.New_DMZ_Gateway
			$dmzdns1 	= $row.DNS1
			$dmzdns2 	= $row.DNS2
			$dmzdns3 	= $row.DNS3
			$dmzdns4 	= $row.DNS4
			$wrapper += [PSCustomObject] @{ 'NewHyperv_Host' = $newhost; `
											'Hyperv_Host' = $hypervhost; `
											'VM_Name' = $vmname; `
											'Switch_Name' = $swname; `
											'ADMIN_VLAN' = $adminvlan; `
											'ADMINNA_Name' = $adminnaname; `
											'ADM_NIC' = $adminnicname; `
											'ADMIN_IP' = $adminip; `
											'ADMIN_Sn' = $adminsn; `
											'ADMIN_Gw' = $admingw; `
											'ADMIN_Dns1' = $admindns1; `
											'ADMIN_Dns2' = $admindns2; `
											'ADMIN_Dns3' = $admindns3; `
											'Admin_Dns4' = $admindns4; `
											'DMZNA_Name' = $dmznaname; `
											'DMZ_VLAN' = $dmzvlan; `
											'DMZ_NIC' = $dmznicname; `
											'DMZ_IP' = $dmzip; `
											'DMZ_Sn' = $dmzsn; `
											'DMZ_Gw' = $dmzgw; `
											'DMZ_Dns1' = $dmzdns1; `
											'DMZ_Dns2' = $dmzdns2; `
											'DMZ_Dns3' = $dmzdns3; `
											'DMZ_Dns4' = $dmzdns4; `
											'Proc_Assigned' = cpus; `
											'Mem_Startup' = $Memory; `
											'Mem_Min' = $minMemory; `
											'Mem_Max' = $maxMemory; `
											'New_DMZ_IP2' = $row.New_DMZ_IP2; `
											'New_DMZ_IP3' = $row.New_DMZ_IP3; `
											'New_DMZ_IP4' = $row.New_DMZ_IP4; `
											'OLD_ADMIN_IP' = $row.OLD_ADMIN_IP; `
											'OLD_DMZ_IP1' = $row.OLD_DMZ_IP1; `
											'OLD_DMZ_IP2' = $row.OLD_DMZ_IP2; `
											'OLD_DMZ_IP3' = $row.OLD_DMZ_IP3; `
											'OLD_DMZ_IP4' = $row.OLD_DMZ_IP4; `
											'RoboCopy' = $row.RoboCopy; `
											'Create_VM' = $row.Create_VM; `
											'Set_VM' = $row.Set_VM; `
											'Remove_VMNetworkAdapter' = $row.Remove_VMNetworkAdapter; `
											'Add_VMNetworkAdapter1' = $row.Add_VMNetworkAdapter1; `
											'Add_VMNetworkAdapter2' = $row.Add_VMNetworkAdapter2; `
											'Set_VMNetworkAdapterVLAN1' = $row.Set_VMNetworkAdapterVLAN1; `
											'Set_VMNetworkAdapterVLAN2' = $row.Set_VMNetworkAdapterVLAN2; `
											'Set_VMParameters' = $row.Set_VMParameters; `
											'Set_ADMIN_IP1' = $row.Set_ADMIN_IP1; `
											'Set_DMZ_IP1' = $row.Set_DMZ_IP1; `
											'Set_DMZ_IP2' = $row.Set_DMZ_IP2; `
											'Set_DMZ_IP3' = $row.Set_DMZ_IP3; `
											'Set_ADMIN_DNS1' = $row.Set_ADMIN_DNS1; `
											'Set_ADMIN_DNS2' = $row.Set_ADMIN_DNS2; `
											'Set_ADMIN_DNS3' = $row.Set_ADMIN_DNS3; `
											'Set_ADMIN_DNS4' = $row.Set_ADMIN_DNS4; `
											'Set_DMZ_DNS1' = $row.Set_DMZ_DNS1; `
											'RenameAdminNIC' = $row.RenameAdminNIC; `
											'RenameDMZNIC' = $row.RenameDMZNIC; `
											'SetPersistentRoute' = $row.SetPersistentRoute }
			#Export-Csv -InputObject $wrapper -path VMMigration_INT.csv -NoType
			
		}
	}
}
#$Wrapper | Format-Table -AutoSize
$Wrapper | Export-CSV -Path VMMigration_INT.csv -NoType