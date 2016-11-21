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
#    Both of these will execute the script named ValidateServers.ps1 and provide each of the server with fqdn names in Systems.txt
#    .\ValidateServers.ps1 -ServersList list.txt
#

param( 
[Parameter(Mandatory=$true)][String[]]$ServersList
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
#$msnpatchcurrent = "2015.02.09.0001"


ForEach ($computer in (Get-Content list.txt)) 
{
	$tc = Test-Connection -ComputerName $computer -Count 1 -Delay 2 -TTL 255 -BufferSize 256 -ThrottleLimit 32 -ErrorAction SilentlyContinue
	

	if ($tc.Statuscode -eq 0)
	{
		$status = "Available"
		try 
		{
			$ghe = [net.dns]::GetHostEntry($Computer).Hostname
			$msnpatch = Invoke-Command -Computer $ghe -ScriptBlock {Get-ItemProperty HKLM:\Software\Microsoft\msnipak\MSNPATCH\}
			$pv = $msnpatch.Version
			
		} 
		catch 
		{ 
			$ghe = "Fail"
			#$status = "Not Available"
		}

		#if($ghe -ne $null){$serverName = $ghe}
		$serverName = $ghe
		$msnp = $pv
		#try {$dnsresult = [System.Net.DNS]::GetHostEntry($strComputer)}
		#catch {$dnsresult = "Fail"}
	}
	else
	{
		$status = "Not Available"
		$serverName = $computer
		$serverName | Out-File -FilePath Not_patched.txt -Append
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
			default 
			{
				$envName = "Local Host"
				break
			}
		}
	    $serverName, $msnp | Out-File -FilePath Patched_Servers.txt -Append
        Log1 "`n$computer Status: $status $envName $serverName $pv"
    } 
    
    Catch 
    {
        Log1 "$computer Status: $status"
    }
}



