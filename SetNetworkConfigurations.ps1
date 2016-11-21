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
		#$dmzip 		= $row.DMZ_IP
		#$dmzsn 		= $row.DMZ_Sn
		#$dmzgw 		= $row.DMZ_Gw
		#$dmzdns1 		= $row.DMZ_Dns1
		#$dmzdns2 		= $row.DMZ_Dns2
		#$dmzdns3 		= $row.DMZ_Dns3
		#$dmzdns4 		= $row.DMZ_Dns4

		
	}
}

$gna1 = Get-WmiObject Win32_NetworkAdapter | Where-Object {$_.NetConnectionID -ne $null}

#Rename the NIC 
foreach($na in $gna1)
{
	if($na.NetConnectionID -eq "Local Area Connection")
	{ 
		$na.NetConnectionID = 'ADMIN'
		$na.Put()
	}
}
#Configure IP , Subnet Mask, Gateway and DNS Server IPs
netsh interface ipv4 set address name="TEST" source=static address=$adminip mask=$adminsn gateway=$admingw
netsh interface ipv4 set dnsservers name="TEST" source=static address=$admindns1 register=primary validate=no
netsh interface ipv4 add dnsservers name="TEST" address=$admindns2 index=2 validate=no
netsh interface ipv4 add dnsservers name="TEST" address=$admindns3 index=3 validate=no
netsh interface ipv4 add dnsservers name="TEST" address=$admindns4 index=4 validate=no 

#Delete thd Scheduled Task to avoid any issue
SCHTASKS /Delete /TN test /F


