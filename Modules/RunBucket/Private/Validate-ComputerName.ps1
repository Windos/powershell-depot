function Validate-ComputerName
{
    Param
    (
        [string] $ComputerName
    )

    if (Test-Connection $ComputerName -BufferSize 16 -Count 1)
    {
        $true
    }
    else
    {
        throw "The computer $ComputerName is either offline or does not " +
            'exist. Please check that the value is correct and try again.'
    }
}
