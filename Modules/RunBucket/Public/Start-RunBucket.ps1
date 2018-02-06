function Start-RunBucket {
    [CmdletBinding()]

    param (
        [Parameter(Mandatory)]
        [scriptblock] $Control,

        [Parameter(Mandatory)]
        [scriptblock] $Variation
    )

    Get-UDDashboard -Name 'RunBucketResults' | Stop-UDDashboard

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