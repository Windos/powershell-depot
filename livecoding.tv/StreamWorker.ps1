$Path = 'C:\References\'
        
Add-Type -Path (Join-Path -Path $Path -ChildPath '\Selenium\Selenium.WebDriverBackedSelenium.dll')
Add-Type -Path (Join-Path -Path $Path -ChildPath '\Selenium\ThoughtWorks.Selenium.Core.dll')
Add-Type -Path (Join-Path -Path $Path -ChildPath '\Selenium\WebDriver.dll')
Add-Type -Path (Join-Path -Path $Path -ChildPath '\Selenium\WebDriver.Support.dll')

$Browser = New-Object -TypeName OpenQA.Selenium.Chrome.ChromeDriver -ArgumentList @(,(Join-Path -Path $Path -ChildPath '\Chrome\'))

$Browser.Navigate().GoToUrl('https://www.livecoding.tv/accounts/login/')
Start-Sleep -Seconds 90

$StreamInfo = Import-Csv 'C:\streams.csv'

foreach ($NewStream in $StreamInfo)
{
    Add-ScheduledStream -Title $NewStream.Title -Date $NewStream.Date -Browser $Browser
}

$Browser.Quit()