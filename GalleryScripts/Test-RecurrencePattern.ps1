<#PSScriptInfo
.VERSION
    0.1.1
.GUID
    e44a66c3-92cb-41f0-846b-43c74bb1ef75
.AUTHOR
    Joshua (Windos) King
.DESCRIPTION
	Tests a recurrence pattern against the current date.
.COMPANYNAME
    king.geek.nz
.COPYRIGHT
    (c) 2017 Joshua (Windos) King.
.TAGS
    Recurrence Utility Helper
.PROJECTURI
    https://github.com/Windos/powershell-depot/tree/master/GalleryScripts
.RELEASENOTES
0.1.1:
* Mixed misspelling: Patern -> Pattern
0.1.0:
* Initial release
#>

function Test-RecurrencePattern {
    <#
    .SYNOPSIS
        Tests a recurrence pattern against the current date.
    .DESCRIPTION
        The Test-RecurrencePattern function tests a recurrence pattern against the current date.

        Given a specified day of the week, via the Day parameter, and an Instance, this function will provide a
        boolean value depending on whether the current date falls within the recurrence pattern.

        For example, if you specify the "First Tuesday" of a month, but it is the Tuesday the 15th this function will
        return false.
    .INPUTS
        System.String
    .OUTPUTS
        System.Boolean
    .EXAMPLE
        PS C:\> Test-RecurrencePattern -Day Friday -Instance Last

        This command will return true if it is run on the last Friday of a given month, for example 08/25/2017. On all
        other days it will return a false.
    #>

    [OutputType('System.Boolean')]
    param (
        # Specifies the day of the week on which the recurrence will occur.
        [Parameter(Mandatory)]
        [ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]
        [String] $Day,

        # Specifies which instance of the specified day is valid within a recurrence pattern.
        #
        # Note that 'Fourth' and 'Last' are not the same thing, as some months have up to five instances of a given
        # day of the week.
        [Parameter(Mandatory)]
        [ValidateSet('First', 'Second', 'Third', 'Fourth', 'Last')]
        [String] $Instance
    )

    $Now = Get-Date

    switch ($Instance) {
        'First' {$OccuranceInMonth = 0}
        'Second' {$OccuranceInMonth = 1}
        'Third' {$OccuranceInMonth = 2}
        'Fourth' {$OccuranceInMonth = 3}
        'Last' {$OccuranceInMonth = -1}
    }

    $PossibleDays = @()
    foreach ($Date in 0..([datetime]::DaysInMonth($Now.Year, $Now.Month) - 1)) {
        $TestDate = (Get-Date -Year $Now.Year -Month $Now.Month -Day 1).AddDays($Date)
        if ($TestDate.DayOfWeek -eq $Day) {
            $PossibleDays += $TestDate.Day
        }
    }

    $ValidRunDate = Get-Date -Year $Now.Year -Month $Now.Month -Day $PossibleDays[$OccuranceInMonth]
    $Now.Date -eq $ValidRunDate.Date
}
