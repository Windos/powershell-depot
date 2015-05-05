class Category {
    #region class properties
    [uint64] $id;
    [string] $title;
    [uint64] $clues_count;
    #endregion

    #region class constructors
    Category ([uint64] $id, [string] $title, [uint64] $clues_count) {
        $this.id = $id
        $this.title = $title
        $this.clues_count = $clues_count
    }
    #endregion

    #region class methods
    #endregion
}

class Clue {
    #region class properties
    [uint64] $id;
    [string] $question;
    [uint64] $value;
    [uint64] $category_id;
    #endregion

    #region class constructors
    Clue ([uint64] $id, [string] $question, [uint64] $value, [uint64] $category_id) {
        $this.id = $id
        $this.question = $question
        $this.value = $value
        $this.category_id = $category_id
    }
    #endregion

    #region class methods
    #endregion
}

#$AllGameCats = @()
$GameCats = @() # The six categories used this round
$GameClues = @()
$offset = $null

function Get-AllCategories {
    param ([uint64] $offset)

    if ($offset -eq $null) {
        $cats = Invoke-WebRequest -Uri 'http://jservice.io/api/categories?count=100' | ConvertFrom-Json
    } else {
        $uri = 'http://jservice.io/api/categories?count=100&offset=' + $offset
        $cats = Invoke-WebRequest -Uri $uri | ConvertFrom-Json
    }

    foreach ($cat in $cats) {
        if ($cat.clues_count -ge 10) {
            $JeoCat = [Category]::new($cat.id, $cat.title, $cat.clues_count)
            $Global:AllGameCats += $JeoCat
        }
    }
    
    $catsReturned = ($cats | Measure-Object).Count
    if ($catsReturned -eq 100) {
        GetAllCategories -offset ($cats[-1].id)
    }
}

function Get-RandomCategory {
    $catRand = Get-Random -Minimum 0 -Maximum (($Global:AllGameCats | Measure-Object).Count - 1)
    $Global:AllGameCats[$catRand]
}

function Get-Clues {
    param ([int] $category)
    try {
        $tempAdd = @()
        for ($x = 200; $x -le 1000; $x = $x + 200) {
            $uri = 'http://jservice.io/api/clues?value=' + $x + '&category=' + $category
            $clues = Invoke-WebRequest -Uri $uri | ConvertFrom-Json
            
            $tempClues = @()

            foreach ($clue in $clues) {
                if ($clue.invalid_count -eq $null -or $clue.invalid_count -eq '') {
                    $JeoClue = [Clue]::new($clue.id, $clue.question, $clue.value, $clue.category_id)
                    $tempClues += $JeoClue
                }
            }

            $clueRand = Get-Random -Minimum 0 -Maximum (($tempClues | Measure-Object).Count - 1)
            $tempAdd += $tempClues[$clueRand]
        }
        $Global:GameClues += $tempAdd
    } catch {
        $category
    }
}

function Start-Game {
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
            Repair-ProblemCategory -category $error
        }
    }
}

function Repair-ProblemCategory {
    param ([int] $category)

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
        Write-Host "Error on $($newCat.id)"
        Repair-ProblemCategory -category $newCat.id
    }
}

function Request-JeoClue {
    param ([uint64] $category, [uint64] $value)

    $Global:GameClues | Where-Object -FilterScript {$_.category_id -eq $category -and $_.value -eq $value}
}