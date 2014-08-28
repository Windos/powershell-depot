# Code signing function
function sign ($filename)
{
    $cert = @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)[0]
    Set-AuthenticodeSignature $filename $cert
}

# Voice output function
$voice = New-Object -ComObject SAPI.SPVoice
$voice.Rate = 2

function Invoke-Speech
{
    param([Parameter(ValueFromPipeline=$true)][string] $say)

    process
	{
        $voice.Speak($say) | out-null;    
    }
}

New-Alias -name Out-Voice -value Invoke-Speech;

# Custom prompt with history marker
function prompt
{
    $history = @(get-history)

    if($history.Count -gt 0)
	{
        $lastItem = $history[$history.Count - 1]
        $lastId = $lastItem.Id
    }

    $nextCommand = $lastId + 1
    $currentDirectory = get-location

    "[$nextCommand] PS $currentDirectory> "
}

cd \
