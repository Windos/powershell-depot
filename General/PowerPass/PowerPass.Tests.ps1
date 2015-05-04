. .\PowerPass.ps1
$testhost = $env:COMPUTERNAME

Describe 'PowerPass' {
    $clixml = Import-Clixml -Path ".\PPCredential-$testhost.Tests.clixml"
    Mock Import-Clixml { return $clixml }
    $testPPCredential = @()
    $Global:CredLocker = @()

    Context 'Open-PPCredential' {
        It 'opened the clixml file on disk' {
            Open-PPCredential | Should Be $null
        }
        It 'loaded two PPCredential objects into the CredLocker' {
            ($global:credlocker | Measure-Object).Count | Should Be 2
        }
    }

    Context 'New-PPCredential' {
        $Cred = $Global:CredLocker[0].Credential
        $Global:testPPCredential = New-PPCredential -Name 'Third Test Account' -Folder 'Test' -Note 'Not going to be saved to disk' -Credential $Cred

        It "created new PPCredential object with the name 'Third Test Account'" {
            $Global:testPPCredential.Name | Should Be 'Third Test Account'
        }
        It "created new PPCredential object in the 'Test' folder" {
            $Global:testPPCredential.Folder | Should Be 'Test'
        }
        It "created new PPCredential object with the note 'Not going to be saved to disk'" {
            $Global:testPPCredential.Notes | Should Be 'Not going to be saved to disk'
        }
        It 'created new PPCredential object that is not set as a favorite' {
            $Global:testPPCredential.Favorite | Should Be $false
        }
    }

    Context 'Add-PPCredential' {
        Add-PPCredential -Credential $Global:testPPCredential 
        It 'added a PPCredential to the CredLocker, total is now 3' {
            ($Global:CredLocker | Measure-Object).Count | Should Be 3
        }
    }

    Context 'Save-PPCredential' {
        It 'saved the CredLocker array to disk as a clixml file' {
            Mock Export-Clixml {}
            Save-PPCredential    
            Assert-MockCalled Export-Clixml -Exactly 1
        }
    }

    Context 'Search-PPCredential' {
        It 'returns all objects in the CredLocker' {
            (Search-PPCredential | Measure-Object).Count | Should Be 3
        }

        It 'returns all objects that have "Pester" in their name (case insensitive)' {
            (Search-PPCredential -UserName 'pester' | Measure-Object).Count | Should Be 1
        }

        It 'returns all objects that have "pester" in their name (case sensitive)' {
            (Search-PPCredential -UserName 'pester' -CaseSensitive | Measure-Object).Count | Should Be 0
        }

        It 'returns all objects that have "pester" in their name, if that is the entire name (whole word)' {
            (Search-PPCredential -UserName 'pester' -WholeWord | Measure-Object).Count | Should Be 0
        }

        It 'returns the object with Id 2' {
            (Search-PPCredential -Id 2 | Measure-Object).Count | Should Be 1
        }
    }
}