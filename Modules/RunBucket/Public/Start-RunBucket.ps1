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
    $VariationResult = Start-TestCaseMeasurement -ScriptBlock $Variation -Throttle 25

    $Minimum = ($ControlResult.Minimum - $VariationResult.Minimum) / $ControlResult.Minimum
    $Maximum = ($ControlResult.Maximum - $VariationResult.Maximum) / $ControlResult.Maximum
    $Average = ($ControlResult.Average - $VariationResult.Average) / $ControlResult.Average

    [PSCustomObject] @{
        Minimum = $Minimum
        Maximum = $Maximum
        Average = $Average
    }

    $VariationResult = Start-TestCaseMeasurement -ScriptBlock $Variation -Throttle 25
    $ControlResult = Start-TestCaseMeasurement -ScriptBlock $Control -Throttle 25
    
    $Minimum = ($ControlResult.Minimum - $VariationResult.Minimum) / $ControlResult.Minimum
    $Maximum = ($ControlResult.Maximum - $VariationResult.Maximum) / $ControlResult.Maximum
    $Average = ($ControlResult.Average - $VariationResult.Average) / $ControlResult.Average

    [PSCustomObject] @{
        Minimum = $Minimum
        Maximum = $Maximum
        Average = $Average
    }
}