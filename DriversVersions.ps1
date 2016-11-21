#.Synopsis
#    The script will provide drivers version information from a list of servers- 
#    Login to one of the servers from the list of servers and you will not required to enter credentials - save the list of servers to the location where the script will be run
#.Description
#    Commerce Platform Infra team
#    Date created: 
#    For any assistance "v-ianwer@microsoft.com"
#    
#.PARAMETER InputParam
#    This allows you to specify the parameter for which your input objects are to be evaluated.  As an example, 
#
#.EXAMPLE
#    Both of these will execute the script named DriversVersions.ps1 and provide each of the server with fqdn names in Systems.txt
#    .\DriversVersions.ps1 -ServersList list.txt
#

param
( 
	[Parameter(Mandatory=$true)][String[]]$ServersList
)

ForEach ($computer in (Get-Content list.txt)) 
{
	$tc = Test-Connection -ComputerName $computer -Count 1 -Delay 2 -TTL 255 -BufferSize 256 -ThrottleLimit 32 -ErrorAction SilentlyContinue
	if ($tc.Statuscode -eq 0)
	{
		Try 
		{	
			$driversver = Get-WmiObject Win32_PnPSignedDriver -ComputerName $computer | select devicename, driverversion -Unique
			for($i = 0; $i -le $driversver.Count; $i++)
			{
				$wrapper = [PSCustomObject] @{ 'Server_Name' = $computer; `
				'Device_Name' = $driversver[$i].devicename; `
				'Driver_Version' = $driversver[$i].driverversion}	
				Export-Csv -InputObject $wrapper -path DriversVersionsDetail.csv -Append -NoTypeInformation
			} 
		}
		Catch 
		{
			$error | Out-File -FilePath Errors.txt -Append
		}
	}
	else
	{
		$status = "Not Available"
		$NotavAilableServers = $computer + $status
		$NotavAilableServers | Out-File -FilePath Not_Available.txt -Append
	}
}