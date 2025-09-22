
$presetPath = Join-Path $PSScriptRoot "preset.txt"

$exeMap = @{
    "1" = "DeadByDaylight-Win64-Shipping.exe"   # Steam
    "2" = "DeadByDaylight-EGS-Shipping.exe"     # Epic
    "3" = "DeadByDaylight-WinGDK-Shipping.exe"  # Windows Store
}

$labelMap = @{
    "1" = "steam_dir"
    "2" = "epic_games_dir"
    "3" = "windows_store_dir"
}

$activeLabel = "active_dir"

# Initialize preset.txt if missing
if (-not (Test-Path $presetPath)) {
    Set-Content -Path $presetPath -Value @(
        "steam_dir ="
        "epic_games_dir ="
        "windows_store_dir ="
        ""
        "active_dir ="
    )
}

$presetLines = Get-Content $presetPath
if ($presetLines.Count -lt 5) {
    Write-Host "Malformed preset.txt. Reinitializing..."
    Set-Content -Path $presetPath -Value @(
        "steam_dir ="
        "epic_games_dir ="
        "windows_store_dir ="
        ""
        "active_dir ="
    )
    $presetLines = Get-Content $presetPath
}

Write-Host "Choose your DBD client:`n1. Steam`n2. Epic Games`n3. Windows Store"
$choice = Read-Host "Enter number (1-3)"
if ($choice -notin @("1", "2", "3")) {
    Write-Host "Invalid choice. Exiting." -ForegroundColor Red
    exit 1
}

$expectedExe = $exeMap[$choice]
$label = $labelMap[$choice]

function Get-LineIndex {
    param ($lines, $label)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^$label\s*=") {
            return $i
        }
    }
    return -1
}

$lineIndex = Get-LineIndex -lines $presetLines -label $label
if ($lineIndex -lt 0) {
    Write-Host "Label $label not found. Repairing preset.txt..."
    Set-Content -Path $presetPath -Value @(
        "steam_dir ="
        "epic_games_dir ="
        "windows_store_dir ="
        ""
        "active_dir ="
    )
    $presetLines = Get-Content $presetPath
    $lineIndex = Get-LineIndex -lines $presetLines -label $label
    if ($lineIndex -lt 0) {
        Write-Host "Failed to repair preset.txt. Aborting." -ForegroundColor Red
        exit 1
    }
}

function Test-ExePath {
    param ($fullPath, $expected)
    return (Test-Path $fullPath -PathType Leaf) -and ((Split-Path $fullPath -Leaf) -ieq $expected)
}

$currentEntry = $presetLines[$lineIndex] -replace "^$label\s*=\s*", ""
if ($currentEntry -and (Test-ExePath -fullPath $currentEntry -expected $expectedExe)) {
    $presetLines[-1] = "$activeLabel = $currentEntry"
    $presetLines | Set-Content -Path $presetPath
    Write-Host "Using saved path: $currentEntry"
    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\main.ps1`"" -WindowStyle Normal
    exit
}

while ($true) {
    $inputPath = Read-Host "Enter full path to $expectedExe"
    if (Test-ExePath -fullPath $inputPath -expected $expectedExe) {
        $presetLines[$lineIndex] = "$label = $inputPath"
        $presetLines[-1] = "$activeLabel = $inputPath"
        $presetLines | Set-Content -Path $presetPath
        Write-Host "Saved and using: $inputPath"
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\main.ps1`"" -WindowStyle Normal
        break
    } else {
        Write-Host "Path invalid or wrong executable. Expected: $expectedExe" -ForegroundColor Red
    }
}
