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
    * Decide whether to store answer with clue or in a dedicated hash table.
    * error checking, category is valid?
    * parameter validation scripts/dynamic valid sets?
        * Possible to have valid categories appear in intellisense?
    * Better answer validation, can currently supply a single letter as wildcards are used (does the answer contain an a?)
    * Answers should be returned in the form of a question.
       * Is this how we should roll in our variation of Jeopardy?
    * Show game state on completion of 'start-game' and answer a question has been answered/timed out, e.g.
        State Capitals: $200, $400, $X (already done), $800, $1000
        and so on for the other categories.
    * Find out if it possible to keep the prompt interactive while a progress bar is displayed?
        * Show clue count down (and current clue) in a progress bar.
    * Save all clues to disk. Make refreshing them a switch parameter on start-game cmdlet.
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
    [string] $answer;
    [uint64] $value;
    [uint64] $category_id;
    #endregion

    #region class constructors
    JeoClue ([uint64] $id, [string] $question, [string] $answer, [uint64] $value, [uint64] $category_id) {
        $this.id = $id
        $this.question = $question
        $this.answer = $answer
        $this.value = $value
        $this.category_id = $category_id
    }
    #endregion

    #region class methods
    #endregion
}

$GameCats = @() # The six categories used this round
$GameClues = @()
$offset = $null

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
            for ($x = 200; $x -le 1000; $x = $x + 200) {
                Write-Verbose -Message "Getting a clue from $category with value of $x"
                $uri = 'http://jservice.io/api/clues?value=' + $x + '&category=' + $category
                $clues = Invoke-WebRequest -Uri $uri | ConvertFrom-Json
                
                $tempClues = @()

                foreach ($clue in $clues) {
                    if ($clue.invalid_count -eq $null -or $clue.invalid_count -eq '') {
                        $JeoClue = [JeoClue]::new($clue.id, $clue.question, $clue.value, $clue.category_id)
                        $tempClues += $JeoClue
                    }
                }

                Write-Verbose -Message "Choosing a random valid clue."
                $clueRand = Get-Random -Minimum 0 -Maximum (($tempClues | Measure-Object).Count - 1)
                $tempAdd += $tempClues[$clueRand]
            }
            $Global:GameClues += $tempAdd
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
    Param ()

    Write-Verbose -Message 'Emptying game arrays.'
    $Global:GameCats = @()
    $Global:GameClues = @()

    for ($i = 1; $i -le 6; $i++) { 
        $Global:GameCats += Get-RandomCategory
    }

    $errors = @()

    foreach ($gameCat in $Global:GameCats) {
        $errors += Get-Clues -category $gameCat.id
    }

    if (($errors | Measure-Object).Count -ge 1) {
        foreach ($error in $errors) {
            Write-Warning -Message "A complete clue set for category $error could not be generated, choosing replacement category."
            Repair-ProblemCategory -category $error
        }
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
        [uint64] $Category,

        # Param2 help description
        [Parameter(Mandatory=$true,
                   Position=1)]
        [uint64] $Value
    )

    $Global:GameClues | Where-Object -FilterScript {$_.category_id -eq $category -and $_.value -eq $value}
}