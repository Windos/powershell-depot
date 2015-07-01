function Add-ScheduledStream
{
    <#
        .SYNOPSIS
        Short Description
        .DESCRIPTION
        Detailed Description
        .EXAMPLE
        Add-ScheduledStream
        explains how to use the command
        can be multiple lines
        .EXAMPLE
        Add-ScheduledStream
        another example
        can have as many examples as you like
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$false,
            Position = 0)]
        [string] $Title = 'PowerBot, LCTV Bot in #PowerShell',

        [Parameter(Mandatory=$true,
            Position = 2)]
        [string[]] $Date = '2015-07-06',
        
        [Parameter(Mandatory=$false)]
        [string] $Difficuilty = 'beginner',
        
        [Parameter(Mandatory=$false)]
        [string] $Music = 'Game OSTs',
        
        [Parameter(Mandatory=$false)]
        [string] $Time = '10:00 (10:00 AM)',

        [Parameter(Mandatory=$false)]
        [OpenQA.Selenium.Chrome.ChromeDriver] $Browser
    )
    
    if (!$Browser)
    {
        $Path = 'C:\References\'
        
        Add-Type -Path (Join-Path -Path $Path -ChildPath '\Selenium\Selenium.WebDriverBackedSelenium.dll')
        Add-Type -Path (Join-Path -Path $Path -ChildPath '\Selenium\ThoughtWorks.Selenium.Core.dll')
        Add-Type -Path (Join-Path -Path $Path -ChildPath '\Selenium\WebDriver.dll')
        Add-Type -Path (Join-Path -Path $Path -ChildPath '\Selenium\WebDriver.Support.dll')
        
        #$Browser = New-Object -TypeName OpenQA.Selenium.Chrome.ChromeDriver -ArgumentList @(,(Join-Path -Path $Path -ChildPath '\Chrome\'))
        $Browser = New-Object -TypeName OpenQA.Selenium.Chrome.ChromeDriver -ArgumentList @(,'C:\Program Files (x86)\Google\Chrome\Application\')
        
        $Browser.Navigate().GoToUrl('https://www.livecoding.tv/accounts/login/')
        Start-Sleep -Seconds 90
    }
        
    $Browser.Navigate().GoToUrl('https://www.livecoding.tv/schedule/')
    Start-Sleep -Seconds 1
    
    foreach ($StreamDate in $Date)
    {
        $AddStreamButton = $Browser.FindElementById('add-times')
        $AddStreamButton.Click()
        
        Start-Sleep -Seconds 1
        $TitleTextBox = $Browser.FindElementById('id_title')
        $TitleTextBox.SendKeys($Title)
        
        
        $DifficuiltyDropDown = $Browser.FindElementById('s2id_id_coding_difficulty')
        $DifficuiltyDropDown.Click()
        
        $SelectedDifficuilty = $Browser.FindElementsByClassName('select2-result-label') | Where-Object {$_.Text -eq $Difficuilty}
        $SelectedDifficuilty.Click()
        
        $MusicTextBox = $Browser.FindElementsById('id_music')
        $MusicTextBox.SendKeys($Music)
        
        $DatePicker = $Browser.FindElementsById('id_start_date')
        
        for ($i=0; $i -lt 10; $i++)
        {
            $DatePicker.SendKeys(([Char](8)))
        }
        $DatePicker.SendKeys($StreamDate + ([Char](27)))
        
        $ActiveDay = $Browser.FindElementByClassName('active')
        
        
        $TimeDropDown = $Browser.FindElementById('s2id_id_start_hour')
        $TimeDropDown.Click()
        
        $SelectedTime = $Browser.FindElementsByClassName('select2-result-label') | Where-Object {$_.Text -eq $Time}
        $SelectedTime.Click()
        
        $saveButton = $Browser.FindElementsByClassName('btn') | Where-Object {$_.Text -eq 'SAVE'}
        $saveButton.Click()
        Start-Sleep -Seconds 5
    }
}

