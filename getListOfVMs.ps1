#.Synopsis
#    The script will verify the list of servers and availability and return list of available and not verified lists of servers
#    
#.Description
#    Commerce Platform Infra team
#    Date created: 
#    For any assistance "v-ianwer@microsoft.com"
#    
#.PARAMETER InputParam
#    This allows you to specify the parameter for which your input objects are to be evaluated.  As an example, 
#
#.EXAMPLE
#    Both of these will execute the script named HVServersAndVMsList.ps1 and provide each of the server with fqdn names in Systems.txt
#    .\HVServersAndVMsList.ps1 
#
#| Select-Object -Property "Displayname",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
#$YourUSers = $GADUser | Where-Object { $_.DisplayName -like "*$YourName*"} 

Write-Host "Please Enter PHX Credential"
$creds = Get-Credential 
$currentUser = whoami  
$Wrapper = @()       
$Rows = Import-Csv HyperVServers-Sorted.csv

foreach($row in $Rows) 
{
	Try
	{
		$tc = Test-Connection -ComputerName $row.HyperVServer_Name -Count 1 -Delay 2 -TTL 255 -BufferSize 256 -ThrottleLimit 32 -ErrorAction SilentlyContinue
	}
	Catch
	{
		$err = "$_"
		$err = "$hypervserver , Can't access... $_"
		$err | Out-File -FilePath VMs_NotFound_temp.txt -Append
	}
	
	$hypervserver = $row.HyperVServer_Name
	$OSVersion = $row.OS_Version
	if ($OSVersion -eq "Windows Server 2012 R2 Datacenter")
	{
		Try
		{
			$gvm = Get-VM -ComputerName $hypervserver -ErrorAction SilentlyContinue -ErrorVariable +err
		}
		Catch
		{
			$err = "$_"
			$err = "$hypervserver, $_"
			$err | Out-File -FilePath VMs_NotFound_temp.txt -Append
		}
		if ($gvm.Name.Count -eq 0)
		{
			$VMsNotFound = $hypervserver
			$wrapper += [PSCustomObject] @{ 'Fence_Info' = $row.Fence_Info; `
			'Domain_Name' = $row.Domain_Name; `
			'HyperVServer_Name' = $VMsNotFound; `
			'OS_Version' = $row.OS_Version; `
			'VM_Name' = 	"VMs Not Found"; `
			'VM_State' =	""; `
			'VM_OS' =	""; `
			'VM_Uptime' =	""; `
			#							'VM_Health' =	""; `
			'VM_Clustered' = ""; `
			'VM_CPUUsage' =	""; `
			'VM_AutomaticStartAction' =	""; `
			'VM_MemoryAssigned' =	""; `
			'C$_Size' = ""; `
			'C$_Free' = ""; `
			'D$_Size' = ""; `
			'D$_Free' = ""; `
			'E$_Size' = ""; `
			'E$_Free' = ""; `
			'F$_Size' = ""; `
			'F$_Free' = ""; `
			'G$_Size' = ""; `
			'G$_Free' = ""; `
			'H$_Size' = ""; `
			'H$_Free' = ""; `
			'I$_Size' = ""; `
			'I$_Free' = ""; `
			'J$_Size' = ""; `
			'J$_Free' = ""; `
			'K$_Size' = ""; `
			'K$_Free' = ""; `
			'N$_Size' = ""; `
			'N$_Free' = ""; `
			'O$_Size' = ""; `
			'O$_Free' = ""; `
			'T$_Size' = ""; `
			'T$_Free' = ""; `
			'AllDrives_Size' = ""; `
			'AllDrives_Free' = ""; `
			'VM_NetworkAdapters' =	""; `								
			'VM_Path' =	"" }
		}
		
		foreach ($vm in $gvm)
		{
			$vmname = $vm.Name
			$tc = Test-Connection -ComputerName $vmname -Count 1 -Delay 2 -TTL 255 -BufferSize 256 -ThrottleLimit 32 -ErrorAction SilentlyContinue
			if ($tc.Statuscode -eq 0)
			{
				Try
				{
					
					if ($currentUser -ne $creds.UserName)
					{
						$os = Get-WmiObject Win32_OperatingSystem -ComputerName $vmname -Credential $creds
						$gna = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $vmname -Credential $creds | Where-Object {$_.IPAddress -ne $null}
						$gna1 = Get-WmiObject Win32_NetworkAdapter -ComputerName $vmname -Credential $creds | Where-Object {$_.NetConnectionID -ne $null}
					}
					
					else
					{
						$os = Get-WmiObject Win32_OperatingSystem -ComputerName $vmname
						$gna = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $vmname | Where-Object {$_.IPAddress -ne $null}
						$gna1 = Get-WmiObject Win32_NetworkAdapter -ComputerName $vmname | Where-Object {$_.NetConnectionID -ne $null}
					}
				}
				
				Catch
				{
					$err = "$vmname, $_"
					$err | Out-File -FilePath VMs_NotFound_temp.txt -Append
				}
				if ($currentUser -ne $creds.UserName)
				{
					$drives = Get-WmiObject Win32_LogicalDisk -filter "DriveType=3" -computer $vmname -Credential $creds
				}
				
				else
				{
					$drives = Get-WmiObject Win32_LogicalDisk -filter "DriveType=3" -computer $vmname
				}
				$AllDrives = $drives | Select DeviceID,@{Name="Size";Expression={"{0:N0}" -f($_.size/1gb)}},@{Name="FreeSpace";Expression={"{0:N0}" -f($_.freespace/1gb)}} 			
				if($AllDrives.DeviceID -ne $null)
				{
			
					for($i = 0; $i -le $AllDrives.Count; $i++)
					{

						if($AllDrives[$i].DeviceID -eq "C:")
						{
							$drivename0 = $AllDrives[$i].DeviceID
							[int]$drivesize0 = $AllDrives[$i].Size
							[int]$drivefreespace0 = $AllDrives[$i].FreeSpace				
						}

						elseif($AllDrives[$i].DeviceID -eq "D:")
						{
							$drivename1 = $AllDrives[$i].DeviceID
							[int]$drivesize1 = $AllDrives[$i].Size
							[int]$drivefreespace1 = $AllDrives[$i].FreeSpace				
						}
						elseif($AllDrives[$i].DeviceID -eq "E:")
						{
							$drivename2 = $AllDrives[$i].DeviceID
							[int]$drivesize2 = $AllDrives[$i].Size
							[int]$drivefreespace2 = $AllDrives[$i].FreeSpace
						}
						elseif($AllDrives[$i].DeviceID -eq "F:")
						{
							$drivename3 = $AllDrives[$i].DeviceID
							[int]$drivesize3 = $AllDrives[$i].Size
							[int]$drivefreespace3 = $AllDrives[$i].FreeSpace
						}
						elseif($AllDrives[$i].DeviceID -eq "G:")
						{
							$drivename4 = $AllDrives[$i].DeviceID
							[int]$drivesize4 = $AllDrives[$i].Size
							[int]$drivefreespace4 = $AllDrives[$i].FreeSpace
						}
						elseif($AllDrives[$i].DeviceID -eq "H:")
						{
							$drivename5 = $AllDrives[$i].DeviceID
							[int]$drivesize5 = $AllDrives[$i].Size
							[int]$drivefreespace5 = $AllDrives[$i].FreeSpace
						}
						elseif($AllDrives[$i].DeviceID -eq "I:")
						{
							$drivename6 = $AllDrives[$i].DeviceID
							[int]$drivesize6 = $AllDrives[$i].Size
							[int]$drivefreespace6 = $AllDrives[$i].FreeSpace
						}
						elseif($AllDrives[$i].DeviceID -eq "J:")
						{
							$drivename7 = $AllDrives[$i].DeviceID
							[int]$drivesize7 = $AllDrives[$i].Size
							[int]$drivefreespace7 = $AllDrives[$i].FreeSpace
						}
						elseif($AllDrives[$i].DeviceID -eq "K:")
						{
							$drivename8 = $AllDrives[$i].DeviceID
							[int]$drivesize8 = $AllDrives[$i].Size
							[int]$drivefreespace8 = $AllDrives[$i].FreeSpace
						}
						elseif($AllDrives[$i].DeviceID -eq "N:")
						{
							$drivename9 = $AllDrives[$i].DeviceID
							[int]$drivesize9 = $AllDrives[$i].Size
							[int]$drivefreespace9 = $AllDrives[$i].FreeSpace
						}
						elseif($AllDrives[$i].DeviceID -eq "O:")
						{
							$drivename10 = $AllDrives[$i].DeviceID
							[int]$drivesize10 = $AllDrives[$i].Size
							[int]$drivefreespace10 = $AllDrives[$i].FreeSpace
						}
						elseif($AllDrives[$i].DeviceID -eq "T:")
						{
							$drivename11 = $AllDrives[$i].DeviceID
							[int]$drivesize11 = $AllDrives[$i].Size
							[int]$drivefreespace11 = $AllDrives[$i].FreeSpace
						}
						else
						{
							$drivename = ""
							[int]$drivesize = ""
							[int]$drivefreespace = ""	
						}
					}
				}
				
				$allDriveSize = ($drivesize0 + $drivesize1 + $drivesize2 + $drivesize3 + $drivesize4 + $drivesize5 + $drivesize6 + $drivesize7 + $drivesize8 + $drivesize9 + $drivesize10 + $drivesize11)
				$allDriveFreeSpace = ($drivefreespace0 + $drivefreespace1 + $drivefreespace2 + $drivefreespace3 + $drivefreespace4 + $drivefreespace5 + $drivefreespace6 + $drivefreespace7 + $drivefreespace8 + $drivefreespace9 + $drivefreespace10 + $drivefreespace11)

				$vmosn = $os.name
				$vmosname = $vmosn.Substring(0, $vmosn.IndexOf('|'))
				$vmuptm = $os.ConvertToDateTime($os.LastBootUpTime)
				$d = $vmuptm.Day
				$h = $vmuptm.Hour
				$m = $vmuptm.Minute
				$vmuptime = "$d Day(s), $h Hour(s), $m Minute(s)" 
			}
			else
			{
				$vmosname = "VM is turned off"
				$vmuptime = "" 
				$err | Out-File -FilePath VMs_NotFound_temp.txt -Append
			}
			$vmmem = $vm.MemoryAssigned
			$vmmemory = ("{0:N0}" -f($vmmem/1gb))
			$memoryassigned = "$vmmemory GB"
			
			#IP Information
			
			$na1name = $gna1.NetConnectionID[0]
			$na1 = $gna.Description[0]
			$na1ip =  $gna.IPAddress[0]
			$na1ipsubnet = $gna.ipsubnet[0]
			$na1dg = $gna.DefaultIPGateway[0]
			
			$na2name = $gna1.NetConnectionID[1]
			$na2 = $gna.Description[1]
			$na2ip =  $gna.IPAddress[2]
			$na2ipsubnet = $gna.ipsubnet[1]
			$na2dg = $gna.DefaultIPGateway[1]
			
			$networkAdapterDetail = "$na1name, NIC Name $na1, IP Address $na1ip, Subnet $na1ipsubnet, Default Gateway  $na1dg, $na2name NIC Name $na2, IP Address $na2ip, Subnet $na2ipsubnet, Default Gateway  $na2dg"
			
			
			#**********add more stuff*****************
			#$vm.ProcessorCount
			#$vm.CPUUsage
			#$vm.SnapshotFileLocation

			###########
					
			$wrapper += [PSCustomObject] @{ 'Fence_Info' = $row.Fence_Info; `
											'Domain_Name' = $row.Domain_Name; `
											'HyperVServer_Name' = $hypervserver; `
											'OS_Version' = $row.OS_Version; `
											'VM_Name' = 	$vmname; `
											'VM_State' =	$vm.State; `
											'VM_OS' =	$vmosname; `
											'VM_Uptime' =	$vmuptime; `
	#										'VM_Health' =	""; `
											'VM_Clustered' = $vm.IsClustered; `
											'VM_CPUUsage' =	$vm.CPUUsage; `
											'VM_AutomaticStartAction' =	$vm.AutomaticStartAction; `
											'VM_MemoryAssigned' =	$memoryassigned; `
											'C$_Size' = $drivesize0; `
											'C$_Free' = $drivefreespace0; `
											'D$_Size' = $drivesize1; `
											'D$_Free' = $drivefreespace1; `
											'E$_Size' = $drivesize2; `
											'E$_Free' = $drivefreespace2; `
											'F$_Size' = $drivesize3; `
											'F$_Free' = $drivefreespace3; `
											'G$_Size' = $drivesize4; `
											'G$_Free' = $drivefreespace4; `
											'H$_Size' = $drivesize5; `
											'H$_Free' = $drivefreespace5; `
											'I$_Size' = $drivesize6; `
											'I$_Free' = $drivefreespace6; `
											'J$_Size' = $drivesize7; `
											'J$_Free' = $drivefreespace7; `
											'K$_Size' = $drivesize8; `
											'K$_Free' = $drivefreespace8; `
											'N$_Size' = $drivesize9; `
											'N$_Free' = $drivefreespace9; `
											'O$_Size' = $drivesize10; `
											'O$_Free' = $drivefreespace10; `
											'T$_Size' = $drivesize11; `
											'T$_Free' = $drivefreespace11; `
											'AllDrives_Size' = $allDriveSize; `
											'AllDrives_Free' = $allDriveFreeSpace; `
											'VM_NetworkAdapters' =	$networkAdapterDetail; `								
											'VM_Path' =	$vm.Path }
		}
	}							

	else
	{
		Try 
		{
			$gvm = gwmi -Namespace root\virtualization -Class Msvm_ComputerSystem -ComputerName $hypervserver | Where-Object { $_.Caption -like "*Virtual Machine*"}
		}
		Catch
		{
			$err = "$_"
			$err = "$hypervserver, $_"
			$err | Out-File -FilePath VMs_NotFound_temp.txt -Append
		}
		if ($gvm.ElementName.Count -eq 0)
		{
			$VMsNotFound = $hypervserver
			$wrapper += [PSCustomObject] @{ 'Fence_Info' = $row.Fence_Info; `
			'Domain_Name' = $row.Domain_Name; `
			'HyperVServer_Name' = $VMsNotFound; `
			'OS_Version' = $row.OS_Version; `
			'VM_Name' = 	"VMs Not Found"; `
			'VM_State' =	""; `
			'VM_OS' =	""; `
			'VM_Uptime' =	""; `
			#							'VM_Health' =	""; `
			'VM_Clustered' = ""; `
			'VM_CPUUsage' =	""; `
			'VM_AutomaticStartAction' =	""; `
			'VM_MemoryAssigned' =	""; `
			'C$_Size' = ""; `
			'C$_Free' = ""; `
			'D$_Size' = ""; `
			'D$_Free' = ""; `
			'E$_Size' = ""; `
			'E$_Free' = ""; `
			'F$_Size' = ""; `
			'F$_Free' = ""; `
			'G$_Size' = ""; `
			'G$_Free' = ""; `
			'H$_Size' = ""; `
			'H$_Free' = ""; `
			'I$_Size' = ""; `
			'I$_Free' = ""; `
			'J$_Size' = ""; `
			'J$_Free' = ""; `
			'K$_Size' = ""; `
			'K$_Free' = ""; `
			'N$_Size' = ""; `
			'N$_Free' = ""; `
			'O$_Size' = ""; `
			'O$_Free' = ""; `
			'T$_Size' = ""; `
			'T$_Free' = ""; `
			'AllDrives_Size' = ""; `
			'AllDrives_Free' = ""; `
			'VM_NetworkAdapters' =	""; `								
			'VM_Path' =	"" }
		}
		foreach ($vm in $gvm)
		{
			$vmname = $vm.ElementName
			$tc = Test-Connection -ComputerName $vmname -Count 1 -Delay 2 -TTL 255 -BufferSize 256 -ThrottleLimit 32 -ErrorAction SilentlyContinue
			if ($tc.Statuscode -eq 0)
			{
				Try
				{
					$os = Get-WmiObject Win32_OperatingSystem -ComputerName $vmname
					$gna = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $vmname | Where-Object {$_.IPAddress -ne $null}
					$gna1 = Get-WmiObject Win32_NetworkAdapter -ComputerName $vmname | Where-Object {$_.NetConnectionID -ne $null}
				}
				
				Catch
				{
					$err = "$_"
					$err = "$vmname, $_"
					$err | Out-File -FilePath VMs_NotFound_temp.txt -Append
				}
				$vmosn = $os.name
				$vmosname = $vmosn.Substring(0, $vmosn.IndexOf('|'))
				$vmuptm = $os.ConvertToDateTime($os.LastBootUpTime)
				$d = $vmuptm.Day
				$h = $vmuptm.Hour
				$m = $vmuptm.Minute
				$vmuptime = "$d Day(s), $h Hour(s), $m Minute(s)" 
			}
			else
			{
				$vmosname = "VM is turned off"
				$vmuptime = "" 
				$err | Out-File -FilePath VMs_NotFound_temp.txt -Append 
			}
			if (($gvm.EnabledState -ne $false) -and ($gvm.EnabledState -ne ""))
			{
				$vmstate = $gvm.EnabledState
				Switch ($vmstate)
				{
					"0"
					{
						$vmstate = "Unknown"				
						break
					}
					"2"
					{
						$vmstate = "VM is Running"				
						break
					}
					"3"
					{
						$vmstate = "Turned Off"				
						break
					}
					"32768"
					{
						$vmstate = "Paused"				
						break
					}
					"32769"
					{
						$vmstate = "Suspended"				
						break
					}
					"32770"
					{
						$vmstate = "Starting"				
						break
					}
					"32771"
					{
						$vmstate = "Snapshotting"				
						break
					}
					"32773"
					{
						$vmstate = "Saving"				
						break
					}
					"32774"
					{
						$vmstate = "Stopping"				
						break
					}
					"32776"
					{
						$vmstate = "Pausing"				
						break
					}
					"32777"
					{
						$vmstate = "Resuming"				
						break
					}
					default 
					{
						$vmstate = ""
					}
				}
			}
			Elseif (($gvm.OpertionalStatus -ne $false) -and ($gvm.OpertionalStatus -ne ""))
			{
				$vmstate = $gvm.OpertionalStatus
				Switch ($vmstate)
				{
					"2"
					{
						$vmstate = "Operating Normally"				
						break
					}
					"3"
					{
						$vmstate = "Degraded"				
						break
					}
					"5"
					{
						$vmstate = "Predictive Failure"				
						break
					}
					"10"
					{
						$vmstate = "Stopped"				
						break
					}
					"11"
					{
						$vmstate = "In Service"				
						break
					}
					"15"
					{
						$vmstate = "Dormant"				
						break
					}
					default 
					{
						$vmstate = ""
					}	
				}
			}

			Elseif (($gvm.StatusDescriptions -ne $false) -and ($gvm.StatusDescriptions -ne ""))
			{
				{$vmstate = $gvm.StatusDescriptions[0]}
			}
			Else
			{
				$vmstate = " "
			}

			$drives = Get-WmiObject Win32_LogicalDisk -filter "DriveType=3" -computer $vmname
			#decimal point 1 valies
			#$AllDrives = $drives | Select DeviceID,@{Name="Size(GB)";Expression={"{0:N1}" -f($_.size/1gb)}},@{Name="FreeSpace(GB)";Expression={"{0:N1}" -f($_.freespace/1gb)}} 
			#rounded values of Size and Free Space
			$AllDrives = $drives | Select DeviceID,@{Name="Size";Expression={"{0:N0}" -f($_.size/1gb)}},@{Name="FreeSpace";Expression={"{0:N0}" -f($_.freespace/1gb)}} 
			if($AllDrives.DeviceID -ne $null)
			{
				for($i = 0; $i -le $AllDrives.Count; $i++)
				{

					if($AllDrives[$i].DeviceID -eq "C:")
					{
						$drivename0 = $AllDrives[$i].DeviceID
						[int]$drivesize0 = $AllDrives[$i].Size
						[int]$drivefreespace0 = $AllDrives[$i].FreeSpace				
					}

					elseif($AllDrives[$i].DeviceID -eq "D:")
					{
						$drivename1 = $AllDrives[$i].DeviceID
						[int]$drivesize1 = $AllDrives[$i].Size
						[int]$drivefreespace1 = $AllDrives[$i].FreeSpace				
					}
					elseif($AllDrives[$i].DeviceID -eq "E:")
					{
						$drivename2 = $AllDrives[$i].DeviceID
						[int]$drivesize2 = $AllDrives[$i].Size
						[int]$drivefreespace2 = $AllDrives[$i].FreeSpace
					}
					elseif($AllDrives[$i].DeviceID -eq "F:")
					{
						$drivename3 = $AllDrives[$i].DeviceID
						[int]$drivesize3 = $AllDrives[$i].Size
						[int]$drivefreespace3 = $AllDrives[$i].FreeSpace
					}
					elseif($AllDrives[$i].DeviceID -eq "G:")
					{
						$drivename4 = $AllDrives[$i].DeviceID
						[int]$drivesize4 = $AllDrives[$i].Size
						[int]$drivefreespace4 = $AllDrives[$i].FreeSpace
					}
					elseif($AllDrives[$i].DeviceID -eq "H:")
					{
						$drivename5 = $AllDrives[$i].DeviceID
						[int]$drivesize5 = $AllDrives[$i].Size
						[int]$drivefreespace5 = $AllDrives[$i].FreeSpace
					}
					elseif($AllDrives[$i].DeviceID -eq "I:")
					{
						$drivename6 = $AllDrives[$i].DeviceID
						[int]$drivesize6 = $AllDrives[$i].Size
						[int]$drivefreespace6 = $AllDrives[$i].FreeSpace
					}
					elseif($AllDrives[$i].DeviceID -eq "J:")
					{
						$drivename7 = $AllDrives[$i].DeviceID
						[int]$drivesize7 = $AllDrives[$i].Size
						[int]$drivefreespace7 = $AllDrives[$i].FreeSpace
					}
					elseif($AllDrives[$i].DeviceID -eq "K:")
					{
						$drivename8 = $AllDrives[$i].DeviceID
						[int]$drivesize8 = $AllDrives[$i].Size
						[int]$drivefreespace8 = $AllDrives[$i].FreeSpace
					}
					elseif($AllDrives[$i].DeviceID -eq "N:")
					{
						$drivename9 = $AllDrives[$i].DeviceID
						[int]$drivesize9 = $AllDrives[$i].Size
						[int]$drivefreespace9 = $AllDrives[$i].FreeSpace
					}
					elseif($AllDrives[$i].DeviceID -eq "O:")
					{
						$drivename10 = $AllDrives[$i].DeviceID
						[int]$drivesize10 = $AllDrives[$i].Size
						[int]$drivefreespace10 = $AllDrives[$i].FreeSpace
					}
					elseif($AllDrives[$i].DeviceID -eq "T:")
					{
						$drivename11 = $AllDrives[$i].DeviceID
						[int]$drivesize11 = $AllDrives[$i].Size
						[int]$drivefreespace11 = $AllDrives[$i].FreeSpace
					}
					else
					{
						$drivename = ""
						[int]$drivesize = ""
						[int]$drivefreespace = ""	
					}
				
				}
			}
			
			$allDriveSize = ($drivesize0 + $drivesize1 + $drivesize2 + $drivesize3 + $drivesize4 + $drivesize5 + $drivesize6 + $drivesize7 + $drivesize8 + $drivesize9 + $drivesize10 + $drivesize11)
			$allDriveFreeSpace = ($drivefreespace0 + $drivefreespace1 + $drivefreespace2 + $drivefreespace3 + $drivefreespace4 + $drivefreespace5 + $drivefreespace6 + $drivefreespace7 + $drivefreespace8 + $drivefreespace9 + $drivefreespace10 + $drivefreespace11)
			
			#IP Information
			#$gna = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $vmname | Where-Object {$_.IPAddress -ne $null}
			#$gna1 = Get-WmiObject Win32_NetworkAdapter -ComputerName $vmname | Where-Object {$_.NetConnectionID -ne $null}
			
			$na1name = $gna1.NetConnectionID[0]
			$na1 = $gna.Description[0]
			$na1ip =  $gna.IPAddress[0]
			$na1ipsubnet = $gna.ipsubnet[0]
			$na1dg = $gna.DefaultIPGateway[0]
			
			$na2name = $gna1.NetConnectionID[1]
			$na2 = $gna.Description[1]
			$na2ip =  $gna.IPAddress[2]
			$na2ipsubnet = $gna.ipsubnet[1]
			$na2dg = $gna.DefaultIPGateway[1]
			
			$networkAdapterDetail = "$na1name, NIC Name $na1, IP Address $na1ip, Subnet $na1ipsubnet, Default Gateway  $na1dg, $na2name NIC Name $na2, IP Address $na2ip, Subnet $na2ipsubnet, Default Gateway  $na2dg"
			
			#vm path
			Try
			{
				$Testpath1 = Test-Path -Path "\\$hypervserver\d$\Virtual Machines\$vmname"
				if($Testpath1 -ne $false)
				{
					$gci = Get-ChildItem "\\$hypervserver\d$\Virtual Machines\$vmname"
					if ($gci[0].PSPath -ne $null)
					{
						$vmf = $gci[0].PSPath
						$vmFolderPath = $vmf.TrimStart("Microsoft.PowerShell.Core\FileSystem")
					}	
					else
					{
						$vmFolderPath = "Path not found"
					}	
				}
				else
				{
					$Testpath2 = Test-Path -Path "\\$hypervserver\d$\Hyper-V\$vmname"
					if($Testpath2 -ne $false)
					{
						$gci = Get-ChildItem "\\$hypervserver\d$\Hyper-V\$vmname"
						if ($gci[0].PSPath -ne $null)
						{
							$vmf = $gci[0].PSPath
							$vmFolderPath = $vmf.TrimStart("Microsoft.PowerShell.Core\FileSystem")
						}
						
						else
						{
							$vmFolderPath = "Path not found"
						}				
					}
					else
					{
						$Testpath3 = Test-Path -Path "\\$hypervserver\e$\Hyper-V\$vmname"
						if($Testpath3 -ne $false)
						{
							$gci = Get-ChildItem "\\$hypervserver\e$\Hyper-V\$vmname"
							if ($gci[0].PSPath -ne $null)
							{
								$vmf = $gci[0].PSPath
								$vmFolderPath = $vmf.TrimStart("Microsoft.PowerShell.Core\FileSystem")
							}
							
							else
							{
								$vmFolderPath = "Folder Path not found"
							}					
						}
					}
					else
					{
						$TestPath ="Path Not Validated"
					}
				}
			}
			catch
			{
				$err = "$_"
			}
				
		
			
			$wrapper += [PSCustomObject] @{ 'Fence_Info' = $row.Fence_Info; `
					'Domain_Name' = $row.Domain_Name; `
					'HyperVServer_Name' = $hypervserver; `
					'OS_Version' = $row.OS_Version; `
					'VM_Name' = $vmname; `
					'VM_State' =	$vmstate; `
					'VM_OS' =	$vmosname; `
					'VM_Uptime' =	$vmuptime; `
					#'VM_Health' =	""; `
					'VM_Clustered' = ""; `
					'VM_CPUUsage' =	""; `
					'VM_AutomaticStartAction' =	""; `
					'VM_MemoryAssigned' =	""; `
					'C$_Size' = $drivesize0; `
					'C$_Free' = $drivefreespace0; `
					'D$_Size' = $drivesize1; `
					'D$_Free' = $drivefreespace1; `
					'E$_Size' = $drivesize2; `
					'E$_Free' = $drivefreespace2; `
					'F$_Size' = $drivesize3; `
					'F$_Free' = $drivefreespace3; `
					'G$_Size' = $drivesize4; `
					'G$_Free' = $drivefreespace4; `
					'H$_Size' = $drivesize5; `
					'H$_Free' = $drivefreespace5; `
					'I$_Size' = $drivesize6; `
					'I$_Free' = $drivefreespace6; `
					'J$_Size' = $drivesize7; `
					'J$_Free' = $drivefreespace7; `
					'K$_Size' = $drivesize8; `
					'K$_Free' = $drivefreespace8; `
					'N$_Size' = $drivesize9; `
					'N$_Free' = $drivefreespace9; `
					'O$_Size' = $drivesize10; `
					'O$_Free' = $drivefreespace10; `
					'T$_Size' = $drivesize11; `
					'T$_Free' = $drivefreespace11; `
					'AllDrives_Size' = $allDriveSize; `
					'AllDrives_Free' = $allDriveFreeSpace; `
					'VM_NetworkAdapters' =	$networkAdapterDetail; `								
					'VM_Path' =	$vmFolderPath }
		
		}
		$VMsNotFound | Out-File -FilePath VMs_NotFound_temp.txt -Append             
		 
	}
}

$hash = @{}	
gc VMs_NotFound_temp.txt | %{if($hash.$_ -eq $null) { $_ }; $hash.$_ = 1} > VMs_NotFound.txt
Remove-Item VMs_NotFound_temp.txt
$Wrapper | Format-Table -AutoSize
$Wrapper | Export-CSV -Path HypervServersAndVMs.csv  -NoType