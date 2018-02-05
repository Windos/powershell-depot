function Start-RBResultDashboard {
    [CmdletBinding()]

    param (
        [Parameter(Mandatory)]
        [PSCustomObject] $ControlResult,
        
        [Parameter(Mandatory)]
        [PSCustomObject] $VariationResult,

        [Parameter(Mandatory)]
        [PSCustomObject] $Difference
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
                        $ControlResult.Minimum | ConvertTo-Json
                    }
                }
                New-UDColumn -Size 4 {
                    New-UDCounter -Title 'Minimum (ms)' -Format '0,0.000' -Icon 'chevron_down' -TextAlignment center -BackgroundColor '#252525' -FontColor "#FFFFFF" -Endpoint {
                        $VariationResult.Minimum | ConvertTo-Json
                    }
                }
                New-UDColumn -Size 4 {
                    if ($Difference.Minimum -lt 0) {
                        $BgColour = '#006400'
                    } else {
                        $BgColour = '#8B0000'
                    }

                    New-UDCounter -Title 'Difference' -Format '0.00 %' -Icon 'percent' -TextAlignment center -BackgroundColor $BgColour -FontColor "#FFFFFF" -Endpoint {
                        $Difference.Minimum | ConvertTo-Json
                    }
                }
            }
            New-UDRow {
                New-UDColumn -Size 4 {
                    New-UDCounter -Title 'Maximum (ms)' -Format '0,0.000' -Icon 'chevron_up' -TextAlignment center -BackgroundColor '#252525' -FontColor "#FFFFFF" -Endpoint {
                        $ControlResult.Maximum | ConvertTo-Json
                    }
                }
                New-UDColumn -Size 4 {
                    New-UDCounter -Title 'Maximum (ms)' -Format '0,0.000' -Icon 'chevron_up' -TextAlignment center -BackgroundColor '#252525' -FontColor "#FFFFFF" -Endpoint {
                        $VariationResult.Maximum | ConvertTo-Json
                    }
                }
                New-UDColumn -Size 4 {
                    if ($Difference.Maximum -lt 0) {
                        $BgColour = '#006400'
                    } else {
                        $BgColour = '#8B0000'
                    }

                    New-UDCounter -Title 'Difference' -Format '0.00 %' -Icon 'percent' -TextAlignment center -BackgroundColor $BgColour -FontColor "#FFFFFF" -Endpoint {
                        $Difference.Maximum | ConvertTo-Json
                    }
                }
            }
            New-UDRow {
                New-UDColumn -Size 4 {
                    New-UDCounter -Title 'Average (ms)' -Format '0,0.000' -Icon 'chevron_right' -TextAlignment center -BackgroundColor '#252525' -FontColor "#FFFFFF" -Endpoint {
                        $ControlResult.Average | ConvertTo-Json
                    }
                }
                New-UDColumn -Size 4 {
                    New-UDCounter -Title 'Average (ms)' -Format '0,0.000' -Icon 'chevron_right' -TextAlignment center -BackgroundColor '#252525' -FontColor "#FFFFFF" -Endpoint {
                        $VariationResult.Average | ConvertTo-Json
                    }
                }
                New-UDColumn -Size 4 {
                    if ($Difference.Average -lt 0) {
                        $BgColour = '#006400'
                    } else {
                        $BgColour = '#8B0000'
                    }

                    New-UDCounter -Title 'Difference' -Format '0.00 %' -Icon 'percent' -TextAlignment center -BackgroundColor $BgColour -FontColor "#FFFFFF" -Endpoint {
                        $Difference.Average | ConvertTo-Json
                    }
                }
            }
        }
    }
}