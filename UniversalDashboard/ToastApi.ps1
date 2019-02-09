$Method = New-UDAuthenticationMethod
# $Token = Grant-UDJsonWebToken -UserName 'Pipeline'

$Endpoint = New-UDEndpoint -Url "/toast" -Method "POST" -Endpoint {
    param ($Build, $Branch, $Project, $Status, $Commit, $BuildId)

    switch ($Status) {
        'Succeeded' { $Icon = 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/73/Flat_tick_icon.svg/480px-Flat_tick_icon.svg.png' }
        'Failed' { $Icon = 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Flat_cross_icon.svg/480px-Flat_cross_icon.svg.png' }
        Default { $Icon = 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Icon-round-Question_mark.svg/480px-Icon-round-Question_mark.svg.png' }
    }

    $ShortCommitSha = $Commit.Substring(0,7)
    $Button = New-BTButton -Content 'Open' -Arguments "https://dev.azure.com/windosnz/CrashTest/_build/results?buildId=$BuildId"
    New-BurntToastNotification -Text "$Project $Build - $Status", "Source: $ShortCommitSha", "Branch: $Branch"  -AppLogo $Icon -Button $Button
}
$Api = Start-UDRestApi -AuthenticationMethod $Method -Endpoint $Endpoint -Port 8888

$Body = @{
    Build = 'Random'
    Result = 'Succeeded'
}
Invoke-RestMethod -Headers @{ Authorization = "Bearer $Token" } -Uri http://localhost:8888/api/toast -Method POST -Body $Body

Invoke-RestMethod -Uri http://localhost:80/api/toast

$Api | Stop-UDRestApi