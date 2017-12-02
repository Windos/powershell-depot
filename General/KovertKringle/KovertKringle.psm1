$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

Foreach($Import in @($Public + $Private))
{
    Try
    {
        . $Import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($Import.fullname): $_"
    }
}

$Script:Participants = [System.Collections.ArrayList]::new()

Export-ModuleMember -Function $Public.Basename
