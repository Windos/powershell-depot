. .\PowerPass.ps1

Describe 'PowerPass' {
    $clixml = Import-Clixml -Path 'C:\GitHub\powershell-depot\General\PowerPass\PPCredential.Tests.clixml'
    Mock Import-Clixml { return $clixml }

    Context 'testing Open-PPCredential cmdlet' {
        It 'opened the credential locker' {
            Open-PPCredential | Should Be $null
        }
        It 'CredLocker is not empty' {
            $global:credlocker | Should Not BeNullOrEmpty
        }
    }

    Context 'testing Show-PPCredential cmdlet' {
        It 'shows only one PPCredential' {
            (Show-PPCredential | Measure-Object).Count | Should be 1
        }
        It 'shows the Pester test account' {
            (Show-PPCredential)[0].Name | Should be 'Pester Test Account'
        }
    }

    Context 'testing New-PPCredential cmdlet' {
        $Cred = (Show-PPCredential)[0].Credential
        $testPPCredential = New-PPCredential -Name 'Second Test Account' -Folder 'Test' -Note 'Not going to be saved to disk' -Credential $Cred

        It "has the name 'Second Test Account'" {
            $testPPCredential.Name | Should Be 'Second Test Account'
        }
        It "is in the 'Test' folder" {
            $testPPCredential.Folder | Should Be 'Test'
        }
        It "has the note 'Not going to be saved to disk'" {
            $testPPCredential.Notes | Should Be 'Not going to be saved to disk'
        }
        It 'is not set as favorite' {
            $testPPCredential.Favorite | Should Be $false
        }
    }

    #Context 'testing Add-PPCredential cmdlet' {
    #    It 'adds a PPCredential to the CredLocker' {
    #        Add-PPCredential -Credential $testPPCredential | Should Not Throw
    #    }
    #}

    Context 'testing Save-PPCredential cmdlet' {
        It 'saves CredLocker to disk' {
            Mock Export-Clixml {}
            Save-PPCredential    
            Assert-MockCalled Export-Clixml -Exactly 1
        }
    }
}