# The script is designed to collect specific file information from all servers in the server list
# Commerce
# Date Modified: 1/20/2015
# For any assistance "v-ianwer@microsoft.com"
#

param( 
        [Parameter][String[]]$ServersFile
	#[Parameter(Mandatory=$true)][String[]]$list,        
        #,[Parameter(Mandatory=$true)][Alias("Path")][String]$BackupPath,
)

$LOGFILE = "Config-results.txt"

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

$date = Get-Date  -uformat "%A %B %d, %Y"
Log "$date"
$time = Get-Date –f "HH:mm:ss"
Log "Script Start Time: $time"
Log ("{0,-1} {1,-9} {2,-20} {3,-30}" -f "S.No.", "Server", "File Name", "Size")
Log ("{0,-1} {1,-9} {2,-20} {3,-30}" -f "=====", "=========", "=========", "====")
$count = 0
$list = "c:\scripts\ServerList.txt"
$creds = Get-Credential

$ServerList = Get-Content $list

$logFileInfo = { Get-ChildItem -Path "C:\windows\Logs\DPX"}

foreach ($server in $serverlist)
{
	$count = 1
	Log ("{0,-9}" -f "$server")
	#Invoke-Command -ComputerName $server -ScriptBlock $logFileInfo | Select -Property Name, Length
	$info = Invoke-Command -ComputerName $server $creds -ScriptBlock $logFileInfo
	foreach ($inf in $info)
	{
		$name = $inf.Name
		$size = $inf.Length
		Log ("{0,-1} {1,-20} {2,-30}" -f "$count", "$name", "$size")
		$count++
	}
}

$time = Get-Date –f "HH:mm:ss"
Log "Script End Time: $time"
#$info | Export-CSV NICPorts.csv -NoTypeInformation
# END 