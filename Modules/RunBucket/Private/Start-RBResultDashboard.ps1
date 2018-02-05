function Start-RBResultDashboard {
    [CmdletBinding()]

    param (
        [PSCustomObject] $ControlResult,
        [PSCustomObject] $VariationResult
    )

    $Colors = @{
        BackgroundColor = "#FF252525"
        FontColor = "#FFFFFFFF"
    }

    Start-UDDashboard -Wait -Content {
        New-UDDashboard -Title 'RunBucket Test Results' -NavBarColor '#FF1c1c1c' -NavBarFontColor "#FF55b3ff" -BackgroundColor "#FF333333" -FontColor "#FFFFFF" -Content {
            New-UDRow {
                New-UDColumn -Size 4 {
                    New-UDCounter -Title 'Minimum (ms)' -Format '0,0.000' -Icon 'chevron_down' -TextAlignment center -BackgroundColor '#252525' -FontColor "#FFFFFF" -Endpoint {
                        0.2432 | ConvertTo-Json
                    }
                }
                New-UDColumn -Size 4 {
                    New-UDCounter -Title 'Minimum (ms)' -Format '0,0.000' -Icon 'chevron_down' -TextAlignment center -BackgroundColor '#252525' -FontColor "#FFFFFF" -Endpoint {
                        0.0972 | ConvertTo-Json
                    }
                }
                New-UDColumn -Size 4 {
                    New-UDCounter -Title 'Difference' -Format '(0.00 %)' -Icon 'percent' -TextAlignment center -BackgroundColor '#252525' -FontColor "#FFFFFF" -Endpoint {
                        0.0972 | ConvertTo-Json
                    }
                }
            }
            New-UDRow {
                New-UDColumn -Size 4 {
                    New-UDCounter -Title 'Maximum (ms)' -Format '0,0.000' -Icon 'chevron_up' -TextAlignment center -BackgroundColor '#252525' -FontColor "#FFFFFF" -Endpoint {
                        0.2432 | ConvertTo-Json
                    }
                }
                New-UDColumn -Size 4 {
                    New-UDCounter -Title 'Maximum (ms)' -Format '0,0.000' -Icon 'chevron_up' -TextAlignment center -BackgroundColor '#252525' -FontColor "#FFFFFF" -Endpoint {
                        0.0972 | ConvertTo-Json
                    }
                }
                New-UDColumn -Size 4 {
                    New-UDCounter -Title 'Difference' -Format '(0.00 %)' -Icon 'percent' -TextAlignment center -BackgroundColor '#252525' -FontColor "#FFFFFF" -Endpoint {
                        0.0972 | ConvertTo-Json
                    }
                }
            }
            New-UDRow {
                New-UDColumn -Size 4 {
                    New-UDCounter -Title 'Average (ms)' -Format '0,0.000' -Icon 'chevron_right' -TextAlignment center -BackgroundColor '#252525' -FontColor "#FFFFFF" -Endpoint {
                        0.2432 | ConvertTo-Json
                    }
                }
                New-UDColumn -Size 4 {
                    New-UDCounter -Title 'Average (ms)' -Format '0,0.000' -Icon 'chevron_right' -TextAlignment center -BackgroundColor '#252525' -FontColor "#FFFFFF" -Endpoint {
                        0.0972 | ConvertTo-Json
                    }
                }
                New-UDColumn -Size 4 {
                    New-UDCounter -Title 'Difference' -Format '(0.00 %)' -Icon 'percent' -TextAlignment center -BackgroundColor '#252525' -FontColor "#FFFFFF" -Endpoint {
                        0.0972 | ConvertTo-Json
                    }
                }
            }
        }
    }
}