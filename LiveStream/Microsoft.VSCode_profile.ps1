function prompt {
    $CurrentLocation = (Get-Location).Path
    $SplitLocation = $CurrentLocation.Split('\').where({$_ -ne ''})

    if ($SplitLocation.Count -le 2) {
        $PrintLocation = $CurrentLocation
    } else {
        $PrintLocation = $SplitLocation[0]

        for ($x = 0; $x -lt ($SplitLocation.Count - 2); $x++) {
            $PrintLocation += '\.'
        }

        $PrintLocation += '\{0}' -f $SplitLocation[-1]
    }

    "PS $PrintLocation> "
}

#region Music Ticker
$Folder = 'C:\Users\Windos\AppData\Roaming\foobar2000'
$File = 'now-playing.txt'

$Watcher = [IO.FileSystemWatcher]::new()
$Watcher.Path = $Folder
$Watcher.Filter = $File
$Watcher.IncludeSubdirectories = $false
$Watcher.NotifyFilter = [IO.NotifyFilters]'LastWrite'

$WatcherAction = {
    $DefaultTitle = '${dirty}${activeEditorShort}${separator}${rootName} - VSCode'

    $CodeSettings = Get-Content -Path "$Env:APPDATA\Code\User\settings.json" | ConvertFrom-Json
    $NowPlaying = Get-Content -Path $Folder\$File

    if ($NowPlaying.Length -gt 0) {
        $CodeSettings.'window.title' = "$DefaultTitle - Music: $NowPlaying"
    } else {
        $CodeSettings.'window.title' = $DefaultTitle
    }

    ConvertTo-Json -InputObject $CodeSettings | Set-Content -Path "$Env:APPDATA\Code\User\settings.json"
}

$WatcherEvent = Register-ObjectEvent -InputObject $Watcher -EventName Changed -SourceIdentifier FileChanged -Action $WatcherAction
#endregion
