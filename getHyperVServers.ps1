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

param( 
#[Parameter(Mandatory=$true)][String[]]$ServersList
)

$LOGFILE = "logfile.txt"

function DeleteLog( [string]$file )
{
    if(test-path $file)
    { 
        Remove-Item $file 
    } 
}

function Log([string]$text)
{
    write-host  $text
    $timendate = Get-Date -f "yyyy-MM-dd HH:mm:ss"
    $text = $text.Replace( "`r", "" )
    $text = $text.Replace( "`n", "" )
    $text = "$text`n"
    add-content $LOGFILE "$timendate]  $text"
}

function Log1([string]$text)
{
    $timendate = Get-Date -f "yyyy-MM-dd HH:mm:ss"
    $text = $text.Replace( "`r", "" )
    $text = $text.Replace( "`n", "" )
    $text = "$text`n"
    add-content $LOGFILE "$timendate  $text"
}

function startLog( [string]$file )
{
    $backupfile = $file.Replace(".txt", "_bk.txt")
    deleteLog $backupfile
    if(test-path $file)
    {
        rename-item $file $backupfile 
    } 
}
startLog $LOGFILE
#$date = Get-Date  -uformat "%A %B %d, %Y"

$HVServersName = @()
try {            
	Import-Module ActiveDirectory -ErrorAction Stop            
} 

catch {            
	 Write-Warning "Failed to import Active Directory module. Exiting"            
	 return            
}            

try {            
	$Hypervs = Get-ADObject -Filter 'ObjectClass -eq "serviceConnectionPoint" -and Name -eq "Microsoft Hyper-V"' -ErrorAction Stop            
} 

catch {            
	Write-Error "Failed to query active directory. More details : $_"            
}            
foreach($Hyperv in $Hypervs) {
	 $temp = $Hyperv.DistinguishedName.split(",")            
	 $HypervDN = $temp[1..$temp.Count] -join ","            
	 $Comp = Get-ADComputer -Id $HypervDN -Prop *          
	 $sName = $Comp.Name
	 $osVersion = $Comp.operatingSystem
	 $HVServersList = $HVServersList + $sName
         $HVServersName += [PSCustomObject] @{ 'HyperVServer_Name' = $sName; `
						'OS_Version' = $osVersion }								          
} 
$HVServersList | Out-File -FilePath HVServers.txt -Append
$HVServersName | Export-CSV -Path HVServers.csv -NoTypeInformation -Append 


$readallrows = Import-Csv HVServers.csv

Foreach($row in $readallrows)
{
	$computer = $row.HyperVServer_Name
	$osVersion = $row.OS_Version
	$tc = Test-Connection -ComputerName $computer -Count 1 -Delay 2 -TTL 255 -BufferSize 256 -ThrottleLimit 32 -ErrorAction SilentlyContinue
	if ($tc.Statuscode -eq 0)
	{
		$status = "Available"
		try 
		{
			$ghe = [net.dns]::GetHostEntry($Computer).Hostname
		} 
		catch 
		{ 
			$ghe = "Fail"
			#$status = "Not Available"
		}

		#if($ghe -ne $null){$serverName = $ghe}
		$serverName = $ghe
		#try {$dnsresult = [System.Net.DNS]::GetHostEntry($strComputer)}
		#catch {$dnsresult = "Fail"}
	}
	else
	{
		$status = "Not Available"
		$serverName = $computer
		$serverName | Out-File -FilePath Not_Available.txt -Append
	}
	
    
	Try 
    {	
		$pos = $serverName.IndexOf(".")
		$leftPart = $serverName.Substring(0, $pos)
		$rightPart = $serverName.Substring($pos+1)
		if($rightPart -ne $null)
		{
			$envName = $rightPart
		}
		else
		{
			$envName = "default"
		}

		Switch ($envName.ToUpper())
		{

			"CME.LOCAL"
			{
				$envName = "CME"				
				break
			}
			"GME.LOCAL"
			{
				$envName = "GME"				
				break
			}
			"CPM.LOCAL"
			{
				$envName = "CPM"				
				break
			}
			"INDPPE.MSOPPE.MSFT.NET"
			{
				$envName = "INDPPE"				
				break
			}
			"IND001"
			{
				$envName = "IND001"
				break
			}
			"JME.LOCAL"
			{
				$envName = "JME"				
				break
			}
			"JMEBETA.LOCAL"
			{
				$envName = "JMEBETA"				
				break
			}
			"PHX.GBL"
			{
				$envName = "PHX"				
				break
			}
			"RED001.LOCAL"
			{
				$envName = "RED001"				
				break
			}
			"REDMOND.CORP.MICROSOFT.COM"
			{
				$envName = "REDMOND"
				break
			}
			"PROD.SD.NET"
			{
				$envName = "PROD"
				break
			}
			"INT.SDINT.NET"
			{
				$envName = "INT"
				break
			}
			default 
			{
				$envName = "Local Host"
				break
			}
		}
		#$temp = $Hyperv.DistinguishedName.split(",")            
		#$HypervDN = $temp[1..$temp.Count] -join ","            
		#$Comp = Get-ADComputer -Id $HypervDN -Prop *
		#$osVersion = $Comp.operatingSystem   
		$compou = (Get-ADComputer $computer).distinguishedname
		$arrDN = New-Object System.Collections.ArrayList
		$tmparr = $compou.Split(",")
		$ouvlaue2 = $tmparr[2].TrimStart("OU=")
		if ($ouvlaue2 -ne "FencedServices")
		{ $ouvalue = "Not Fenced"}
		else { $ouvalue = $tmparr[1].TrimStart("OU=")}
		$wrapper = New-Object PSObject -Property @{ "Fence_Info" = $ouvalue; "Domain_Name" = $envName; "HyperVServer_Name" = $serverName; "OS_Version" = $osVersion }
		Export-Csv -InputObject $wrapper -path HyperVServers.csv -Append -NoTypeInformation 
		Log1 "`n$computer Status: $status $envName $serverName , $ouvalue"
    } 
    
    Catch 
    {
        Log1 "$computer Status: $status"
    }
} 
Import-Csv HyperVServers.csv | Sort-Object Fence_Info, Domain_Name | Export-Csv HyperVServers-Sorted.csv -NoTypeInformation
Remove-Item HyperVServers.csv
Remove-Item HVServers.csv
