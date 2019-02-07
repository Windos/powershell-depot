$Method = New-UDAuthenticationMethod
$Token = Grant-UDJsonWebToken -UserName 'Pipeline'

$Endpoint = New-UDEndpoint -Url "/toast" -Method "POST" -Endpoint {
    param ($Build, $Branch, $Project, $Status, $Commit, $Owner, $Uri)

    $ShortCommitSha = $Commit.Substring(0,7)
    $Button = New-BTButton -Content 'Open' -Arguments $Uri
    New-BurntToastNotification -Text "Build $Build of $Project $Status", "Source: $ShortCommitSha on branch $Branch", "Triggered by: $Owner"  -AppLogo 'https://avatars2.githubusercontent.com/u/39924718?s=460&v=4' -Button $Button
}
$Api = Start-UDRestApi -AuthenticationMethod $Method -Endpoint $Endpoint -Port 8888

$Body = @{
    Build = 'Random'
    Result = 'Succeeded'
}
Invoke-RestMethod -Headers @{ Authorization = "Bearer $Token" } -Uri http://localhost:80/api/toast -Method POST -Body $Body

Invoke-RestMethod -Uri http://localhost:80/api/toast

$Api | Stop-UDRestApi