$Wrapper = @()       
$Rows = Import-Csv VMMigration_INT.csv
foreach($row in $Rows) 
{
	#assign values to the variable 
	[int64]$startupmem = $row.Mem_Startup
	$Memory = 1GB*$startupmem
	[int64]$minmem = $row.Mem_Min
	$minMemory = 1GB*$minmem
	[int64]$maxmem = $row.Mem_Max
	$maxMemory = 1GB*$maxmem
	$newhost = $row.NewHyperv_Host
	$adminnaname = $row.ADMINNA_Name
	$swname = $row.Switch_Name
	$adminvlan = $row.ADMIN_VLAN
	$cpus = $row.Proc_Assigned
	$dmznaname = $row.DMZNA_Name
	$adminip = $row.ADMIN_IP
	$adminsn = $row.ADMIN_Sn
	$admindns1 = $row.ADMIN_Dns1
	$admindns2 = $row.ADMIN_Dns2
	$admindns3 = $row.ADMIN_Dns3
	$admindns4 = $row.ADMIN_Dns4
	$dmzip = $row.DMZ_IP
	$dmzvlan = $row.DMZ_VLAN
	$dmzsn = $row.DMZ_Sn
	$dmzgw = $row.DMZ_Gw
	$dmzdns1 = $row.DMZ_Dns1
	$dmzdns2 = $row.DMZ_Dns2
	$dmzdns3 = $row.DMZ_Dns3
	$dmzdns4 = $row.DMZ_Dns4
	
	#$vmname
	$vmname = $row.VM_Name

	Write-Host "Virtual Machine Name :",$vmname
	Write-Host "Hyper-v Host Name    :",$newhost
	Write-Host "Number of CPUs       :",$cpus
	Write-Host "Startup Memory       :",$Memory
	Write-Host "Minimum Memory       :",$minMemory
	Write-Host "Maximum Memory       :",$maxMemory
	Write-Host "Admin NIC Name       :",$adminnaname
	Write-Host "Hyper-v Switch Name  :",$swname	
	Write-Host "Admin VLAN ID        :",$adminvlan
	Write-Host "Admin IP             :",$adminip
	Write-Host "Admin Subnet Mask    :",$adminsn
	Write-Host "Admin DNS IP1        :",$admindns1
	Write-Host "Admin DNS IP2        :",$admindns2
	Write-Host "Admin DNS IP3        :",$admindns3
	Write-Host "Admin DNS IP4        :",$admindns4
	Write-Host "DMZ NIC Name         :",$dmznaname
	Write-Host "DMZ VLAN ID          :",$dmzvlan
	Write-Host "DMZ IP               :",$dmzip
	Write-Host "DMZ Subnet Mask      :",$dmzsn
	Write-Host "DMZ Gateway IP       :",$dmzgw
	Write-Host "DMZ DNS IP1          :",$dmzdns1
	Write-Host "DMZ DNS IP1          :",$dmzdns2
	Write-Host "DMZ DNS IP1          :",$dmzdns3
	Write-Host "DMZ DNS IP1          :",$dmzdns4

	#VHD path and VHD name
	$vmFolderPath = "X:\VMs\$vmname"
	$gci = Get-ChildItem X:\VMs\$vmname
	$vhd = $gci.name
	$vmpath = $gci.PSPath
	$vmptrim = $vmpath.TrimStart("Microsoft.PowerShell.Core\FileSystem")
	$vmptrim1 = $vmptrim.TrimStart("::")
	$vhdpath = $vmptrim1
	Write-Host "VM Name :",$vmname
	Write-Host "VM Folder Path :",$vmFolderPath
	Write-Host "VHD Name :",$vhd
	Write-Host "VHD Path :",$vhdpath

	#Create VM
	Write-Host "Creating Virtual Machine $vmname..."
	New-VM -Name $vmname -MemoryStartupBytes $Memory -VHDPath $vhdpath
	Start-Sleep -Seconds 30
	
	#Create Snapshot Folder
	Write-Host "Creating Virtual Machine Snapshot..."
	Set-VM –Name $vmname -SmartPagingFilePath $vmFolderPath -SnapshotFileLocation $vmFolderPath

	#Remove Network Adapter
	Write-Host "Removing Network Adapter..."
	remove-VMNetworkAdapter -VMName $vmname

	#Add Network Adapter
	Write-Host "Adding ADMIN Network Adapter..."
	Add-VMNetworkAdapter -Name $adminnaname -VMName $vmname -SwitchName $swname

	#Configure Network Adapter
	Write-Host "Setting ADMIN Network Adapter..."
	Set-VMNetworkAdapterVlan -VMName $vmname -VMNetworkAdapterName $adminnaname -Access -VLANID $adminvlan

	#Configure VM
	Write-Host "Configuring Virtual Machine..."
	Stop-VM -Name $vmname -Passthru | Set-VM -ProcessorCount $cpus -DynamicMemory -MemoryStartupBytes $Memory -MemoryMaximumBytes $maxMemory -MemoryMinimumBytes $minMemory -AutomaticStartAction StartIfRunning -Passthru | Start-VM 
	Start-Sleep -Seconds 60
	
	#Add DMZ IPs
	Write-Host "Creating Schedule Task..."
	SCHTASKS /Create /RU "NT AUTHORITY\SYSTEM" /RL HIGHEST /S $vmname /TN DMZIPConfig /SC ONSTART /TR "powershell.exe c:\temp\SetNetConfigDMZNic.ps1"
	Start-Sleep -Seconds 30
	
	#Shutdown the VM and - add the DMZ NIC
	Write-Host "Shutting down ", $vmname, "..."
	#shutdown -s -m \\$vmname 
	Write-Host "Waiting until ", $vmname, "is shutting down ..."
	Start-Sleep -Seconds 140
	
	#Add Network Adapter
	Write-Host "Adding DMZ Network Adapter..."
	Add-VMNetworkAdapter -Name $dmznaname -VMName $vmname -SwitchName $swname

	#Configure Network Adapter
	Write-Host "Setting DMZ Network Adapter..."
	Set-VMNetworkAdapterVlan -VMName $vmname -VMNetworkAdapterName $dmznaname -Access -VLANID $dmzvlan
	
	Write-Host "Starting Virtual Machine..."
	Start-VM -Name $vmname
	
	Write-Host "Completed"
}