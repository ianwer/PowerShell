# This utility will configure MHS, OBE and NDR Roles in Exchange Test & Other Environments
# FOPE_Test_NOC
# Date Modified: 11/16/2010
# For any assistance "v-ianwer@microsoft.com"

Get-PSSnapin -Registered | Add-PSSnapin -ErrorAction SilentlyContinue
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

function GetIPs()
{ 
	$IPconfigset = Get-WmiObject Win32_NetworkAdapterConfiguration  
	$ips = @()

	foreach ($IPConfig in $IPConfigSet)
  	{  
    	if ($Ipconfig.IPaddress -and $IPCOnfig.IPENabled -eq $True )
        {  
            foreach ($addr in $Ipconfig.Ipaddress)
            {
                if( $addr -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" ) { $ips += $addr }
            }  
        }  
  	}
  	return $ips[0]
}

function SearchForEvent( $eventID )
{
$i=0
if( $array.Count -gt 0 )
{
    foreach ( $evt in $array )
    {
        if( $evt.eventID -eq $eventID )
        {
            $i++
            Log $evt.Index $evt.TimeGenerated $evt.EntryType $evt.Source $evt.InstanceId $evt.Message
        }
    }
}
Log "`n  Total Events Found : " $i
return $i;
}

function RepTime( [DateTime]$wt, [ref]$diff  )
{
  	$fifteen = New-Object System.TimeSpan 0,0,$nMinutes,0,0
  	$diff.value = $now - $wt;
  
  	if( $diff.value -le $fifteen ) { return $true; }
  	return $false;
}

function checkPath( [String]$p, [bool]$required )
{ 
    $AllFiles = @()
    $AllFiles = Get-ChildItem -path $p -recurse -include *.sdf
    #write-host "  $AllFiles "
    if (( $required -eq $true) -and ($AllFiles.length -le 0 )) 
    {
        if ($p -eq "C:\Program Files\Exchange Hosted Services\CustomerRelayAgent\data\SQLCE")
        {
            copy C:\volumes\data\dfsr\core\*.sdf C:\Program Files\Exchange Hosted Services\CustomerRelayAgent\data\SQLCE
        }
        else
        {
             write-host "`n  Failed to find files in" $p -foregroundcolor "red"
             Log "Failed to find files in $p"
             exit 1
        }
    }
    return $AllFiles
    $DirAll = $AllFiles
}

function GetDBItem([string]$SqlQuery)
{
    $SQLDBName = "DeploymentDB"
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server=$SQLServer;Database=$SQLDBName;Integrated Security=True"
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $SqlQuery
    $SqlCmd.Connection = $SqlConnection
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $dset = $SqlAdapter.Fill($DataSet)
    $SqlConnection.Close()
    return $DataSet.Tables[0].Rows[0][0]
}

function GetQueuevalues()
{
    $ret = $false
    [Array]$gq = Get-Queue
    foreach ($gqi in $gq)
    {
        if ($gqi.MessageCount -ne 0) 
        {	 
            $gqi
            $ret = $true
        }
    }
    return $ret
}

$error_string = ""
$ipProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
$fulcompname = "{0}.{1}" -f $ipProperties.HostName, $ipProperties.DomainName
$usr = [Environment]::UserName
$env = $ipProperties.DomainName
$smtpserverip = GetIPs
$servername = hostname
$sender = "admin@$fulcompname"
$recipient = "$usr@microsoft.com"
$loggedinuser = [Environment]::UserName
$intdnsiptest = $args[0]
$timendate = Get-Date
$foundURL = $false
Log "  *** Starting Configurations on $servername *** "
switch ($env.ToUpper() )
{
    "PERPETUALBETA.COM" 
    { 
        $SQLServer = "10.10.80.9" 
        $foundURL = $true
        break
    }
    "PREVIEWDF.COM" 
    { 
        $SQLServer = "10.10.200.6"  
        $foundURL = $true
        break
    }
    "STAGING.LOCAL"
    { 
        $SQLServer = "192.168.210.24" 
        $foundURL = $true
        break
    }
    "SHWCPG-DOM.EXTEST.MICROSOFT.COM"
    { 
        $SQLServer = "10.193.90.13" 
        $foundURL = $true
        break
    }
     "EHS.LOCAL"
    {
        $SQLServer = "10.210.100.00"
        $foundURL = $true
        break
    }
    default 
    {
        Log "  Did not find SQL Server IP, Continue with the static value "
    }
}

if( $foundURL -eq $true )
{
    $serverrole = GetDBItem "SELECT Name from roles, machines where machines.hostName = '$servername' and machines.serverRole = roles.Id"
    $linuxdnsserver = GetDBItem "SELECT staticIP from machines where (serverRole = '4' or serverRole = '44') and (osType = '1' or osType = '16' )"  
}

if (($serverrole.ToUpper() -eq "WIN_OUTBOUNDEDGE") -and ($serverrole.ToUpper() -eq "WIN_OUTBOUNDNDR"))
{
#  *** Verify Event Log *** "
    Log "`n  *** Verifying Event Log *** "
    $num += SearchForEvent( 7 )
    if( $num -eq 0 )
    {
        write-host "  Did not find any event for Event id 7 " -foregroundcolor "green"
        Log "  Did not find any event for Event id 7 "
    }
    else
    {
        write-host "  Check the Event Log and if fixed run it again to verify " -foregroundcolor "red"
        Log "  Check the Event Log and if fixed run it again to verify "
    }
    $num += SearchForEvent( 8 )
    if( $num -eq 0 )
    {
        write-host "  Did not find any event for Event id 8 " -foregroundcolor "green"
        Log "  Did not find any event for Event id 8 " -foregroundcolor "green"
    }
    else
    {
        write-host "  Check the Event Log and if fixed run it again to verify " -foregroundcolor "red"
        Log "  Check the Event Log and if fixed run it again to verify " 
        Exit 1     
    }
}
#  *** Verify Replication *** "
if (($serverrole.ToUpper() -eq "WINDOWS_MESSAGE_SWITCH"))
{
    Log "`n  *** Verifying Replication  *** "
    $nMinutes = 20
    $now = [DateTime]::Now
    $myfiles = @()
    if ($env -eq "SHWCPG-DOM.EXTEST.MICROSOFT.COM") 
    { 
        $myfiles += checkPath "C:\dfsr\core" $true 
    }
    else 
    { 
    $myfiles += checkPath "C:\volumes\data\dfsr\core" $true 
    }

    $myfiles += checkPath "C:\Program Files\Exchange Hosted Services\CustomerRelayAgent\data\SQLCE" $true

    Log "CHECKING FOR REPLICATION WITHIN $nMinutes MINUTES"     

    $notUpdated = 0
    foreach( $item in $myfiles )
    {
        $file = Get-Childitem ($item)
        $diff = ""
        $result = RepTime $file.LastWriteTime ([ref]$diff) 
        Log "`n  File:  $item" 
        Log "  No update for :  $diff"
        if ($result -eq $false )
        {
            $notUpdated++
            write-host "`n  *** WARNING : No Replication  *** " -foregroundcolor "red"      
            Log "`n  *** WARNING : No Replication  *** "
        }
    }
    write-host "`n  Files not update : " $notUpdated "`n"
    if ($env -eq "SHWCPG-DOM.EXTEST.MICROSOFT.COM")
    {
        write-host "`n  Diretory of C:\dfsr\AntiSpam "
        Get-ChildItem C:\dfsr\AntiSpam 
        $items = Get-ChildItem C:\dfsr\AntiSpam
        if ($items -eq $True)
        {
            for( $i=0; $i -lt $items.length; $i++ )
            {
                $text = "{0, 1} {1, 5} {2, 8}" -f $items[$i].LastWriteTime, $items[$i].Length, $items[$i].name
                Log1 $text
            } 
        }
    }
    write-host "`n  Diretory of C:\dfsr\core "
    Get-ChildItem C:\dfsr\core
    $items = Get-ChildItem C:\dfsr\core
    if ($items -eq $True)
    {
    for( $i=0; $i -lt $items.length; $i++ )
        {
            $text = "{0, 1} {1, 5} {2, 8}" -f $items[$i].LastWriteTime, $items[$i].Length, $items[$i].name
            Log1 $text
        }
    } 
    else 
    {
        write-host "`n  Diretory of C:\volumes\data\dfsr\AntiSpam "
        Get-ChildItem C:\volumes\data\dfsr\AntiSpam
        $items = Get-ChildItem C:\volumes\data\dfsr\AntiSpam
        if ($items -eq $True)
        {
            for( $i=0; $i -lt $items.length; $i++ )
            {
                $text = "{0, 1} {1, 5} {2, 8}" -f $items[$i].LastWriteTime, $items[$i].Length, $items[$i].name
                Log1 $text
            }    
        }
    }

    write-host "`n  Diretory of C:\volumes\data\dfsr\core"
    Get-ChildItem C:\volumes\data\dfsr\core
    $items = Get-ChildItem C:\volumes\data\dfsr\core
    if ($items -eq $True)
    {
        for( $i=0; $i -lt $items.length; $i++ )
        {
            $text = "{0, 1} {1, 5} {2, 8}" -f $items[$i].LastWriteTime, $items[$i].Length, $items[$i].name
            Log1 $text
        } 
    }
    write-host "`n  Diretory of C:\Program Files\Exchange Hosted Services\CustomerRelayAgent\data\SQLCE"
    Get-ChildItem "C:\Program Files\Exchange Hosted Services\CustomerRelayAgent\data\SQLCE"
    $items = Get-ChildItem "C:\Program Files\Exchange Hosted Services\CustomerRelayAgent\data\SQLCE"
    if ($items -eq $True)
    {
        for( $i=0; $i -lt $items.length; $i++ )
        {
            $text = "{0, 1} {1, 5} {2, 8}" -f $items[$i].LastWriteTime, $items[$i].Length, $items[$i].name
            Log1 $text
        }
    }
    
}

#  *** Verify Trsport Server *** "
Log "`n  *** Verifying Trsport Server  *** "

$obj = Get-TransportServer

if ( $obj.ExternalDNSAdapterEnabled -ne $True )  
{ 
    Get-TransportServer | Set-TransportServer -ExternalDNSAdapterEnabled $True
} 
else 
{
    $value1 = $obj.ExternalDNSAdapterEnabled.ToString()
    Log "`n  ExternalDNSAdapterEnabled  :  $value1"
}


if ( $obj.InternalDNSAdapterEnabled -ne $False ) 

{
    Get-TransportServer | Set-TransportServer -InternalDNSAdapterEnabled $False 
} 
else 
{
    $value2 =  $obj.InternalDNSAdapterEnabled.ToString() 
    Log "`n  InternalDNSAdapterEnabled  :  $value2"
}

$foundURL = $false
switch ($env.ToUpper() )
{
    "PERPETUALBETA.COM" 
    { 
        $actval = "10.10.80.98" 
        $foundURL = $true
        break
    }
    "PREVIEWDF.COM" 
    { 
        $actval = "10.10.200.40"  
        $foundURL = $true
        break
    }
    "STAGING.LOCAL"
    { 
        $actval = "192.168.210.25" 
        $foundURL = $true
        break
    }
    "SHWCPG-DOM.EXTEST.MICROSOFT.COM"
    { 
        $actval = "10.193.90.134" 
        $foundURL = $true
        break
    }
     "EHS.LOCAL"
    {
        $actval = "10.210.100.88"
        $foundURL = $true
        break
    }
    default 
    {
        Log "  Did not find Linux DNS Server IP, Continue with the existing value "
    }
}

if( $foundURL -eq $true )
{
   $actidsval = $actval
}

$intdnsip = $linuxdnsserver
$file = resolve-path("C:\Program Files\Microsoft Online\Messaging\Config\global.config")
[System.Xml.XmlDocument] $xml = new-object System.Xml.XmlDocument
$xml.load($file)
$node = $xml.SelectSingleNode("configuration/appSettings/add[@key='DatacenterDNSIPAddress']").value

if (($exidsval -ne $node) -and ($node -ne $actval))
{
    Get-TransportServer | Set-TransportServer -InternalDNSServers $actval
    if ($node -eq $actval)
    {
        Get-TransportServer | Set-TransportServer -InternalDNSServers $node
    } 
}
else
{
#   write-host "  InternalDNSServers         : " $obj.InternalDNSServers
   $value3 = $obj.InternalDNSServers.ToString()
   Log "`n  InternalDNSServers         :  $value3"
   write-host "`n  *** Values are correct ***  " -foregroundcolor "green"
   Log1 "`n  *** Values are correct ***  "
}
   
#Get-TransportServer | fl *dns*
#  *** Verify exchange transport service *** "
Log "`n  *** Verifying exchange transport service! *** "

$srvchk = Get-Service MSExchangeTransport
if ($srvchk.status -eq "Running")
{
    Get-Service MSExchangeTransport | select displayname, status
    write-host "`n  MSExchangeTRansport Service is running " -foregroundcolor "green"
    Log1 "`n  MSExchangeTRansport Service is running "
}
else
{ 
    write-host "  MSExchangeTRansport Service is not running, please check" -foregroundcolor "red" 
    Log1 "  MSExchangeTRansport Service is not running, please check"
}
if (($serverrole.ToUpper() -eq "WINDOWS_MESSAGE_SWITCH"))
{
    #  *** Verify Send Connectors *** "
    Log "`n  *** Verifying Send Connectors *** "
    $scdata = Get-SendConnector
    if ($scdata.Enabled -eq "True") 
    { 
        write-host "`n  Send Connector is ENABLED " -foregroundcolor "green" 
        Log1 "`n  Send Connector is ENABLED "
    }
    else 
    { 
        write-host "`n  Send Connector is not enabled, please check " -foregroundcolor "red" 
        Log1 "`n  Send Connector is not enabled, please check "
    }
    #  *** Verify Receive Connectors *** "
    Log "`n  *** Verifying Receive Connectors *** "
    $rcdata = Get-ReceiveConnector
    if (($rcdata[0].Enabled -eq "True") -and ($rcdata[1].Enabled -eq "True"))
    { 
    write-host "`n  Both Receive Connectors are ENABLED " -foregroundcolor "green" 
    Log1 "`n  Both Receive Connectors are ENABLED "
    }
    else 
    { 
        write-host "`n  Receive Connectors are not enabled, please check " -foregroundcolor "red" 
        Log1 "`n  Receive Connectors are not enabled, please check "
    }
    #  *** Verify Exchange Certificates *** "
    Log "`n  *** Verifying Exchange Certificates *** "
    $certs = Get-ExchangeCertificate
    foreach ($cert in $certs) 
    {
        $cstatus = $cert.Status
        if (( $cert.Status -eq "Valid" ) -and ( $cert.NotAfter -gt $now ))
        {
            write-host "`n  Certificate " $cert.CertificateDomains " is: " $cert.Status  -foregroundcolor "green"
            $cdomains = $cert.CertificateDomains.ToString()
            Log1 "`n  Certificate  $cdomains  is:  $cstatus"
            Log "`n  is not valide please check the status"
        }
        else
        {
            write-host "`n  Certificate "$cert.CertificateDomains" is: " $cert.Status  -foregroundcolor "red"
            $cdomains = $cert.CertificateDomains.ToString()
            Log1 "`n  Certificate  $cdomains  is:  $cstatus"
            Log "  *** Certificate is valid *** "
        }
    }
}
#  *** Verify Transport Agent *** "
Log "`n  *** Verifying Transport Agent  *** "
$valids = Get-TransportAgent
foreach ($valid in $valids) 
{
    if ($valid.IsValid -eq "True")
    {
        write-host "`n"  $valid.Identity " Enabled valued is:" $valid.Isvalid -foregroundcolor "green"
        $videntity = $valid.Identity.ToString()
        $visvalid = $valid.Isvalid.ToString()
        Log1 "`n  $videntity  Enabled valued is: $visvalid"
    }
    else
    {
        Get-TransportAgent * | fl
    }
}
#  *** Verify Queue *** "
Log "`n  *** Verifying Queue  *** "
$val = GetQueuevalues
if( $val -eq $true )
{
    $val[0]	
}
else
{
    #Get-Queue
    $qitems = Get-Queue 
    foreach ($components in $qitems )
    {
       $id = $components.Identity.Server.ToString()
       $dt = $components.DeliveryType.ToString()
       $st = $components.Status.ToString()
       $mc = $components.MessageCount.ToString()
       $nh = $components.NextHopDomain.ToString() 
       Log1 "`n  $id,  $dt,  $st,  $mc,  $nh"
       write-host "`n " $components.Identity.Server "has status" $components.Status "and there are" $components.MessageCount "in " $components.NextHopDomain
    }
}

#  *** Verify mail flow *** "
Log "`n  *** Verifying mail flow  *** "
if ( $loggedinuser.ToUpper() -eq "ADMINISTRATOR")
{
    write-host "`n  Since you are logged in as" $loggedinuser
    write-host -NoNewline "`n  Please enter e-mail address to send status mail:  "
    $line = $HOST.UI.ReadLine()
    $usr = $line
    $recipient = "$usr"
}
else
{
    $usr = $loggedinuser
    $recipient = "$usr@microsoft.com"
}
$GetText = Get-Content Config-results.txt
for ($i = 0; $i -lt $GetText.length; $i++)
{
    $GetText[$i] += "`n"
}
Send-MailMessage -to $recipient -from $sender -subject "Mail Flow Validation" -Body "$GetText" -SmtpServer $smtpserverip -ev errorout -ErrorAction silentlycontinue
if ($errorout) 
{
    write-host "`n  Fail to send mail" -foregroundcolor "red"
    Log1 "`n  Fail to send mail"
    $error_string += $fullcompname + "`n  Error - " + $errorout + "`n" 
}
else
{
    $val = GetQueuevalues
    Log "`n  Mail From   :  $sender"
    Log "  Mail to     :  $recipient"
    Log "  Subject     :  Mail Flow Validation"
    Log "  SMTP Server :  $smtpserverip"
    if( $val -eq $true ) 
    { 
        write-host "`n  ! Mail has been sent and it is the Queue " -foregroundcolor "yellow" 
        Log1 "`n  ! Mail has been sent and it is the Queue "
    } 
    else 
    { 
        write-host "`n  *** Mail has been sent ***" -foregroundcolor "green" 
        Log1 "`n  *** Mail has been sent ***"
    }
}
Log "`n $error_string"
Log "`n  *** Process completed! please put server back into rotation *** "
