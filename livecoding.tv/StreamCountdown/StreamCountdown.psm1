function Start-Stream {
    $loading = @('Waiting for Windos to hit enter',
                 'Warming up processors', 
                 'Downloading the internet', 
                 'Trying common passwords', 
                 'Commencing infinite loop', 
                 'Injecting double negatives', 
                 'Breeding bits', 
                 'Capturing escaped bits', 
                 'Dreaming of a faster computer', 
                 'Calculating gravitational constant', 
                 'Adding Hidden Agendas', 
                 'Adjusting Bell Curves', 
                 'Aligning Covariance Matrices', 
                 'Attempting to Lock Back-Buffer', 
                 'Building Data Trees', 
                 'Calculating Inverse Probability Matrices', 
                 'Calculating Llama Expectoration Trajectory', 
                 'Compounding Inert Tessellations', 
                 'Concatenating Sub-Contractors', 
                 'Containing Existential Buffer', 
                 'Deciding What Message to Display Next', 
                 'Increasing Accuracy of RCI Simulators', 
                 'Perturbing Matrices')

    $startTime = Get-Date
    $endTime = $startTime.AddMinutes(5)
    $totalSeconds = (New-TimeSpan -Start $startTime -End $endTime).TotalSeconds

    $totalSecondsChild = Get-Random -Minimum 4 -Maximum 30
    $startTimeChild = $startTime
    $endTimeChild = $startTimeChild.AddSeconds($totalSecondsChild)
    $loadingMessage = $loading[(Get-Random -Minimum 0 -Maximum ($loading.Length - 1))]


    Do {
        $now = Get-Date
        $secondsElapsed = (New-TimeSpan -Start $startTime -End $now).TotalSeconds
        $secondsRemaining = $totalSeconds - $secondsElapsed
        $percentDone = ($secondsElapsed / $totalSeconds) * 100

        Write-Progress -id 0 -Activity Start-Stream -Status 'Stream starting soon' -PercentComplete $percentDone -SecondsRemaining $secondsRemaining

        $secondsElapsedChild = (New-TimeSpan -Start $startTimeChild -End $now).TotalSeconds
        $secondsRemainingChild = $totalSecondsChild - $secondsElapsedChild
        $percentDoneChild = ($secondsElapsedChild / $totalSecondsChild) * 100

        Write-Progress -id 1 -ParentId 0 -Activity $loadingMessage -PercentComplete $percentDoneChild -SecondsRemaining $secondsRemainingChild

        if ($percentDoneChild -ge 100 -and $percentDone -le 98) {
            $totalSecondsChild = Get-Random -Minimum 4 -Maximum 30
            $startTimeChild = $now
            $endTimeChild = $startTimeChild.AddSeconds($totalSecondsChild)
            if ($endTimeChild -gt $endTime) {
                $endTimeChild = $endTime
            }
            $loadingMessage = $loading[(Get-Random -Minimum 0 -Maximum ($loading.Length - 1))]
        }

        Start-Sleep 0.2
    } Until ($now -ge $endTime)
}