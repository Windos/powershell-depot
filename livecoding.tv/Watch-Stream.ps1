function Validate-Streamer ($streamer)
{
    if ($streamer -eq $false)
    {
        $true
    }
    else
    {
        throw "$streamer is not currently streaming. Please press follow to be notified when they are next live, or check the Livecoding.tv streaming schedule."
    }
}

function Watch-Stream
{
    Param
    (
        [ValidateScript({Validate-Streamer $_})]
        [string] $Streamer,

        [string] $Service
    )
}