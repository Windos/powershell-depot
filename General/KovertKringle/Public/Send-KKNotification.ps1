function Send-KKNotification {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    # Get your credentials
    $Cred = Get-StoredCredential -Target SendGrid
    $SmtpServer = 'smtp.sendgrid.net'
    $FromEmail = 'windosbk+sendgrid@gmail.com'
    $Subject = 'Your Secret Santa Pairing!'
    $BCC = ($Script:Participants | where {$_.Snitch}).Email

    foreach ($Pair in $Script:Pairings) {
        $Body = '{0}, you are buying a Secret Santa gift for {1}! Remeber the limit is $20.' -f $Pair.Buyer.Name, $Pair.Receiver.Name
        $ToEmail = $Pair.Buyer.Email

        $Splat = @{
            SmtpServer = $SmtpServer
            Credential = $Cred
            Body = $Body
            Subject = $Subject
            To = $ToEmail
            From = $FromEmail
        }

        if ($BCC) {
            $Splat.Add('Bcc', $BCC)
        }

        Send-MailMessage @Splat
    }
}
