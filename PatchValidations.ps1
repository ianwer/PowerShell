########################################################################################################
#Name: PatchValidations.ps1
#
#Author: Joshua Closson (v-joshcl)
#
#Version: v1
#
#Purpose: Verifies MSNPatch version number and if a server is pending reboot.  Input can be a single
#         server or a text file input.
#
#
#Syntax: .\PatchValidations [-ServerList <FileName> | -ServerName <ServerName>]
#
########################################################################################################

Param(
[String] $ServerList,
[String] $ServerName
)

If (($ServerList) -and ($ServerName)){
    "Only server name or server list can be selected, not both."
    }
If ((!$ServerList) -and (!$ServerName)){
    "Please select at least one, server name or server list."
    }
If (($ServerList) -and (!$ServerName)){


    $Servers = GC $ServerList
    ForEach($Server in $Servers){
        #Clear Variables
        $Reg = ""
        $regPatchKey = ""
        $MSNPatchValue = ""
        $regRebootKey = ""
        $regRebootValue = ""
        $Reboot = ""
        
        #Create Results
        $Result = New-Object system.object
        $Result | Add-Member -MemberType NoteProperty -Name "Name" -Value ""
        $Result | Add-Member -MemberType NoteProperty -Name "MSNPatch" -Value ""
        $Result | Add-Member -MemberType NoteProperty -Name "RebootPending" -Value ""
        
        $Ping = Test-Connection $Server -count 1 -ea 0
        If(!$Ping){
            $MSNPatchValue = "PING FAILED"
            $Reboot = "N/A"
            }
        Else{
            $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$Server)
            $regPatchKey = $Reg.OpenSubKey("SOFTWARE\Microsoft\msnipak")
            $MSNPatchValue = $regPatchKey.GetValue("MSNPatch")
            $regRebootKey = $Reg.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager")
            $regRebootValue = $regRebootKey.GetValue("PendingFileRenameOperations")
            If (!$regRebootValue){$Reboot = $FALSE}
            Else{$Reboot = $TRUE}
            }
            
        $Result.Name = $Server
        $Result.MSNPatch = $MSNPatchValue
        $Result.RebootPending = $Reboot
        
        $Result
		Export-Csv -InputObject $Result -path PatchValidation.csv -Append -NoTypeInformation
        }
    }
If ((!$ServerList) -and ($ServerName)){
    $Result = New-Object system.object
    $Result | Add-Member -MemberType NoteProperty -Name "Name" -Value ""
    $Result | Add-Member -MemberType NoteProperty -Name "MSNPatch" -Value ""
    $Result | Add-Member -MemberType NoteProperty -Name "RebootPending" -Value ""

    $Ping = Test-Connection $ServerName -count 1 -ea 0
    If(!$Ping){
        $MSNPatchValue = "PING FAILED"
        $regRebootValue = "N/A"
        }
    Else{
        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$ServerName)
        $regPatchKey = $Reg.OpenSubKey("SOFTWARE\Microsoft\msnipak")
        $MSNPatchValue = $regPatchKey.GetValue("MSNPatch")
        $regRebootKey = $Reg.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager")
        $regRebootValue = $regRebootKey.GetValue("PendingFileRenameOperations")
        If (!$regRebootValue){$Reboot = $FALSE}
        Else{$Reboot = $TRUE}
        }
            
    $Result.Name = $ServerName
    $Result.MSNPatch = $MSNPatchValue
    $Result.RebootPending = $Reboot
    
    $Result
	Export-Csv -InputObject $Result -path PatchValidation.csv -Append -NoTypeInformation
    }