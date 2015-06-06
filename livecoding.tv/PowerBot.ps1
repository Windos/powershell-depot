function Initialize-PowerBot {
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

    if (!(Test-Path -Path $referencesPath)) {
        Write-Verbose -Message "$referencesPath does not exist, creating specified directory."
        New-Item -ItemType Directory -Path $referencesPath | Out-Null
    }
    
    Start-Job -Name 'Selenium' -ScriptBlock {
        $referencesPath = $args[0]
        if (!(Test-Path -Path (Join-Path -Path $referencesPath -ChildPath 'selenium\Selenium.WebDriverBackedSelenium.dll'))) {
            Write-Verbose -Message "Selenium not present in $referencesPath, downloading latest version."

            $sSource = 'http://selenium-release.storage.googleapis.com/2.45/selenium-dotnet-2.45.0.zip'
            $sArchive = Join-Path -Path $referencesPath -ChildPath 'selenium.zip'
 
            Invoke-WebRequest $sSource -OutFile $sArchive

            Write-Verbose -Message "Expanding Selenium archive."

            Expand-Archive -Path $sArchive -DestinationPath (Join-Path -Path $referencesPath -ChildPath '\temp-selenium')

            Write-Verbose -Message "Copying component files to permenant location."
            $seleniumPath = Join-Path -Path $referencesPath -ChildPath 'Selenium\'

            if (!(Test-Path -Path $seleniumPath)) {
                New-Item -ItemType Directory -Path $seleniumPath | Out-Null
            }
            Copy-Item -Path (Join-Path -Path $referencesPath -ChildPath '\temp-selenium\net40\*') -Destination $seleniumPath

            Remove-Item -Path $sArchive
            Remove-Item -Path (Join-Path -Path $referencesPath -ChildPath '\temp-selenium') -Recurse -Force
        }
    } -ArgumentList @(,$referencesPath) | Out-Null

    Start-Job -Name 'PhantomJS' -ScriptBlock {
        $referencesPath = $args[0]
        if (!(Test-Path -Path (Join-Path -Path $referencesPath -ChildPath '\PhantomJS\PhantomJS.exe'))) {
            Write-Verbose -Message "PhantomJS not present in $referencesPath, downloading latest version."

            $jSource = 'https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.0.0-windows.zip'
            $jArchive = Join-Path -Path $referencesPath -ChildPath 'phantomjs.zip'
 
            Invoke-WebRequest $jSource -OutFile $jArchive

            Write-Verbose -Message "Expanding PhantomJS archive."

            Expand-Archive -Path $jArchive -DestinationPath (Join-Path -Path $referencesPath -ChildPath '\temp-phantomjs')

            Write-Verbose -Message "Copying component files to permenant location."
            $phantomJSPath = Join-Path -Path $referencesPath -ChildPath 'PhantomJS\'

            if (!(Test-Path -Path $phantomJSPath)) {
                New-Item -ItemType Directory -Path $phantomJSPath | Out-Null
            }
            Copy-Item -Path (Join-Path -Path $referencesPath -ChildPath '\temp-phantomjs\phantomjs-2.0.0-windows\bin\*') -Destination $phantomJSPath

            Remove-Item -Path $JArchive
            Remove-Item -Path (Join-Path -Path $referencesPath -ChildPath '\temp-phantomjs') -Recurse -Force
        }
    } -ArgumentList @(,$referencesPath) | Out-Null

    Wait-Job -Name Selenium -Timeout 180 | Out-Null
    Get-Job -Name Selenium | Remove-Job

    Add-Type -Path (Join-Path -Path $referencesPath -ChildPath '\Selenium\Selenium.WebDriverBackedSelenium.dll')
    Add-Type -Path (Join-Path -Path $referencesPath -ChildPath '\Selenium\ThoughtWorks.Selenium.Core.dll')
    Add-Type -Path (Join-Path -Path $referencesPath -ChildPath '\Selenium\WebDriver.dll')
    Add-Type -Path (Join-Path -Path $referencesPath -ChildPath '\Selenium\WebDriver.Support.dll')
    
    Wait-Job -Name PhantomJS -Timeout 180 | Out-Null
    Get-Job -Name PhantomJS | Remove-Job

    $service = [OpenQA.Selenium.PhantomJS.PhantomJSDriverService]::CreateDefaultService((Join-Path -Path $referencesPath -ChildPath '\PhantomJS\'))
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
    $Global:newViewers = @{}
    $Global:activeChatter = @()
    $Global:lastTwitterLink = $null
    $Global:PBCommands = @{'!help' = '';
                           '!twitter' = 'Follow Windos on Twitter! https://twitter.com/WindosNZ';
                           '!microsoft' = 'Windos doesn''t work for Microsoft'}
    $Global:ChatLog = 'C:\GitHub\powershell-depot\livecoding.tv\chatlog.csv'
    $Global:LastPowerBotMessage = $null
    $Global:MemLog = @()

    $existingChat = Import-Csv -Path $Global:ChatLog
    foreach ($msg in $existingChat) {
        $properties = @{'UserName'=$msg.User;
                        'Message'=$msg.Message}
        $Result = New-Object -TypeName psobject -Property $properties
        $Global:MemLog += $Result
    }

    $Stoploop = $false
    [int]$Retrycount = "0"
     
    do {
    	try {
    		$Global:textBox = $Global:driver.FindElementById('message-textarea')
            $Global:sendButton = $Global:driver.FindElementByClassName('submit')
    		$Stoploop = $true
    	}
    	catch {
    		if ($Retrycount -gt 5){
    			$Stoploop = $true
    		}
    		else {
    			Start-Sleep -Seconds 10
    			$Retrycount = $Retrycount + 1
    		}
    	}
    } While ($Stoploop -eq $false)
}

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

    Begin {}

    Process {
        foreach ($output in $Message) {
            $Global:textBox.SendKeys($output)
            $Global:sendButton.Click()

            $pbMessage = New-Object -TypeName PSCustomObject -property @{'Time'=Get-Date;
                                                                         'User'='PowerBot';
                                                                         'Message'=$output
            }
            $Global:LastPowerBotMessage = $pbMessage
            # Make this persistent later (save to disk...)
        }
    }

    End {}
}

function Read-Stream {
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

    $chatMessages = $Global:driver.FindElementsByClassName('lctv-premium')

    $log = @()
    foreach ($chatMessage in $chatMessages) {
        $parts = ($chatMessage.GetAttribute('innerHTML')).Split('>')
        $username = $parts[1].Replace('</a', '')

        $messageText = $parts[2]

        $properties = @{'UserName'=$username;
                        'Message'=$messageText}
        $Result = New-Object -TypeName psobject -Property $properties
        $log += $Result
    }

    if ($all) {
        $log
    } else {
        $difference = Compare-Object -ReferenceObject $Global:MemLog -DifferenceObject $log -Property 'UserName', 'Message' | where sideindicator -eq '=>'
        foreach ($newMessage in $difference) {
            Log-Chat -ChatMessage $newMessage
        }
        $Global:MemLog = @()

        $existingChat = Import-Csv -Path $Global:ChatLog
        foreach ($msg in $existingChat) {
            $properties = @{'UserName'=$msg.User;
                            'Message'=$msg.Message}
            $Result = New-Object -TypeName psobject -Property $properties
            $Global:MemLog += $Result
        }
    }
}

function Log-Chat {
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
        [psobject] $ChatMessage
    )

    $result = New-Object -TypeName PSCustomObject -property @{'Time'=Get-Date;
                                                              'User'=$ChatMessage.Username;
                                                              'Message'=$ChatMessage.Message
    }

    $result | Export-Csv -Path $Global:ChatLog -Append
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
    $testTime = (Get-Date).AddMinutes(-2)

    $Greetings = @('Welcome {0}!',
                   'Hey {0}',
                   'How''s it going, {0}?',
                   'Hey {0}, how''s it going?',
                   'Good to see you, {0}',
                   'Hi {0}',
                   'Howdy {0}'
    )

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
                if ($Global:newViewers.ContainsKey($user)) {
                    $userTime = $Global:newViewers.$user
                    if ($userTime -le $testTime) {
                        $rand = $null
                        $rand = Get-Random -Minimum 0 -Maximum ($Greetings.Length - 1)
                        Out-Stream -Message ($Greetings[$rand] -f $user)
                        $Global:viewersGreeted += $user
                    }
                } else {
                    $Global:newViewers.Add($user,(Get-Date))
                }
            }
        }
    }
}

function Start-Raffle {
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

function Send-PBHelp {
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
    foreach ($command in $commands) {
        $outHelp += "$($command.Name), "
    }
    $outHelp = $outHelp.Trim().TrimEnd(',')
    $outHelp | Out-Stream
}

function Add-PBCommand {
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

    foreach ($userMessage in $userMessages) {
        if ($userMessage.UserName -eq 'Windos') {
            if ($userMessage.Message -like "Add-PBCommand*") {
                $parts = $userMessage.Message.Split('-')
                $key = ($parts[2].Replace('command ','')).Trim().Trim("'")

                if (!($Global:PBCommands.ContainsKey($key))) {
                    $value = ($parts[3].Replace('message ','')).Trim().Trim("'")
                    $Global:PBCommands.Add($key, $value)
                }
            }
        }
    }
}

function Check-PBCommand {
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

    $fullLog = import-csv -Path $Global:ChatLog
    $delay = (Get-Date).AddMinutes(-60)
    $helpDelay = (Get-Date).AddMinutes(-30)
    $active = (Get-Date).AddSeconds(-15)
    $cmds = $Global:PBCommands.GetEnumerator()

    $commandRequests = $fullLog | Where-Object -FilterScript {$_.Message -like "!*"}
    foreach ($commandRequest in $commandRequests) {
        if ($commandRequest.Message -in $Global:PBCommands.Keys) {
            if ((Get-Date $commandRequest.Time) -gt $active) {
                $recentResponse = $false
                if ($commandRequest.Message -eq '!help') {
                    $commandResponses = $fullLog | Where-Object -FilterScript {$_.Message -like "Available Commands: *" -and $_.User -eq 'PowerBot'}
                    foreach ($commandResponse in $commandResponses) {
                        $responseTime = Get-Date $commandResponse.Time
                        if ($responseTime -gt $helpDelay) {
                            $recentResponse = $true
                        }
                    }
                    if (!$recentResponse) {
                        Send-PBHelp
                        Start-Sleep -Seconds 0.5
                    }
                } else {
                    $commandOutput = $Global:PBCommands.($commandRequest.Message)
                    $testString = $commandOutput
                    if ($commandOutput -like "*twitter*") {
                        $testString = $testString.Replace(' https://twitter.com/WindosNZ','')
                    }
                    $commandResponses = $fullLog | Where-Object -FilterScript {$_.Message -like "$testString*" -and $_.User -eq 'PowerBot'}

                    foreach ($commandResponse in $commandResponses) {
                        $responseTime = Get-Date $commandResponse.Time
                        if ($responseTime -gt $delay) {
                            $recentResponse = $true
                        }
                    }
                    if (!$recentResponse) {
                        Out-Stream -Message $commandOutput
                        Start-Sleep -Seconds 0.5
                    }
                }
            }
        }
    }
}

function Start-PBLoop {
    Start-Job -Name 'Greeter' -ScriptBlock {
        try {
            . 'C:\GitHub\powershell-depot\livecoding.tv\PowerBot.ps1'
            Initialize-PowerBot
            Out-Stream 'PowerBot: Online'
            While ($true) {
                Greet-StreamViewers
                Read-Stream
                Check-PBCommand
                Start-Sleep -Seconds 1
            }
        } catch {
        } finally {
            $driver.Quit()
        }
    } | Out-Null
}
