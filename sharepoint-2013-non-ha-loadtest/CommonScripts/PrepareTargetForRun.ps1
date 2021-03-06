param(
	[parameter(Mandatory = $true)]
	[String]$ServiceUserName
)

# Install the log to file module
$currentPath = Convert-Path .
$PSModulePath = "$($env:ProgramFiles)\WindowsPowerShell\Modules"
$LogToFileFolderName = "LogToFile"
$LogToFileFolderPath = Join-Path $PSModulePath $LogToFileFolderName
if(-not(Test-Path $LogToFileFolderPath))
{
	New-Item -Path $LogToFileFolderPath -ItemType directory
	$moduleFileName = "LogToFile.psm1"
	$moduleFilePath = Join-Path $currentPath $moduleFileName
	Copy-Item $moduleFilePath $LogToFileFolderPath
}

#Import modules
Import-Module LogToFile
Import-Module NetSecurity 

# Create the log file
CreateLogFile

# Adding test controller service user to local admins
LogToFile -Message "Adding domain user $($ServiceUserName) to the local administrators group"
$Domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
$group = [ADSI]"WinNT://localhost/Administrators,group"
$members = $group.psbase.Invoke("Members")
if(($members | ForEach-Object {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}) -notcontains $ServiceUserName)
{
	$group.psbase.Invoke("Add",([ADSI]"WinNT://$Domain/$ServiceUserName").path)
}
LogToFile -Message "Done adding domain user $($ServiceUserName) to the local administrators group"

# Enabling fire wall rules for performance counter capture
LogToFile -Message "Enabling fire wall rules for remote performance counter capture"
Enable-NetFirewallRule –Group "@FirewallAPI.dll,-34752"
LogToFile -Message "Done enabling fire wall rules for remote performance counter capture"