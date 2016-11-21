# Script to rename computers in a domain by parsing a CSV file 
# Assumes: File of names with a header row of OldName,NewName
# and a row for oldname,newname pairs for each computer to be renamed.
# Adjust filename and file path as appropriate. 

$getcreds = Get-Credential -Credential prod\v-ianwer_2897501
$usr = $getcreds.UserName
$pwd = $getcreds.GetNetworkCredential().password  
$csvfile = "renameServers.csv"
Import-Csv $csvfile | foreach { 
$oldName = $_.OldName;
$newName = $_.NewName;
  
Write-Host "Renaming computer from: $oldName to: $newName"
netdom renamecomputer $oldName /newName:$newName /uD:$usr /passwordD:$pwd /force /reboot
}