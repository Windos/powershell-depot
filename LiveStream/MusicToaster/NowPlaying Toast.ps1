$WatcherPath = 'D:\MusicBee'
$FileFilter = 'Tags.txt'

$FileSystemWatcher = New-Object -TypeName System.IO.FileSystemWatcher -ArgumentList $WatcherPath, $FileFilter

$Global:LastTitle = ''

Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Changed -Action {

    Start-Sleep 1

    $MusicInfo = Import-Csv 'D:\MusicBee\Tags.txt' -Delimiter "`t" -Header 'Artist', 'Album', 'Year', 'Title'
    $AlbumInfo = '{0} ({1})' -f $MusicInfo.Album, $MusicInfo.Year

    if ($MusicInfo.Title -and $MusicInfo.Title -ne $Global:LastTitle) {
        $Global:LastTitle = $MusicInfo.Title

        $Header = New-BTText -Text 'Now Playing'


        $LogoPath = Join-Path -Path (Get-Module BurntToast -ListAvailable)[0].ModuleBase -ChildPath 'Images\BurntToast.png'
        $AppLogo = New-BTImage -Source $LogoPath -AppLogoOverride -Crop Circle

        $ImagePath = 'D:\MusicBee\CoverArtwork.jpg'
        $ToastImage = New-BTImage -Source $ImagePath -RemoveMargin -Align Right

        $TitleLabel = New-BTText -Text 'Title:' -Style Base
        $AlbumLabel = New-BTText -Text 'Album:' -Style Base
        $ArtistLabel = New-BTText -Text 'Artist:' -Style Base

        $Title = New-BTText -Text $MusicInfo.Title -Style BaseSubtle
        $Album = New-BTText -Text $MusicInfo.Artist -Style BaseSubtle
        $Artist = New-BTText -Text $AlbumInfo -Style BaseSubtle

        $Column1 = New-BtColumn -Children $TitleLabel, $AlbumLabel, $ArtistLabel
        $Column2 = New-BtColumn -Children $Title, $Album, $Artist

        $Audio1 = New-BTAudio -Silent

        $Binding1 = New-BTBinding -Children $Header, $ToastImage -Column $Column1, $Column2 -AppLogoOverride $AppLogo
        $Visual1 = New-BTVisual -BindingGeneric $Binding1
        $Content1 = New-BTContent -Visual $Visual1 -Audio $Audio1 -Duration Long

        Submit-BTNotification -Content $Content1
    }
}