function Start-RunBucket {
    [CmdletBinding()]

    param (
        [Parameter(Mandatory)]
        [scriptblock] $Control,

        [Parameter(Mandatory)]
        [scriptblock] $Variation,

        [Parameter()]
        [string] $Title,

        [Parameter()]
        [int] $Iterations = 100
    )

    $ControlResult = Start-TestCaseMeasurement -ScriptBlock $Control -Throttle 25 -Iterations $Iterations
    Start-Sleep -Milliseconds 50
    $VariationResult = Start-TestCaseMeasurement -ScriptBlock $Variation -Throttle 25 -Iterations $Iterations

    $Difference = [PSCustomObject] @{
        Minimum = Measure-RBDifference -Control $ControlResult.Minimum -Variation $VariationResult.Minimum
        Maximum = Measure-RBDifference -Control $ControlResult.Maximum -Variation $VariationResult.Maximum
        Average = Measure-RBDifference -Control $ControlResult.Average -Variation $VariationResult.Average
    }

    $Params = @{
        ControlResult = $ControlResult
        VariationResult = $VariationResult
        Difference = $Difference
    }

    if ($Title) {
        $Params.Add('Title', $Title)
    }

    Start-RBResultDashboard @Params
}
