function Start-RunBucket {
    [CmdletBinding()]

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
}