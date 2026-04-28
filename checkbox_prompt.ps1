$title = $env:CHECKBOX_TITLE
$minimum = [int]$env:CHECKBOX_MINIMUM
$options = @()

if ($env:CHECKBOX_OPTIONS) {
  $options = $env:CHECKBOX_OPTIONS -split ';'
}

if ($options.Count -eq 0) {
  Write-Error 'No checkbox options were provided.'
  exit 1
}

$selected = New-Object bool[] $options.Count
$cursor = 0
$message = ''

function Render-Menu {
  Clear-Host
  Write-Host $title
  Write-Host 'Use Up/Down arrows to move, Space to toggle, Enter to confirm.'
  Write-Host "Minimum selections: $minimum"

  for ($i = 0; $i -lt $options.Count; $i++) {
    $pointer = ' '
    if ($i -eq $cursor) {
      $pointer = '>'
    }

    $marker = '[ ]'
    if ($selected[$i]) {
      $marker = '[x]'
    }

    Write-Host "$pointer $marker $($options[$i])"
  }

  if ($message) {
    Write-Host $message
  }
}

Render-Menu

while ($true) {
  $key = [Console]::ReadKey($true)

  switch ($key.Key) {
    ([ConsoleKey]::UpArrow) {
      $cursor--
      if ($cursor -lt 0) {
        $cursor = $options.Count - 1
      }
      $message = ''
    }
    ([ConsoleKey]::DownArrow) {
      $cursor++
      if ($cursor -ge $options.Count) {
        $cursor = 0
      }
      $message = ''
    }
    ([ConsoleKey]::Spacebar) {
      $selected[$cursor] = -not $selected[$cursor]
      $message = ''
    }
    ([ConsoleKey]::Enter) {
      $selectedCount = 0
      foreach ($item in $selected) {
        if ($item) {
          $selectedCount++
        }
      }

      if ($selectedCount -ge $minimum) {
        break
      }

      $message = "Select at least $minimum option(s) before confirming."
    }
    ([ConsoleKey]::K) {
      $cursor--
      if ($cursor -lt 0) {
        $cursor = $options.Count - 1
      }
      $message = ''
    }
    ([ConsoleKey]::J) {
      $cursor++
      if ($cursor -ge $options.Count) {
        $cursor = 0
      }
      $message = ''
    }
  }

  Render-Menu
}

$result = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $options.Count; $i++) {
  if ($selected[$i]) {
    [void]$result.Add($options[$i])
  }
}

Write-Output ($result -join ' ')
