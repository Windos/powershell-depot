<#PSScriptInfo

.VERSION 0.0.1

.GUID e30f0920-5320-452a-995e-3466b4512d1b

.AUTHOR Joshua (Windos) King

.COMPANYNAME king.geek.nz

.COPYRIGHT (c) 2017 Joshua (Windos) King. All rights reserved.

.TAGS Utility

.LICENSEURI https://github.com/Windos/powershell-depot/blob/master/LICENSE.md

.PROJECTURI https://github.com/Windos/powershell-depot/tree/master/GalleryScripts

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
* Initial Release

#>

#Requires -Module PoshRSJob

<#
.SYNOPSIS
Measures runtime over multiple runs of a given scriptblock.

.DESCRIPTION
Runs a given scriptblock multiple times, measures runtime and reports back: shortest
runtime, longest runtime, and average runtime.

.PARAMETER ScriptBlock
The code/test cases to be run multiple times and measured.

.PARAMETER Iterations
Total number of test cases to run. Defaults to 100.

.PARAMETER Throttle
Number of concurrent test cases to run. Defaults to 5.

.EXAMPLE
Start-TestCaseMeasurement -ScriptBlock {Write-Host 'How long does it take to write a string?'}

This example measures how long it takes to write a string.

Defaults to 100 iterations, and a throttle of 5.

.EXAMPLE
Start-TestCaseMeasurement -ScriptBlock {Invoke-RestMethod -Uri 'http://example.com/fakeapi'} -Iterations 1000 -Throttle 100

This example measures how long it takes to querry an API.

Runs the scriptblock 1000 times and running 100 instances in parallel.

.LINK
https://github.com/Windos/powershell-depot/tree/master/GalleryScripts
#>

[CmdletBinding()]

param (
    [Parameter(Mandatory)]
    [scriptblock] $ScriptBlock,

    [int] $Iterations = 100,

    [int] $Throttle = 5
)

$JobBlock = {
    $Measurement = Measure-Command -Expression {$_.Script}
    [PSCustomObject] @{
        Iteration = $_.Iteration
        RunTime = $Measurement.TotalMilliseconds
    }
}

$Result = (1..$Iterations | foreach {[PSCustomObject] @{Iteration = $_; Script = $ScriptBlock}} |
    Start-RSJob -ScriptBlock $JobBlock -Name {$_.Iteration} -Throttle $Throttle |
    Wait-RSJob -ShowProgress | Receive-RSJob).RunTime | Measure -Average -Maximum -Minimum

[PSCustomObject] @{
    Minimum = $Result.Minimum
    Maximum = $Result.Maximum
    Average = $Result.Average
}
