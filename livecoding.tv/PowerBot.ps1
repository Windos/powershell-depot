#requires -Version 5

<#ToDo:
 * Greeter:
   * Reset greet delay if viewer leaves chat (i.e. if viewer leaves before 30 seconds, don't auto greet if they re-visit later unless they stay for delay)
   (this may be fixed, needs testing off stream)
 * Revisit dynamically adding commands, add to PBLoop.
   * Make added commands persistent.
   * Edit commands, remove commands.
 * Add comment based help
 * Track 'active' viewers (people who have typed in chat between time x and y)
 * Implement raffle system.
 * Polls/votes (maybe leverage new lc.tv facility)
 * New follower notifications (this and lc.tv poll facility will require bot to log in to site as myself rather than its own account.)
 * Limit some commands to followers only?
 * Song requests?
 * Creating countdown (progress bars) from chat command
 * Command to mute/unmute the bot
 * 'status' updates? (change an OBS ticker?)
 * control OBS/Foobar2000 through bot?
#>

function Initialize-PowerBot 
{
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
        [string] $referencesPath = 'C:\References'
    )

    if (!(Test-Path -Path $referencesPath)) 
    {
        Write-Verbose -Message "$referencesPath does not exist, creating specified directory."
        $null = New-Item -ItemType Directory -Path $referencesPath
    }
    
    $null = Start-Job -Name 'SeleniumInstall' -ScriptBlock {
        $referencesPath = $args[0]
        if (!(Test-Path -Path (Join-Path -Path $referencesPath -ChildPath 'selenium\Selenium.WebDriverBackedSelenium.dll'))) 
        {
            Write-Verbose -Message "Selenium not present in $referencesPath, downloading latest version."

            $seleniumSource = 'http://selenium-release.storage.googleapis.com/2.45/selenium-dotnet-2.45.0.zip'
            $seleniumArchive = Join-Path -Path $referencesPath -ChildPath 'selenium.zip'
 
            Invoke-WebRequest -Uri $seleniumSource -OutFile $seleniumArchive

            Write-Verbose -Message 'Expanding Selenium archive.'

            Expand-Archive -Path $seleniumArchive -DestinationPath (Join-Path -Path $referencesPath -ChildPath '\temp-selenium')

            Write-Verbose -Message 'Copying component files to permenant location.'
            $seleniumPath = Join-Path -Path $referencesPath -ChildPath 'Selenium\'

            if (!(Test-Path -Path $seleniumPath)) 
            {
                $null = New-Item -ItemType Directory -Path $seleniumPath
            }
            Copy-Item -Path (Join-Path -Path $referencesPath -ChildPath '\temp-selenium\net40\*') -Destination $seleniumPath

            Remove-Item -Path $seleniumArchive
            Remove-Item -Path (Join-Path -Path $referencesPath -ChildPath '\temp-selenium') -Recurse -Force
        }
    } -ArgumentList @(,$referencesPath)

    $null = Start-Job -Name 'PhantomJsInstall' -ScriptBlock {
        $referencesPath = $args[0]
        if (!(Test-Path -Path (Join-Path -Path $referencesPath -ChildPath '\PhantomJS\PhantomJS.exe'))) 
        {
            Write-Verbose -Message "PhantomJS not present in $referencesPath, downloading latest version."

            $phantomJsSource = 'https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.0.0-windows.zip'
            $phantomJsArchive = Join-Path -Path $referencesPath -ChildPath 'phantomjs.zip'
 
            Invoke-WebRequest -Uri $phantomJsSource -OutFile $phantomJsArchive

            Write-Verbose -Message 'Expanding PhantomJS archive.'

            Expand-Archive -Path $phantomJsArchive -DestinationPath (Join-Path -Path $referencesPath -ChildPath '\temp-phantomjs')

            Write-Verbose -Message 'Copying component files to permenant location.'
            $phantomJSPath = Join-Path -Path $referencesPath -ChildPath 'PhantomJS\'

            if (!(Test-Path -Path $phantomJSPath)) 
            {
                $null = New-Item -ItemType Directory -Path $phantomJSPath
            }
            Copy-Item -Path (Join-Path -Path $referencesPath -ChildPath '\temp-phantomjs\phantomjs-2.0.0-windows\bin\*') -Destination $phantomJSPath

            Remove-Item -Path $phantomJsArchive
            Remove-Item -Path (Join-Path -Path $referencesPath -ChildPath '\temp-phantomjs') -Recurse -Force
        }
    } -ArgumentList @(,$referencesPath)

    $null = Wait-Job -Name SeleniumInstall -Timeout 180
    Get-Job -Name SeleniumInstall  | Remove-Job

    Add-Type -Path (Join-Path -Path $referencesPath -ChildPath '\Selenium\Selenium.WebDriverBackedSelenium.dll')
    Add-Type -Path (Join-Path -Path $referencesPath -ChildPath '\Selenium\ThoughtWorks.Selenium.Core.dll')
    Add-Type -Path (Join-Path -Path $referencesPath -ChildPath '\Selenium\WebDriver.dll')
    Add-Type -Path (Join-Path -Path $referencesPath -ChildPath '\Selenium\WebDriver.Support.dll')
    
    $null = Wait-Job -Name PhantomJsInstall -Timeout 180
    Get-Job -Name PhantomJsInstall | Remove-Job

    $phatomJsService = [OpenQA.Selenium.PhantomJS.PhantomJSDriverService]::CreateDefaultService((Join-Path -Path $referencesPath -ChildPath '\PhantomJS\'))
    $phatomJsService.HideCommandPromptWindow = $true
    
    $Global:phantomJsDriver = New-Object -TypeName OpenQA.Selenium.PhantomJS.PhantomJSDriver -ArgumentList @(,$phatomJsService)

    PASSWORD HERE!
    
    $Global:phantomJsDriver.Navigate().GoToUrl('https://www.livecoding.tv/accounts/login/')
    
    $userNameField = $Global:phantomJsDriver.FindElementById('id_login')
    $passwordField = $Global:phantomJsDriver.FindElementById('id_password')
    $buttons = $Global:phantomJsDriver.FindElementsByTagName('button')
    
    foreach ($button in $buttons) 
    {
        if ($button.Text -eq 'Login') 
        {
            $loginButton = $button
        }
    }
    
    $userNameField.SendKeys($email)
    $passwordField.SendKeys($pass)
    $loginButton.Click()
    
    $Global:phantomJsDriver.Navigate().GoToUrl('https://www.livecoding.tv/chat/windos/')
    
    $Global:viewersGreeted = @()

    if (!(Test-Path -Path 'C:\GitHub\powershell-depot\livecoding.tv\greeted.csv'))
    {
        $null = New-Item -Path 'C:\GitHub\powershell-depot\livecoding.tv\greeted.csv' -ItemType File
    }

    $importedGreeted = Import-Csv -Path 'C:\GitHub\powershell-depot\livecoding.tv\greeted.csv'

    foreach ($previousGreet in $importedGreeted)
    {
        $properties = @{
            'Name' = $previousGreet.Name
            'whenGreeted' = (Get-Date $previousGreet.whenGreeted)
        }
        $Result = New-Object -TypeName psobject -Property $properties
        $Global:viewersGreeted += $Result
    }

    $Global:newViewers = @{}
    $Global:PBCommands = @{
        '!help'    = ''
        '!twitter' = 'Follow Windos on Twitter! https://twitter.com/WindosNZ'
        '!microsoft' = 'Windos doesn''t work for Microsoft'
    }
    $Global:ChatLog = 'C:\GitHub\powershell-depot\livecoding.tv\chatlog.csv'
    $Global:MemLog = @()

    if (!(Test-Path -Path $Global:ChatLog))
    {
        $null = New-Item -Path $Global:ChatLog -ItemType File
    }

    $existingChat = Import-Csv -Path $Global:ChatLog
    foreach ($msg in $existingChat) 
    {
        $properties = @{
            'UserName' = $msg.User
            'Message' = $msg.Message
        }
        $Result = New-Object -TypeName psobject -Property $properties
        $Global:MemLog += $Result
    }

    $StopLoop = $false
    [int]$Retrycount = 0
     
    do 
    {
        try 
        {
            $Global:messageTextArea = $Global:phantomJsDriver.FindElementById('message-textarea')
            $Global:chatSendButton = $Global:phantomJsDriver.FindElementByClassName('submit')
            $StopLoop = $true
        }
        catch 
        {
            if ($Retrycount -gt 5)
            {
                $StopLoop = $true
            }
            else 
            {
                Start-Sleep -Seconds 10
                $Retrycount = $Retrycount + 1
            }
        }
    }
    While ($StopLoop -eq $false)
}

function Out-Stream 
{
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

    Begin {}

    Process {
        foreach ($output in $Message) 
        {
            $Global:messageTextArea.SendKeys($output)
            $Global:chatSendButton.Click()
        }
    }

    End {}
}

function Read-Stream 
{
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
        [switch] $all
    )

    $chatMessages = $Global:phantomJsDriver.FindElementsByClassName('lctv-premium')

    $log = @()
    foreach ($chatMessage in $chatMessages) 
    {
        $parts = ($chatMessage.GetAttribute('innerHTML')).Split('>')
        $username = $parts[1].Replace('</a', '')

        $messageText = $parts[2]

        $properties = @{
            'UserName' = $username
            'Message' = $messageText
        }
        $Result = New-Object -TypeName psobject -Property $properties
        $log += $Result
    }

    if ($all) 
    {
        $log
    }
    else 
    {
        $difference = Compare-Object -ReferenceObject $Global:MemLog -DifferenceObject $log -Property 'UserName', 'Message' | Where-Object -Property sideindicator -EQ -Value '=>'
        foreach ($newMessage in $difference) 
        {
            Log-Chat -ChatMessage $newMessage
        }
        $Global:MemLog = @()

        $existingChat = Import-Csv -Path $Global:ChatLog
        foreach ($msg in $existingChat) 
        {
            $properties = @{
                'UserName' = $msg.User
                'Message' = $msg.Message
            }
            $Result = New-Object -TypeName psobject -Property $properties
            $Global:MemLog += $Result
        }
    }
}

function Log-Chat 
{
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
        [psobject] $chatMessage
    )

    $Result = New-Object -TypeName PSCustomObject -Property @{
        'Time'  = Get-Date
        'User'  = $chatMessage.Username
        'Message' = $chatMessage.Message
    }

    $Result | Export-Csv -Path $Global:ChatLog -Append
}

function Get-StreamViewers 
{
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
    $users = $Global:phantomJsDriver.FindElementsByClassName('user')

    foreach ($user in $users) 
    {
        $user.GetAttribute('innerText').trimEnd('▾') #This may change with future lc.tv updates
    }
}

function Greet-StreamViewers 
{
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
    $testTime = (Get-Date).AddSeconds(-30)
    $regreetTime = (Get-Date).AddHours(-13)

    $Greetings = @('Welcome {0}!', 
        'Hey {0}', 
        'How''s it going, {0}?', 
        'Hey {0}, how''s it going?', 
        'Good to see you, {0}', 
        'Hi {0}', 
        'Howdy {0}'
    )

    foreach ($user in $users) 
    {
        Write-Verbose -Message $user
        if ($user -ne 'Windos' -and $user -ne 'PowerBot') 
        {
            $greeted = $false
            
            foreach ($viewer in $Global:viewersGreeted)
            {
                Write-Verbose -Message $viewer.Name
                if ($user -eq $viewer.Name) 
                {
                    if ($viewer.whenGreeted -ge $regreetTime)
                    {
                        Write-Verbose -Message 'Already greeted'
                        $greeted = $true
                    }
                }
                else 
                {
                    Write-Verbose -Message 'Not greeted'
                }
            }
            
            if (!$greeted) 
            {
                if ($Global:newViewers.ContainsKey($user)) 
                {
                    $userTime = $Global:newViewers.$user
                    if ($userTime -le $testTime) 
                    {
                        $rand = $null
                        $rand = Get-Random -Minimum 0 -Maximum ($Greetings.Length - 1)
                        Out-Stream -Message ($Greetings[$rand] -f $user)

                        $properties = @{
                            'Name' = $user
                            'whenGreeted' = (Get-Date)
                        }
                        $Result = New-Object -TypeName psobject -Property $properties
                        $Global:viewersGreeted += $Result
                        $Global:viewersGreeted | Export-Csv -Path 'C:\GitHub\powershell-depot\livecoding.tv\greeted.csv'
                        $Global:newViewers.Remove($user)
                    }
                }
                else
                {
                    $Global:newViewers.Add($user,(Get-Date))
                }
            }
        }
    }

    foreach ($newViewer in $Global:newViewers) {
        if ($newViewer.Keys -notin $users) {
            $Global:newViewers.Remove($newViewer.Keys)
        }
    }
}

function Start-Raffle 
{
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

    $userMessages = Read-Stream
    $uniqueUsers = ($userMessages | Group-Object -Property UserName).Name
    $uniqueUsers
}

function Send-PBHelp 
{
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

    $userMessages = Read-Stream -all
    $outHelp = 'Available Commands: '
    $commands = $Global:PBCommands.GetEnumerator()
    foreach ($command in $commands) 
    {
        $outHelp += "$($command.Name), "
    }
    $outHelp = $outHelp.Trim().TrimEnd(',')
    $outHelp | Out-Stream
}

function Add-PBCommand 
{
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

    $userMessages = Read-Stream
    $linkLimit = (Get-Date).AddHours(-1)

    foreach ($userMessage in $userMessages) 
    {
        if ($userMessage.UserName -eq 'Windos') 
        {
            if ($userMessage.Message -like 'Add-PBCommand*') 
            {
                $parts = $userMessage.Message.Split('-')
                $key = ($parts[2].Replace('command ','')).Trim().Trim("'")

                if (!($Global:PBCommands.ContainsKey($key))) 
                {
                    $value = ($parts[3].Replace('message ','')).Trim().Trim("'")
                    $Global:PBCommands.Add($key, $value)
                }
            }
        }
    }
}

function Check-PBCommand 
{
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

    $fullLog = Import-Csv -Path $Global:ChatLog
    $delay = (Get-Date).AddMinutes(-60)
    $helpDelay = (Get-Date).AddMinutes(-30)
    $active = (Get-Date).AddSeconds(-15)
    $cmds = $Global:PBCommands.GetEnumerator()

    $commandRequests = $fullLog | Where-Object -FilterScript {
        $_.Message -like '!*'
    }
    foreach ($commandRequest in $commandRequests) 
    {
        if ($commandRequest.Message -in $Global:PBCommands.Keys) 
        {
            if ((Get-Date -Date $commandRequest.Time) -gt $active) 
            {
                $recentResponse = $false
                if ($commandRequest.Message -eq '!help') 
                {
                    $commandResponses = $fullLog | Where-Object -FilterScript {
                        $_.Message -like 'Available Commands: *' -and $_.User -eq 'PowerBot'
                    }
                    foreach ($commandResponse in $commandResponses) 
                    {
                        $responseTime = Get-Date -Date $commandResponse.Time
                        if ($responseTime -gt $helpDelay) 
                        {
                            $recentResponse = $true
                        }
                    }
                    if (!$recentResponse) 
                    {
                        Send-PBHelp
                        Start-Sleep -Seconds 0.5
                    }
                }
                else 
                {
                    $commandOutput = $Global:PBCommands.($commandRequest.Message)
                    $testString = $commandOutput
                    if ($commandOutput -like '*twitter*') 
                    {
                        $testString = $testString.Replace(' https://twitter.com/WindosNZ','')
                    }
                    $commandResponses = $fullLog | Where-Object -FilterScript {
                        $_.Message -like "$testString*" -and $_.User -eq 'PowerBot'
                    }

                    foreach ($commandResponse in $commandResponses) 
                    {
                        $responseTime = Get-Date -Date $commandResponse.Time
                        if ($responseTime -gt $delay) 
                        {
                            $recentResponse = $true
                        }
                    }
                    if (!$recentResponse) 
                    {
                        Out-Stream -Message $commandOutput
                        Start-Sleep -Seconds 0.5
                    }
                }
            }
        }
    }
}

function Start-PBLoop 
{
    $null = Start-Job -Name 'Greeter' -ScriptBlock {
        try 
        {
            . 'C:\GitHub\powershell-depot\livecoding.tv\PowerBot.ps1'
            Initialize-PowerBot
            Out-Stream -Message 'PowerBot: Online'
            While ($true) 
            {
                Greet-StreamViewers
                Read-Stream
                Check-PBCommand
                Start-Sleep -Seconds 1
            }
        }
        catch 
        {

        }
        finally 
        {
            $driver.Quit()
        }
    }
}
