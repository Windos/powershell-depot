$TSPath = Join-Path (Split-Path $profile) 'timesheet.csv'

class TSEntry {
    #region properties
    [string] $Name
    [datetime] $Time
    [string] $Activity
    #endregion

    #region constructors
    TSEntry([string] $Name, [datetime] $Time, [string] $Activity) {
        $this.Name = $Name
        $this.Time = $Time
        $this.Activity = $Activity
    }
    #endregion

    #region methods

    #endregion
}

function New-TSEntry {
    Add-Type -AssemblyName Microsoft.VisualBasic # The input box object comes care of VisualBasic

    $TSPrompt = 'What are you working on?'
    $TSTitle = 'Timesheet'
    $TSDefault = ''

    $entry = [Microsoft.VisualBasic.Interaction]::InputBox($TSPrompt, $TSTitle, $TSDefault)

    $result = [TSEntry]::new($env:USERNAME, (Get-Date), $entry)

    $result | Export-Csv -Path $TSPath -Append
}

function New-TSReport {
    $reportDate = (get-date).AddDays(-7)
    $timesheet = Import-Csv -Path $TSPath

    foreach ($entry in $timesheet) {
        $time = Get-Date $entry.Time

        if ($time -ge $reportDate) {
            $entry = [TSEntry]::new($entry.name, $time, $entry.Activity)
            $entry
        }
    }
}

while ($true) {
    New-TSEntry
    Start-Sleep -Seconds 3600
}
