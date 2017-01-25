Import-Module ActiveDirectory

#will old ad-users profilepath and users local profile
#since this seems to be a problem sometimes

#make sure computer is rebooted before running sript
#or local profile will locked, run as domain admin

$user 		= Read-host -prompt 'Username'
$computer	= Read-host -prompt 'Remote computer IP/computername'

if (Test-Connection $computer -quiet) {
	Get-WmiObject -class Win32_OperatingSystem -computer $computer | Select-Object __SERVER,@{label='Senaste boot';expression={$_.ConvertToDateTime($_.LastBootUpTime)}} | select "Senaste boot"
} else {
	echo "Computer offline."
	break #fix it
}
echo ""
$execute = Read-Host -prompt 'Reset profile? (y/n)'

if ($execute -eq "y") {
	$profilePath = (Get-ADUser -Identity $user -Properties profilepath).profilepath
	$profilePath += ".V2" #might be other for you, if so uncomment this, is it windows standard? who knoes.
	$objectSid = (Get-ADUser -Identity $user -Properties objectSid).objectSid.value
	$date = Get-Date -UFormat "%Y%m%d"

	$newpath = $profilePath + "_old_" + $date

	if (Test-Path $profilePath) { #check for central profile on servers
		Rename-Item -path $profilePath -newName $newPath
		echo "Central profile has been renamed -> $newPath"
	} else {
		echo "Central profile not found."
	}

	if (Test-Connection $computer) { #test connection, again.
		$driveLetter = "C"
		$newpath = "\\$computer\$driveLetter$\users\$user" + "_old_" + $date
		$oldPath = "\\$computer\$driveLetter$\users\$user"
		
		if (Test-Path $oldPath) { #remove local userprofile
			Rename-Item -path $oldPath -newName $newpath
			echo "Local profile has been renamed."
			Start-Sleep 2
		} else {
			echo "Local profile not found."
		}
		
		$key = $objectSid #remove user SID/guid in local registry
		reg delete "\\$computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$key" /f
		echo "Removed local user SID/GUID: $key"
		
	} else {
		"Computer offline."
	}

}

else {clear}
