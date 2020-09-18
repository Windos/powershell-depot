$WatcherPath = 'D:\MusicBee'
$FileFilter = 'Tags.txt'

$FileSystemWatcher = New-Object -TypeName System.IO.FileSystemWatcher -ArgumentList $WatcherPath, $FileFilter

$Global:LastTitle = ''

Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Changed -Action {

    Start-Sleep 1

    $MusicInfo = Import-Csv 'D:\MusicBee\Tags.txt' -Delimiter "`t" -Header 'Artist', 'Album', 'Year', 'Title'
    $AlbumInfo = '{0} - {1} ({2})' -f $MusicInfo.Artist, $MusicInfo.Album, $MusicInfo.Year

    if ($MusicInfo.Title -and $MusicInfo.Title -ne $Global:LastTitle) {
        $Global:LastTitle = $MusicInfo.Title

        $Header = New-BTText -Text 'Now Playing'
        $Title = New-BTText -Text $MusicInfo.Title
        $Album = New-BTText -Text $AlbumInfo

        $LogoPath = Join-Path -Path (Get-Module BurntToast -ListAvailable)[0].ModuleBase -ChildPath 'Images\BurntToast.png'
        $AppLogo = New-BTImage -Source $LogoPath -AppLogoOverride -Crop Circle

        $ImagePath = 'D:\MusicBee\CoverArtwork.jpg'
        $ToastImage = New-BTImage -Source $ImagePath -RemoveMargin

        $Audio1 = New-BTAudio -Silent

        $Binding1 = New-BTBinding -Children $Header, $Title, $Album, $ToastImage -AppLogoOverride $AppLogo
        $Visual1 = New-BTVisual -BindingGeneric $Binding1
        $Content1 = New-BTContent -Visual $Visual1 -Audio $Audio1 -Duration Long

        Submit-BTNotification -Content $Content1
    }
}