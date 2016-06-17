$ScriptBlock = {
    $URL = 'http://localhost:32400/status/sessions'
    
    while ($true)
    {
        $PlexStatus = Invoke-RestMethod -Uri $URL
    
        if ($PlexStatus.MediaContainer.Size -eq 0)
        {
            Stop-Computer
        }
    
        Start-Sleep -Seconds 900
    }
}

$JobTrigger = New-JobTrigger -Daily -At '8:30 PM'
$JobOption = New-ScheduledJobOption -RunElevated
Register-ScheduledJob -Name 'PlexShutdown' -Trigger $JobTrigger -ScheduledJobOption $JobOption -ScriptBlock $ScriptBlock
