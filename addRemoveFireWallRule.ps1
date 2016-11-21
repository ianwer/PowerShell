# The script is designed to collect specific file information from all servers in the server list
# Commerce
# Date Modified: 7/29/2015
# For any assistance "v-ianwer@microsoft.com"
#

$list = "List.txt"

$ServerList = Get-Content $list

$ApplyFWRule = { netsh advfirewall firewall add rule name="Simpana_IN" dir=in action=allow protocol=tcp localport=8400-8404;
netsh advfirewall firewall add rule name="Simpana_OUT" dir=out action=allow protocol=tcp localport=8400-8404;
netsh advfirewall firewall add rule name="Simpana135_IN" dir=in action=allow protocol=tcp localport=135;
netsh advfirewall firewall add rule name="Simpana135_OUT" dir=out action=allow protocol=tcp localport=135;
netsh advfirewall firewall add rule name="Simpana445_IN" dir=in action=allow protocol=tcp localport=445;
netsh advfirewall firewall add rule name="Simpana445_OUT" dir=out action=allow protocol=tcp localport=445 }

foreach ($server in $serverlist)
{
	Invoke-Command -ComputerName $server -ScriptBlock $ApplyFWRule
}
