function Start-RunBucket {
    [CmdletBinding(DefaultParameterSetName = 'scriptblock')]

    param (
        [Parameter(Mandatory,
                   Position = 0,
                   ParameterSetName = 'scriptblock')]
        [scriptblock] $Control,

        [Parameter(Mandatory,
                   Position = 1,
                   ParameterSetName = 'scriptblock')]
        [scriptblock] $Variation,

        [Parameter(Mandatory,
                   Position = 0,
                   ParameterSetName = 'file')]
        [ValidateScript({Test-Path -Path $_})]
        [string] $ControlPath,

        [Parameter(Mandatory,
                   Position = 1,
                   ParameterSetName = 'file')]
        [ValidateScript({Test-Path -Path $_})]
        [string] $VariationPath
    )

    $ControlResult = Start-TestCaseMeasurement -ScriptBlock $Control -Throttle 25
    Start-Sleep -Milliseconds 50
    $VariationResult = Start-TestCaseMeasurement -ScriptBlock $Variation -Throttle 25

    $Difference = [PSCustomObject] @{
        Minimum = Measure-RBDifference -Control $ControlResult.Minimum -Variation $VariationResult.Minimum
        Maximum = Measure-RBDifference -Control $ControlResult.Maximum -Variation $VariationResult.Maximum
        Average = Measure-RBDifference -Control $ControlResult.Average -Variation $VariationResult.Average
    }

    Start-RBResultDashboard -ControlResult $ControlResult -VariationResult $VariationResult -Difference $Difference
}