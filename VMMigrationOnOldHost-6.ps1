#VM Migration part-I, to be run on the VM
write-host "VM Migration part-I"
$getcreds = Get-Credential -Credential sdops
$usr = $getcreds.UserName
$pwd = $getcreds.GetNetworkCredential().password
$EnableUser = 512
$user = $usr
$Password = $pwd
$Wrapper = @()       
$Rows = Import-Csv VMMigration_INT.csv
foreach($row in $Rows) 
{
	$vmname = $row.VM_Name
	write-host "Starting migration for VM ",$vmname
	$newhost = $row.NewHyperv_Host
	$hypervhost = $row.Hyperv_Host
	$user = [adsi]"WinNT://$vmname/$user,user"
	Write-Host "Enabling and setting password for localadmin on ", $vmname
	$user.description = "Enabled Account"
	$user.userflags = $EnableUser
	$user.SetPassword($Password)
	$user.SetInfo()
	
	#rename network adapters if they are named as ADMIN or DMZ
	$gna1 = Get-WmiObject Win32_NetworkAdapter -ComputerName $vmname | Where-Object {$_.NetConnectionID -ne $null}
	$nicname = $gna1[0].NetConnectionID
	if(($nicname -eq "Admin") -or ($nicname -eq "ADMIN"))
	{
		write-host "Renaming ...",$nicname, "to ADMIN1"
		$gna1[0].NetConnectionID = 'ADMIN1'
		$gna1[0].Put()
	}
	else
	{
		write-host "No need to change as the NIC name is ",$nicname
	}
	$nicname1 = $gna1[1].NetConnectionID
	if(($nicname -eq "dmz") -or ($nicname -eq "DMZ"))
	{
		write-host "Renaming ...",$nicname, "to DMZ1"
		$gna1[1].NetConnectionID = 'DMZ1'
		$gna1[1].Put()
	}
	else
	{
		write-host "No need to change as the NIC name is ",$nicname1
	}
	

	copy-Item VMMigration_INT.csv -Destination \\$vmname\c$\temp\ -Force
	copy-Item SetNetConfigAdminNic.ps1 -Destination \\$vmname\c$\temp\ -Force
	copy-Item SetNetConfigDMZNic.ps1 -Destination \\$vmname\c$\temp\ -Force
	
	
	#Create creds for use on scheduled task
	SCHTASKS /Create /RU "NT AUTHORITY\SYSTEM" /RL HIGHEST /S $vmname /TN AdminIPConfig /SC ONSTART /TR "powershell.exe c:\temp\SetNetConfigAdminNic.ps1"
	Start-Sleep -Seconds 30


	#Shutdown the VM - shutdown -S -t 0 -c "Migration" 
	Write-Host "Shutting down ", $vmname, "..."
	shutdown -s -m \\$vmname 
	Write-Host "Waiting until ", $vmname, "is shutting down ..."
	Start-Sleep -Seconds 110
	
	#Copy VHDs to the new hyper-v host
	#$gvmpath = Get-ChildItem C:\ClusterStorage -recurse | Where-Object {$_.PSIsContainer -eq $true -and $_.Name -match $vmname}
	write-host "Finding VM folder path on the local machine..."
	$gvmpath = Get-ChildItem "D:\Iqbal" -recurse | Where-Object {$_.PSIsContainer -eq $true -and $_.Name -match $vmname}
	$vmpath = $gvmpath.PSPath
	if($vmpath -eq $null){ $vmpath = $gvmpath[0].PSPath}
	$vmptrim = $vmpath.TrimStart("Microsoft.PowerShell.Core\FileSystem")
	$vmptrim1 = $vmptrim.TrimStart("::")
	$source = '"'+$vmptrim1+'"'

	#create folder for $vmname on the new host fi does not exist
	Write-Host "Checking folder", $vmname, "is already there if not create one"
	$vmpath = "\\$newhost\X$\VMs\$vmname"
	$Testpath = Test-Path -Path $vmpath
	if($Testpath -ne $true)
	{
		New-Item $vmpath -type directory
		write-host "folder ", $vmname, "has been created on the ", $newhost
	}
	else
	{
		Write-Host "Folder $vmname already exist - $Testpath"
	}
	
	#now set the destination
	$destination = '"'+"\\"+$newhost+"\X$\VMs\"+$vmname+'"'
	Write-Host "Source path", $source
	Write-Host "Destination path", $destination
	Write-Host "Running robocopy command to copy VHD from existing hyper-v to new hyper-v server"
	#write-host "Please run on different powershell windows-- robocopy $source $destination /ZB"
	$robocopyoptions = "/ZB"
	robocopy $source $destination $robocopyoptions
	#invoke-expression -Command "cmd /c start powershell -NoExit -command {robocopy $source $destination $robocopyoptions}"
}
