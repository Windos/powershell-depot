<#PSScriptInfo

.VERSION 0.1

.GUID 2b02b3ba-b43d-431b-901d-37b919005685

.AUTHOR Joshua (Windos) King

.COMPANYNAME king.geek.nz

.COPYRIGHT (c) 2015 Joshua (Windos) King. All rights reserved.

.TAGS Twitter tweet social blog

.LICENSEURI https://github.com/Windos/powershell-depot/blob/master/LICENSE.md

.PROJECTURI https://github.com/Windos/powershell-depot/blob/master/GalleryScripts/Send-BlogTweet.ps1

.RELEASENOTES
* Initial release

#>

#Requires -Module PoshTwit

<#

.DESCRIPTION
Send-BlogTweet chooses a random post from a blog's RSS feed and sends a Tweet, using PoshTwit, linking to the post.

#>
param (
    [string] $BlogFeed = 'https://king.geek.nz/rss/',
    [string] $TokenPath = 'C:\Program Files\WindowsPowerShell\Modules\PoshTwit\0.1.6\token.json'
)

$Posts = [System.Collections.ArrayList]::new()
$PageNumber = 1
$More = $true

while ($More) {
    try {
        $Page = Invoke-RestMethod -Uri "$BlogFeed$PageNumber" -ErrorAction Stop
    } catch {
        $Page = $null
    }

    if ($Page.Count -gt 0) {
        foreach ($Post in $Page) {
            $null = $Posts.Add($Post)
        }

        $PageNumber += 1
    } else {
        $More = $false
    }
}

$PostToPost = $Posts | Get-Random

$Title = $PostToPost.title.'#cdata-section'
$Excerpt = $PostToPost.description.'#cdata-section'
$Link = $PostToPost.link
$Categories = $PostToPost.category | foreach {$_.'#cdata-section'.replace(' ', '')}

$Hashtags = ''
foreach ($Category in $Categories) {
    $Hashtags += " #$Category"
}

$TweetText = "From the blog archive: ""$Title""`n`n$Excerpt$Hashtags`n$link"

$Token = Get-Content -Path $TokenPath | ConvertFrom-Json

$ParamSplat = @{
    Tweet          = $TweetText
    ConsumerKey    = $Token.ConsumerKey
    ConsumerSecret = $Token.ConsumerSecret
    AccessToken    = $Token.AccessToken
    AccessSecret   = $Token.AccessSecret
}

Publish-Tweet @ParamSplat
