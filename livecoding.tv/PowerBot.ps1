Add-Type -Path 'C:\references\selenium\Selenium.WebDriverBackedSelenium.dll'
Add-Type -Path 'C:\references\selenium\ThoughtWorks.Selenium.Core.dll'
Add-Type -Path 'C:\references\selenium\WebDriver.dll'
Add-Type -Path 'C:\references\selenium\WebDriver.Support.dll'

$service = [OpenQA.Selenium.PhantomJS.PhantomJSDriverService]::CreateDefaultService('C:\references\')
$service.HideCommandPromptWindow = $true

$Global:driver = New-Object OpenQA.Selenium.PhantomJS.PhantomJSDriver -ArgumentList @(,$service)

$email = ''

$pass = ''

$Global:driver.Navigate().GoToUrl('https://www.livecoding.tv/accounts/login/')

$userNameField = $Global:driver.FindElementById('id_login')
$passwordField = $Global:driver.FindElementById('id_password')
$buttons = $Global:driver.FindElementsByTagName('button')

foreach ($button in $buttons) {
    if ($button.Text -eq 'Login') {
        $loginButton = $button
    }
}

$userNameField.SendKeys(($email | Unprotect-CmsMessage))
$passwordField.SendKeys(($pass | Unprotect-CmsMessage))
$loginButton.Click()

$Global:driver.Navigate().GoToUrl('https://www.livecoding.tv/chat/windos/')

$Global:viewersGreeted = @()

function Out-Stream {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
#>
    [CmdletBinding()]
    [Alias()]
    Param (
        # Param1 help description
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 0)]
        [string[]] $Message
    )

    Begin {
        $textBox = $Global:driver.FindElementById('message-textarea')
        $sendButton = $Global:driver.FindElementByClassName('submit')
    }

    Process {
        foreach ($output in $Message) {
            $textBox.SendKeys($output)
            $sendButton.Click()
        }
    }

    End {}
}

function Get-StreamViewers {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
#>
    [CmdletBinding()]
    [Alias()]
    Param ()

    $user = $null
    $users = $Global:driver.FindElementsByClassName('user')

    foreach ($user in $users) {
        $user.GetAttribute('innerText').trimEnd('▾') #This may change with future lc.tv updates
    }
}

function Greet-StreamViewers {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
#>
    [CmdletBinding()]
    [Alias()]
    Param ()

    $user = $null
    $users = Get-StreamViewers

    foreach ($user in $users) {
        Write-Verbose $user
        if ($user -ne 'Windos' -and $user -ne 'PowerBot') {
            $greeted = $false
            
            foreach ($viewer in $Global:viewersGreeted) {
                Write-Verbose $viewer
                if ($user -eq $viewer) {
                    Write-Verbose 'Already greeted'
                    $greeted = $true
                } else {
                    Write-Verbose 'Not greeted'
                }
            }
            
            if (!$greeted) {
                Out-Stream -Message "Welcome $user!"
                $Global:viewersGreeted += $user
            }
        }
    }
}

function Greet-Loop {
    $Host.UI.RawUI.WindowTitle = 'PowerBot'
    $Host.Ui.RawUI.BackgroundColor = 'Red'
    $Host.Ui.RawUI.ForegroundColor = 'Black'

    While ($true) {
        Greet-StreamViewers
        Start-Sleep -Seconds 10
    }
}
