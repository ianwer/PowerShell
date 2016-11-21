$Wrapper = @()       
$Rows = Import-Csv -Path "C:\temp\VMMigration_INT.csv"
foreach($row in $Rows) 
{
	if ($row.DIRECTORYName -eq $vm) 
	{	
		$dmzip 		= $row.DMZ_IP
		$dmzsn 		= $row.DMZ_Sn
		$dmzgw 		= $row.DMZ_Gw
		$dmzdns1 		= $row.DMZ_Dns1
		$dmzdns2 		= $row.DMZ_Dns2
		$dmzdns3 		= $row.DMZ_Dns3
		$dmzdns4 		= $row.DMZ_Dns4		
	}
}

$gna1 = Get-WmiObject Win32_NetworkAdapter | Where-Object {$_.NetConnectionID -ne $null}

#Rename the NIC 
foreach($na in $gna1)
{
	if(($na.NetConnectionID -like "*Local Area*") -or ($na.NetConnectionID -eq "DMZ1"))
	{ 
		$na.NetConnectionID = 'DMZ'
		$na.Put()
	}
	
	else
	{
		Write-Host "NIC Name is", $na.NetConnectionID
	}
}
#Configure IP , Subnet Mask, Gateway and DNS Server IPs
netsh interface ipv4 set address name="DMZ" source=static address=$dmzip mask=$dmzsn gateway=$dmzgw
netsh interface ipv4 set dnsservers name="DMZ" source=static address=$dmzdns1 register=primary validate=no
netsh interface ipv4 add dnsservers name="DMZ" address=$dmzdns2 index=2 validate=no
netsh interface ipv4 add dnsservers name="DMZ" address=$dmzdns3 index=3 validate=no
netsh interface ipv4 add dnsservers name="DMZ" address=$dmzdns4 index=4 validate=no 

#Delete thd Scheduled Task to avoid any issue
SCHTASKS /Delete /TN DMZIPConfig /F


