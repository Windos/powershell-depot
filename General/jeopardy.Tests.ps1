. .\jeopardy.ps1
$WarningPreference = 'SilentlyContinue'

Describe 'Jeopardy in PowerShell' {
    $Global:AllGameCats = @()
    $Global:GameCats = @()
    $Global:GameClues = @()
    $Global:answers = @{}
    $Global:offset = $null

    Context 'Get-AllCategories' {
        It 'gets all available catgeories from jservice.io' {
            Get-AllCategories
            ($Global:AllGameCats | Measure-Object).Count -gt 1000 | Should Be $true
        }
    }

    Context 'Start-Game' {
        It "didn't call Get-AllCategories" {
            Mock Get-AllCategories {}
            Start-Game 
            Assert-MockCalled Get-AllCategories -Exactly 0
        }

        It 'loads categories from disk' {
            $Global:AllGameCats = @()
            Mock PesterDummy {} -ParameterFilter { $Source -eq 'LoadFromDisk' }
            Start-Game 
            Assert-MockCalled PesterDummy -Exactly 1
        }

        It 'chose six random categories' {
            ($Global:GameCats | Measure-Object).Count | Should Be 6
        }

        It 'found 30 random clues (5 per category)' {
            ($Global:GameClues | Measure-Object).Count | Should Be 30
        }
    }
}