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

	$Runtime = [System.Diagnostics.Stopwatch]::StartNew()
	$ControlResult = Start-TestCaseMeasurement -ScriptBlock $Control -Throttle 25 -Iterations $Iterations
    Start-Sleep -Milliseconds 50
    $VariationResult = Start-TestCaseMeasurement -ScriptBlock $Variation -Throttle 25 -Iterations $Iterations
	$Runtime.Stop()
	
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

	$ToastTitle = 'RunBucket Finished'
	
    if ($Title) {
        $Params.Add('Title', $Title)
		$ToastTitle += ":`n$Title"
    }

    Start-RBResultDashboard @Params
	
	$AppLogo = Get-ChildItem -Path $PSScriptRoot\..\Media\Stopwatch.png
	$RuntimeText = 'All tests completed in {0} seconds' -f [Math]::Round($Runtime.Elapsed.TotalSeconds, 2)
	
	New-BurntToastNotification -AppLogo $AppLogo -Text $ToastTitle, $RuntimeText -Sound Alarm
}
