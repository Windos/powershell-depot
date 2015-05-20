# Code signing function
function sign ($file) {
    $cert = (Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)[0]
    Set-AuthenticodeSignature -Certificate $cert -FilePath $file
}

#region WindowTitle
$defaultWindowTitle = $Host.UI.RawUI.WindowTitle
$newWindowTitle = ''

if ($defaultWindowTitle -like "Administrator*") {
    $newWindowTitle = '[Admin] PS' 
} else {
    $newWindowTitle = 'PS' 
}

if ($defaultWindowTitle -like "*ISE") {
    $newWindowTitle += ' ISE'
}

$Host.UI.RawUI.WindowTitle = $newWindowTitle
#endregion

#region Speech
Add-Type -AssemblyName System.Speech
$HAZEL = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
$HAZEL.Rate = 0.1
$voices = $HAZEL.GetInstalledVoices()
$HAZEL.SelectVoice('Microsoft Hazel Desktop')

function Out-Voice {
    param (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   Position = 0)]
        [string] $Message
    )

    process {
        $HAZEL.SpeakAsync($Message) | Out-Null
    }
}

New-Alias -Name Voice -Value Out-Voice
New-Alias -Name V -Value Out-Voice
#endregion

#region Prompt
function prompt {
    $history = @(Get-History)

    if ($history.Count -gt 0) {
        $lastItem = $history[$history.Count -1]
        $lastId = $lastItem.Id
    }

    $nextCommand = $lastID + 1

    $jobs = @(Get-Job -State Running)
    $runningJobs = "`n"

    if ($jobs.Count -gt 0) {
        foreach ($job in $jobs) {
            $ID = $job.Id
            $Name = $job.Name
            $runningJobs += "[$ID : $Name] "
        }
        $runningJobs += "`n"
    }
    $currentDirectory = Get-Location

    "$runningJobs[$nextCommand] PS $currentDirectory> "
}
#endregion

cd \

# SIG # Begin signature block
# MIIIbwYJKoZIhvcNAQcCoIIIYDCCCFwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGWD7sdy2U8fpl01QcgCivNco
# DaegggXLMIIFxzCCBK+gAwIBAgITPwAAAAT2gQLTABzu8QAAAAAABDANBgkqhkiG
# 9w0BAQUFADBWMRIwEAYKCZImiZPyLGQBGRYCbnoxFDASBgoJkiaJk/IsZAEZFgRn
# ZWVrMRQwEgYKCZImiZPyLGQBGRYEa2luZzEUMBIGA1UEAxMLa2luZy1DQTEtQ0Ew
# HhcNMTUwNTE4MDkxMDU5WhcNMTYwNTE3MDkxMDU5WjCBkDESMBAGCgmSJomT8ixk
# ARkWAm56MRQwEgYKCZImiZPyLGQBGRYEZ2VlazEUMBIGCgmSJomT8ixkARkWBGtp
# bmcxEDAOBgNVBAsTB2tpbmdkb20xDjAMBgNVBAsTBXVzZXJzMQ4wDAYDVQQLEwVh
# ZG1pbjEcMBoGA1UEAxMTSm9zaHVhIEtpbmcgKEFkbWluKTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALK8p7BW6P1Yd6zDkucJPyQ0O03iUg5GEZ8rPLU8
# n+O4Li66twPTt0VvhPJBdP1KN1iWdm7n4PsNjDOsi3EzatH2ZekvdgsTVhG206JI
# /Kaf7kqmEYkOKUcoZCN4Z2Scgye08Opp68oGaL5r4CfFi7Kthm/0y6kP//YQxPbh
# 0Qa7lqe5EFWjbRhLpKvL7M1zCGiAqliffzd+ZtFbm7BGKudaurNDawAxMr7sw7EB
# B1NcpOmZwDEoowhxMZ70LFq+aiIHXf8DZUpp8nng5TIgcxjFLChW7cSg7SoiGHvE
# otTo3Wc2fUYTMtwBmoTlJRuao/1ocJ221H1cWyELgfkPhTkCAwEAAaOCAlEwggJN
# MCUGCSsGAQQBgjcUAgQYHhYAQwBvAGQAZQBTAGkAZwBuAGkAbgBnMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMA4GA1UdDwEB/wQEAwIHgDAdBgNVHQ4EFgQU/W2WN8M8RYS7
# +4F0ko+Y18cQwAUwLwYDVR0RBCgwJqAkBgorBgEEAYI3FAIDoBYMFGFkbWluamtA
# a2luZy5nZWVrLm56MB8GA1UdIwQYMBaAFAbq+e7Ik0l+6BF9PUzpTi52vlvIMIHJ
# BgNVHR8EgcEwgb4wgbuggbiggbWGgbJsZGFwOi8vL0NOPWtpbmctQ0ExLUNBLENO
# PUNBMSxDTj1DRFAsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2Vydmlj
# ZXMsQ049Q29uZmlndXJhdGlvbixEQz1raW5nLERDPWdlZWssREM9bno/Y2VydGlm
# aWNhdGVSZXZvY2F0aW9uTGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1
# dGlvblBvaW50MIHBBggrBgEFBQcBAQSBtDCBsTCBrgYIKwYBBQUHMAKGgaFsZGFw
# Oi8vL0NOPWtpbmctQ0ExLUNBLENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2
# aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPWtpbmcsREM9Z2Vl
# ayxEQz1uej9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0Q2xhc3M9Y2VydGlmaWNh
# dGlvbkF1dGhvcml0eTANBgkqhkiG9w0BAQUFAAOCAQEAHGzkUC+EmqQuVrujlUMU
# Madab1XtBdWLhIoQAJH91iaAmi/+b+52nxqLZF5pwdcBx5eg8XcsXsODq2TCnVIa
# eY7+U/t9QQZsf3MqUCh/wYGp9m58lpcJLJMmZgKzhmtRUaNDboBE/Wfn8BCGaTcv
# pE0ckiFxyGriK/5l2+kyduTcWtTvPhr/i50HXoDn60iYPK3ktusQTT3VP226dtN4
# VbdORM4LAh/LcK2tcEWf2GlXC0nSHFb7TDmAQ917VCTmXt+40EiFhkhd1H3fHpPx
# 4qC4HpLkVKijUx1K5HxybzGzxjOugo7wlUtd0B/IA6mQkM1GhW8LtSyjq0f4wssc
# sDGCAg4wggIKAgEBMG0wVjESMBAGCgmSJomT8ixkARkWAm56MRQwEgYKCZImiZPy
# LGQBGRYEZ2VlazEUMBIGCgmSJomT8ixkARkWBGtpbmcxFDASBgNVBAMTC2tpbmct
# Q0ExLUNBAhM/AAAABPaBAtMAHO7xAAAAAAAEMAkGBSsOAwIaBQCgeDAYBgorBgEE
# AYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSlHn2Y
# rmEt7ECvqiIEtt3a1YcgDzANBgkqhkiG9w0BAQEFAASCAQA1Sd/shLeD/qKTWcSN
# fS4o3O4m3abr4t4bEPT2vkATnj6+m0+mIz1Gn6x4hDCWckqqWv/REqyG+YzHzIL+
# MKJuYby3TalDeixKWyavPEY3v6YwTJWpqjd93fySXBqAq6oYZfLqrsSepPI7xmSG
# /rVASaGTMCo3ynnzSOpmjqK1EEUJAlNb8SuRpgiV69LQnH37iJHwI4lW53Zbhrsz
# 4ZANevsoutL1dXfA2rGAF0lxikTXimO2UKYXt6QwexVqbbPFuzWv3l5g/JOXq5ig
# OfBBonasaPasN50dbwPqPtBHTwwpN46zbO0+LQ8iPuO4C4SHW5pkXiNLZDNmmpEV
# 0Dby
# SIG # End signature block
