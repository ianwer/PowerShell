# This script will perform post deployment configurations "Before Reboot" after OS is installed on Hyper-V Server
# COMMERCE_LAB
# Date Modified: 7/30/2015
# For any assistance "v-ianwer@microsoft.com"

#param([Parameter(Mandatory)] $ComputerName) 
Set-ExecutionPolicy Unrestricted

$LOGFILE = "FWRValidation.txt"

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
    $timendate = Get-Date –f "yyyy-MM-dd HH:mm:ss"
    $text = $text.Replace( "`r", "" )
    $text = $text.Replace( "`n", "" )
    $text = "$text`n"
    add-content $LOGFILE "$timendate  $text"
}
function Log1([string]$text)
{
    $timendate = Get-Date –f "yyyy-MM-dd HH:mm:ss"
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
Log "*** Performing Firewall Rules Validation ***"
$list = "List.txt"
$ServerList = Get-Content $list
#****Set Firewall rule to enable "Simpana...”****

foreach ($server in $serverlist)
{
	Log ("Firewall rules on", $server)
	$GFWR = Get-NetFirewallRule | Where {$_.DisplayName -Match "Simpana"}
	Foreach($fwr in $GFWR)
	{
		if($fwr.Enabled -eq $False)
		{
			
			#Set-NetFirewallRule -DisplayGroup “Remote Desktop” -Direction Inbound –Enabled True -ErrorAction SilentlyContinue
			#Start-Sleep -Seconds 3
			Log ($fwr.DisplayName, "Status Enabled is ", $fwr.Enabled)
		}
		Else
		{	
			Log ("Firewall Rule for", $fwr.DisplayName, "is already Enabled")
		}
	}
}

