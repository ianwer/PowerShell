$Wrapper = @()       
$Rows = Import-Csv -Path "C:\temp\VMMigration_INT.csv"
foreach($row in $Rows) 
{
	if ($row.DIRECTORYName -eq $vm) 
	{	
		$adminip 		= $row.ADMIN_IP
		$adminsn 		= $row.ADMIN_Sn
		$admingw 		= $row.ADMIN_Gw
		$admindns1 		= $row.ADMIN_Dns1
		$admindns2 		= $row.ADMIN_Dns2
		$admindns3 		= $row.ADMIN_Dns3
		$admindns4 		= $row.Admin_Dns4
	}
}

$gna1 = Get-WmiObject Win32_NetworkAdapter | Where-Object {$_.NetConnectionID -ne $null}

#Rename the NIC 
foreach($na in $gna1)
{
	if(($na.NetConnectionID -like "*Local Area*") -or ($na.NetConnectionID -eq "ADMIN1"))
	{ 
		$na.NetConnectionID = 'ADMIN'
		$na.Put()
	}
	
	else
	{
		Write-Host "NIC Name is", $na.NetConnectionID
	}
}
#Configure IP , Subnet Mask, Gateway and DNS Server IPs
netsh interface ipv4 set address name="ADMIN" source=static address=$adminip mask=$adminsn gateway=$admingw
netsh interface ipv4 set dnsservers name="ADMIN" source=static address=$admindns1 register=primary validate=no
netsh interface ipv4 add dnsservers name="ADMIN" address=$admindns2 index=2 validate=no
netsh interface ipv4 add dnsservers name="ADMIN" address=$admindns3 index=3 validate=no
netsh interface ipv4 add dnsservers name="ADMIN" address=$admindns4 index=4 validate=no 

#Delete thd Scheduled Task to avoid any issue
SCHTASKS /Delete /TN AmdinIPConfig /F


