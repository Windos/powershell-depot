# Configure proxy authentications
(New-Object System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

# Code signing function
function sign ($filename) {
    $cert = @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)[0]
    Set-AuthenticodeSignature $filename $cert
}

# Custom prompt with history marker
function prompt {
    $history = @(get-history)

    if($history.Count -gt 0) {
        $lastItem = $history[$history.Count - 1]
        $lastId = $lastItem.Id
    }

    $nextCommand = $lastId + 1

    $jobs = @(Get-Job -State Running)
	$runningjobs = "`n"

    if($jobs.Count -gt 0) {
	    foreach ($job in $jobs) {
		    $ID = $job.Id
			$name = $job.Name
		    $runningjobs += "[$ID : $Name] "
		}
		$runningjobs += "`n"
	}

	$currentDirectory = get-location

	"$runningjobs[$nextCommand] PS $currentDirectory> "
}

$PersonalModules = Join-Path -Path (Split-Path -Parent $profile) -ChildPath Modules
$env:PSModulePath = $env:PSModulePath + ";$PersonalModules"

#region WindowTitle
$defaultHostUiWindowTitle = $host.UI.RawUI.WindowTitle

if ($defaultHostUiWindowTitle -like "Administrator*") {
    $defaultHostUiWindowTitle = $defaultHostUiWindowTitle.replace('Administrator: ','[Admin]')
}

$defaultHostUiWindowTitle = $defaultHostUiWindowTitle.replace('Windows PowerShell','PS')
$host.UI.RawUI.WindowTitle = "[$($env:USERNAME)]$defaultHostUiWindowTitle"
#endregion

#region Scripts
$scriptPath = Join-Path (Split-Path $profile) '\scripts\'

. "$scriptPath\Get-ViewUser.ps1"

cd \

# PSReadLine
if ($host.Name -eq 'ConsoleHost')
{
    Import-Module PSReadLine
}
