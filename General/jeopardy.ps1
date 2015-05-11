#region LICENSE

# The MIT License (MIT)
# 
# Copyright (c) 2015 Joshua King
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy 
# of this software and associated documentation files (the "Software"), to deal 
# in the Software without restriction, including without limitation the rights to 
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
# of the Software, and to permit persons to whom the Software is furnished to do 
# so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all 
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
# SOFTWARE.

#endregion

<#
    ToDo:
    * Complete comment based help. Will do this during a lazy lunch hour stream.
    * Better answer validation, can currently supply a single letter as wildcards are used (does the answer contain an a?)
    * Answers should be returned in the form of a question.
       * Is this how we should roll in our variation of Jeopardy?
    * Show game state on completion of 'start-game' and answer a question has been answered/timed out, e.g.
        State Capitals: $200, $400, $X (already done), $800, $1000
        and so on for the other categories.
    * Find out if it possible to keep the prompt interactive while a progress bar is displayed?
        * Show clue count down (and current clue) in a progress bar.
        * # Might be a bit hacky if it's even possible. #
    * store current clue in memory, user doesn't need to supply category and value when answering
    * change request to take a string: Request-JeoClue "State Capitals for $200"
    * show user what the answer was when clue times out
    * consider using events to perform an ction automatically on time out rather than waiting for the user to submit an answer.
    * check that clues do not have a blank question.
#>

class JeoCategory {
    #region class properties
    [uint64] $id;
    [string] $title;
    [uint64] $clues_count;
    #endregion

    #region class constructors
    JeoCategory ([uint64] $id, [string] $title, [uint64] $clues_count) {
        $this.id = $id
        $this.title = $title
        $this.clues_count = $clues_count
    }
    #endregion

    #region class methods
    #endregion
}

class JeoClue {
    #region class properties
    [uint64] $id;
    [string] $question;
    [uint64] $value;
    [uint64] $category_id;
    [bool] $alreadyDone;
    #endregion

    #region class constructors
    JeoClue ([uint64] $id, [string] $question, [uint64] $value, [uint64] $category_id) {
        $this.id = $id
        $this.question = $question
        $this.value = $value
        $this.category_id = $category_id
        $this.alreadyDone = $false
    }
    #endregion

    #region class methods
    #endregion
}



$AllGameCats = @()
$GameCats = @()
$GameClues = @()
$answers = @{}
$offset = $null

#region HelperFunctions

function Validate-Category {
    <#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
    .LINK
    https://github.com/Windos/powershell-depot/tree/master/General
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [int] $Category
    )

    $valid = $false

    foreach ($gameCat in $Global:GameCats) {
        if ($gameCat.Id -eq $Category) {
            $valid = $true
        }
    }

    if ($valid) {
        $valid
    } else {
        throw "$Category is not a valid category ID for this game."
    }
}

#endregion

function Get-AllCategories {
<#
    .Synopsis
    Gets all Jeopardy categories from jservice.io
    .DESCRIPTION
    The Get-AllCategories cmdlet gets all of the Jeopardy categories available on jservice.io. Categories containing ten or more clues are stored for later use in $AllGameCats.
    .EXAMPLE
    Get-AllCategories
    
    This command returns all categories on jservice.io
    .EXAMPLE
    Get-AllCategories -Offset 12345
    
    This command returns all categories on jservice.io starting from the category after Id 12345.
    .LINK
    https://github.com/Windos/powershell-depot/tree/master/General
#>
    [CmdletBinding()]
    Param
    (
        # From jservice.io: offsets the starting id of categories returned. Useful in pagination.
        [Parameter(Mandatory=$false,
                   Position=0)]
        [uint64] $Offset
    )

    if ($offset -eq $null) {
        Write-Verbose -Message 'Getting first page of categories from jservice.io'
        $cats = Invoke-WebRequest -Uri 'http://jservice.io/api/categories?count=100' | ConvertFrom-Json
    } else {
        Write-Verbose -Message "Getting page of categories, offset to category ID $offset"
        $uri = 'http://jservice.io/api/categories?count=100&offset=' + $offset
        $cats = Invoke-WebRequest -Uri $uri | ConvertFrom-Json
    }

    foreach ($cat in $cats) {
        if ($cat.clues_count -ge 10) {
            $JeoCat = [JeoCategory]::new($cat.id, $cat.title, $cat.clues_count)
            $Global:AllGameCats += $JeoCat
        }
    }
    
    $catsReturned = ($cats | Measure-Object).Count
    if ($catsReturned -eq 100) {
        Write-Verbose -Message 'Another page of categories are available.'
        Get-AllCategories -offset ($cats[-1].id)
    }

    $savePath = Join-Path -Path (Split-Path $profile) -ChildPath JeopardyCategories.csv
    $Global:AllGameCats | Export-csv -Path $savePath
}

function Get-RandomCategory {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
    .LINK
    https://github.com/Windos/powershell-depot/tree/master/General
#>
    [CmdletBinding()]
    [OutputType([JeoCategory])]

    $catRand = Get-Random -Minimum 0 -Maximum (($Global:AllGameCats | Measure-Object).Count - 1)
    $Global:AllGameCats[$catRand]
}

function Get-Clues {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
    .LINK
    https://github.com/Windos/powershell-depot/tree/master/General
#>
    [CmdletBinding()]
    Param (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [int] $Category
    )

    begin {}
    process {
        try {
            $tempAdd = @()
            $tempAnsAdd = @{}
            for ($x = 200; $x -le 1000; $x = $x + 200) {
                Write-Verbose -Message "Getting a clue from $category with value of $x"
                $uri = 'http://jservice.io/api/clues?value=' + $x + '&category=' + $category
                $clues = Invoke-WebRequest -Uri $uri | ConvertFrom-Json
                
                $tempClues = @()
                $tempAns = @{}

                foreach ($clue in $clues) {
                    if ($clue.invalid_count -eq $null -or $clue.invalid_count -eq '') {
                        $JeoClue = [JeoClue]::new($clue.id, $clue.question, $clue.value, $clue.category_id)
                        $tempClues += $JeoClue
                        $tempAns.Add($clue.id.ToString(), $clue.answer)
                    }
                }

                Write-Verbose -Message "Choosing a random valid clue."
                $clueRand = Get-Random -Minimum 0 -Maximum (($tempClues | Measure-Object).Count - 1)
                $tempAdd += $tempClues[$clueRand]
                
                $key = ($tempClues[$clueRand]).id.ToString()
                $value = $tempAns.($key)
                $tempAnsAdd.Add($key,$value)
            }
            $Global:GameClues += $tempAdd
            $Global:answers += $tempAnsAdd
        } catch {
            Write-Verbose -Message "$category did not contain a full set of valid clues."
            $category
        }
    }
    end {}
}

function Start-Game {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
    .LINK
    https://github.com/Windos/powershell-depot/tree/master/General
#>
    [CmdletBinding(HelpUri = 'https://github.com/Windos/powershell-depot/tree/master/General')]
    Param ([switch] $RefreshCategories)

    Write-Verbose -Message 'Emptying game arrays.'
    $Global:GameCats = @()
    $Global:GameClues = @()

    $loadPath = Join-Path -Path (Split-Path $profile) -ChildPath JeopardyCategories.csv
    if ($RefreshCategories) {
        Write-Verbose 'Refresh'
        $AllGameCats = @()
        Get-AllCategories
    } elseif (($Global:AllGameCats | Measure-Object).Count -eq 0) {
        Write-Verbose 'Array empty'
        if ((Test-Path -Path $loadPath)) {
            Write-Verbose 'Loading from disk'
            $Global:AllGameCats = Import-Csv -Path $loadPath
        } else {
            Write-Verbose 'loading from api'
            Get-AllCategories
        }
    } else { Write-Verbose 'array not empty' }

    # But, it needs to be tested.
    
    
    if ((Test-Path -Path $loadPath)) {
        $Global:AllGameCats = Import-Csv -Path $loadPath
    } else {
        Get-AllCategories
    }
    

    for ($i = 1; $i -le 6; $i++) {
        $newCat = Get-RandomCategory
        while ($newCat -in $Global:GameCats) {
            $newCat = Get-RandomCategory
        }
        $Global:GameCats += $newCat
    }

    foreach ($gameCat in $Global:GameCats) {
        Write-Debug "Getting clues for $($gameCat.id)"
        $error += Get-Clues -category $gameCat.id
    }

    if ($error -ge 1) {
		Write-Warning -Message "A complete clue set for category $error could not be generated, choosing replacement category."
		Repair-ProblemCategory -category $error
    }
}

function Repair-ProblemCategory {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
    .LINK
    https://github.com/Windos/powershell-depot/tree/master/General
#>
    [CmdletBinding()]
    Param (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   Position=0)]
        [int] $Category
    )

    $newGameCats = @()
    foreach ($cat in $Global:GameCats) {
        if ($cat.id -ne $category) {
            $newGameCats += $cat
        }
    }
    $Global:GameCats = $newGameCats
    $newCat = Get-RandomCategory
	while ($newCat -in $Global:GameCats) {
        $newCat = Get-RandomCategory
    }
    $Global:GameCats += $newCat
    $moreErrors = Get-Clues -category $newCat.id
    if (($moreErrors | Measure-Object).Count -ge 1) {
        Repair-ProblemCategory -category $newCat.id
    }
}

function Request-JeoClue {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
    .LINK
    https://github.com/Windos/powershell-depot/tree/master/General
#>
    [CmdletBinding()]
    Param (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateScript({ Validate-Category -Category $_ })]
        [uint64] $Category,

        # Param2 help description
        [Parameter(Mandatory=$true,
                   Position=1)]
        [uint64] $Value
    )

    $NewClue = $Global:GameClues | Where-Object -FilterScript {$_.category_id -eq $category -and $_.value -eq $value}
    if ($NewClue.alreadyDone) {
		Write-Output 'This clue has already been done, try another.'
	} else {
	    if ((Get-job -name 'ClueCountdown' -ErrorAction SilentlyContinue) -eq $null) {
			Start-Job -Name "ClueCountdown" -ScriptBlock { Start-Sleep -Seconds 60 } | Out-Null
			$NewClue.Question
        } elseif ((Get-job -name 'ClueCountdown').State -eq 'Completed') {
            Get-job -name 'ClueCountdown' | Remove-Job
            Write-Output 'Previous clue timed out, please request a new one.'
        } else {
            Write-Output "You've already requested a clue and have time to answer it."

        }
    }
}

function Answer-JeoClue {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
    .LINK
    https://github.com/Windos/powershell-depot/tree/master/General
#>
    [CmdletBinding()]
    Param (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateScript({ Validate-Category -Category $_ })]
        [uint64] $Category,

        # Param2 help description
        [Parameter(Mandatory=$true,
                   Position=1)]
        [uint64] $Value,

        # Param3 help description
        [Parameter(Mandatory=$true,
                   Position=3)]
        [string] $Answer
    )
	
	$CurrentClue = $Global:GameClues | Where-Object -FilterScript {$_.category_id -eq $category -and $_.value -eq $value}
	$realAnswer = $Global:answers.($CurrentClue.id.ToString())


    if ((Get-job -name 'ClueCountdown').State -ne 'Completed') {
        if ($realAnswer -like "*$answer*") {

            Write-Output 'Correct'
            Get-job -name 'ClueCountdown' | Stop-Job | Remove-Job
			$CurrentClue.alreadyDone = $true
        } else {
            Write-Output 'Try again'
        }

    } else {
        Write-Output 'Too late'
        Get-job -name 'ClueCountdown' | Remove-Job
		$CurrentClue.alreadyDone = $true
    }
}
