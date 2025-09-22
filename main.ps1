# Auto-elevate to Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $escapedPath = "`"$PSCommandPath`""
    $arguments = "-ExecutionPolicy Bypass -File $escapedPath"
    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
    Start-Sleep -Seconds 1
    exit
}

Write-Host "== DEBUG =="
Write-Host "BlockRegion: $BlockRegion"
Write-Host "GameExe: $GameExe"

if ($BlockRegion -and $GameExe) {
    Write-Host "== BLOCK MODE TRIGGERED =="
    Write-Host "Region: $BlockRegion"
    Write-Host "Exe: $GameExe"
    Add-BlockRules -RegionCode $BlockRegion -GameExePath $GameExe -RuleNamePrefix $ruleNamePrefix -RegionCodesDir $RegionCodesDir
    exit
}

# Load Windows Forms for pop-up dialogs
Add-Type -AssemblyName System.Windows.Forms

# Script Paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RegionCodesDir = Join-Path $ScriptDir "..\Region Codes"
$awsJsonPath = Join-Path $RegionCodesDir "ip-ranges.json"
$presetFile = Join-Path $ScriptDir "preset.txt"
$logDir = Join-Path $ScriptDir "..\Logs"
$crashLogFile = Join-Path $logDir "crashlog_$(Get-Date -Format 'ddMMyy_HHmmss').txt"

function Update-IpRanges {
    $results = @()
    $totalRegions = 0
    $totalIPs = 0

    if (-not (Test-Path $RegionCodesDir)) {
        New-Item -ItemType Directory -Path $RegionCodesDir -Force | Out-Null
    }
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    Invoke-WebRequest -Uri "https://ip-ranges.amazonaws.com/ip-ranges.json" -OutFile $awsJsonPath
    $ipData = Get-Content $awsJsonPath | ConvertFrom-Json

    $targetRegions = $regionMap.Keys
    foreach ($regionCode in $targetRegions) {
        $prefixes = $ipData.prefixes | Where-Object { $_.region -eq $regionCode } | Select-Object -ExpandProperty ip_prefix
        $outFile = Join-Path $RegionCodesDir "$regionCode.txt"
        $prefixes | Set-Content -Path $outFile
        $regionName = $regionMap[$regionCode]
        $results += [PSCustomObject]@{
            Region      = $regionName
            IPCount     = $prefixes.Count
            RegionCode  = "$regionCode.txt"
        }
        $totalRegions++
        $totalIPs += $prefixes.Count
    }

    $results = $results | Sort-Object -Property IPCount -Descending

    $table = @()
    $table += "#  | REGION                        | IPs    | Region Code File"
    $table += "---+-------------------------------+--------+-------------------"

    $logLines = @()

    for ($i = 0; $i -lt $results.Count; $i++) {
        $line = "{0,2} | {1,-29} | {2,6} | {3}" -f ($i + 1), $results[$i].Region, $results[$i].IPCount, $results[$i].RegionCode
        $table += $line
        $logLines += "{0} | {1}" -f ($results[$i].RegionCode -replace ".txt$", ""), $results[$i].IPCount
    }

    $table += ""
    $table += "$totalIPs IP Ranges Added across $totalRegions regions."

    $formatted = ($table -join "`r`n")

    # Save summary to Region Codes directory
    $statFilePath = Join-Path $RegionCodesDir "iprange_stat.txt"
    $logLines += ""
    $logLines += "$totalIPs IP Ranges Added across $totalRegions regions."
    $logLines | Set-Content -Path $statFilePath

    $form = New-Object Windows.Forms.Form
    $form.Text = "Update Complete"
    $form.Width = 1000
    $form.Height = 700
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $form.ForeColor = [System.Drawing.Color]::White

    $textBox = New-Object Windows.Forms.TextBox
    $textBox.Multiline = $true
    $textBox.ScrollBars = "Vertical"
    $textBox.Dock = "Fill"
    $textBox.ReadOnly = $true
    $textBox.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $textBox.ForeColor = [System.Drawing.Color]::White
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 15)
    $textBox.Text = $formatted

    $form.Controls.Add($textBox)
    $null = $form.ShowDialog()
}

$regionMap = @{
    "us-east-1" = "US East (N. Virginia)"
    "us-east-2" = "US East (Ohio)"
    "us-west-1" = "US West (N. California)"
    "us-west-2" = "US West (Oregon)"
    "af-south-1" = "Africa (Cape Town)"
    "ap-southeast-7" = "Asia Pacific (Thailand)"
    "ap-east-1" = "Asia Pacific (Hong Kong)"
    "ap-southeast-5" = "Asia Pacific (Malaysia)"
    "ap-south-1" = "Asia Pacific (Mumbai)"
    "ap-northeast-3" = "Asia Pacific (Osaka)"
    "ap-northeast-2" = "Asia Pacific (Seoul)"
    "ap-southeast-1" = "Asia Pacific (Singapore)"
    "ap-southeast-2" = "Asia Pacific (Sydney)"
    "ap-northeast-1" = "Asia Pacific (Tokyo)"
    "ca-central-1" = "Canada (Central)"
    "eu-central-1" = "Europe (Frankfurt)"
    "eu-west-1" = "Europe (Ireland)"
    "eu-west-2" = "Europe (London)"
    "eu-south-1" = "Europe (Milan)"
    "eu-west-3" = "Europe (Paris)"
    "eu-north-1" = "Europe (Stockholm)"
    "me-south-1" = "Middle East (Bahrain)"
    "sa-east-1" = "South America (Sao Paulo)"
}

$regionPages = @(
    @("us-east-1", "us-east-2", "us-west-1", "us-west-2", "af-south-1", "ap-southeast-7"),
    @("ap-east-1", "ap-southeast-5", "ap-south-1", "ap-northeast-3", "ap-northeast-2", "ap-southeast-1"),
    @("ap-southeast-2", "ap-northeast-1", "ca-central-1", "eu-central-1", "eu-west-1", "eu-west-2"),
    @("eu-south-1", "eu-west-3", "eu-north-1", "me-south-1", "sa-east-1")
)

function Save-Preset($path) {
    Set-Content -Path $presetFile -Value "<game dir> = $path"
}
function Get-ValidGameExe {
    if (-not (Test-Path $presetFile)) {
        Write-Host "preset.txt not found. Please run getdir.ps1 first." -ForegroundColor Red
        return $null
    }

    $lines = Get-Content $presetFile
    foreach ($line in $lines) {
        if ($line -match "^active_dir\s*=\s*(.+)$") {
            $gameExe = $Matches[1].Trim()
            if (Test-Path $gameExe -PathType Leaf) {
                return $gameExe
            } else {
                Write-Host "The path set in 'active_dir' is invalid or missing. Please run getdir.ps1 to fix it." -ForegroundColor Red
                return $null
            }
        }
    }

    Write-Host "'active_dir' not found in preset.txt. Please run getdir.ps1 first." -ForegroundColor Red
    return $null
}

function Get-LatestLogFile {
    $statFile = Join-Path $RegionCodesDir "iprange_stat.txt"
    if (Test-Path $statFile) {
        return Get-Item $statFile
    } else {
        return $null
    }
}

function Read-LogData($logPath) {
    $map = @{}
    Get-Content $logPath | ForEach-Object {
        if ($_ -match "^(\S+)\s+\|\s+(\d+)$") {
            $map[$matches[1]] = [int]$matches[2]
        }
    }
    return $map
}

function Block-Regions {
    $gameExe = Get-ValidGameExe
    if (-not $gameExe) {
        Write-Host "Could not determine game executable. Aborting." -ForegroundColor Red
        return
    }

    $rbpPath = Join-Path $ScriptDir "rbp.ps1"

    $exeName = Split-Path $gameExe -Leaf
    $exeClientMap = @{
        "DeadByDaylight-Win64-Shipping.exe"   = "Steam"
        "DeadByDaylight-EGS-Shipping.exe"     = "Epic"
        "DeadByDaylight-WinGDK-Shipping.exe"  = "Windows"
    }
    $client = if ($exeClientMap.ContainsKey($exeName)) { $exeClientMap[$exeName] } else { "Unknown" }
    $ruleNamePrefix = "MRB_${client}"

    $currentPage = 0
    $markedRegions = @{}

    while ($true) {
        Clear-Host
        Write-Host "Select Server Regions to Block - Page $($currentPage + 1)"
        Write-Host "Client: $client"
        Write-Host "Directory: $gameExe`n"

        $regions = $regionPages[$currentPage]
        for ($i = 0; $i -lt $regions.Count; $i++) {
            $code = $regions[$i]
            $name = $regionMap[$code]
            $isMarked = $markedRegions.ContainsKey($code)
            if ($isMarked) {
                Write-Host "$($i + 1) - $code ($name) [MARKED]" -ForegroundColor Red
            } else {
                Write-Host "$($i + 1) - $code ($name)"
            }
        }

        Write-Host "`nA - Apply Marked Regions" -ForegroundColor Green
        Write-Host "8 - Previous Page"
        Write-Host "9 - Next Page"
        Write-Host "0 - Cancel"

        $input = Read-Host "`nSelect region (1-6) to mark/unmark or option"
        switch ($input.ToUpper()) {
            "8" { if ($currentPage -gt 0) { $currentPage-- } }
            "9" { $currentPage = ($currentPage + 1) % $regionPages.Count }
            "0" { return }
            "A" {
                foreach ($regionCode in $markedRegions.Keys) {
                    $args = @(
                        "-ExecutionPolicy", "Bypass",
                        "-File", "`"$rbpPath`"",
                        "-RegionCode", $regionCode,
                        "-GameExe", "`"$gameExe`"",
                        "-RuleNamePrefix", $ruleNamePrefix
                    )
                    Start-Process powershell.exe -ArgumentList $args -WindowStyle Normal -Verb RunAs
                }
                Read-Host "`nAll marked regions applied. Press Enter to return to menu."
                return
            }
            default {
                if ($input -match '^[1-6]$') {
                    $idx = [int]$input - 1
                    if ($idx -lt $regions.Count) {
                        $regionCode = $regions[$idx]
                        if ($markedRegions.ContainsKey($regionCode)) {
                            $markedRegions.Remove($regionCode)
                        } else {
                            $markedRegions[$regionCode] = $true
                        }
                    }
                }
            }
        }
    }
}

function Remove-Rules {
    Clear-Host

    # Determine rule prefix from active game client
    $gameExe = Get-ValidGameExe
    if (-not $gameExe) {
        Write-Host "Could not determine game executable. Aborting." -ForegroundColor Red
        return
    }

    $exeName = Split-Path $gameExe -Leaf
    $exeClientMap = @{
        "DeadByDaylight-Win64-Shipping.exe"   = "Steam"
        "DeadByDaylight-EGS-Shipping.exe"     = "Epic"
        "DeadByDaylight-WinGDK-Shipping.exe"  = "Windows"
    }
    $client = $exeClientMap[$exeName]
    if (-not $client) { $client = "Unknown" }

    $ruleNamePrefix = "MRB_${client}"

    Write-Host "This will remove all region block rules starting with '$ruleNamePrefix'."
    $confirm = Read-Host "Are you sure? (Y/N)"
    if ($confirm -ne "Y") { return }

    Get-NetFirewallRule | Where-Object { $_.DisplayName -like "$ruleNamePrefix*" } | ForEach-Object {
        Remove-NetFirewallRule -Name $_.Name
        Write-Host "Removed: $($_.DisplayName)"
    }

    Read-Host "Done. Press Enter to return to menu."
}

function Export-ClientBlockList {
    $gameExe = Get-ValidGameExe
    if (-not $gameExe) {
        Write-Host "Could not determine game executable. Aborting." -ForegroundColor Red
        return
    }

    $exeName = Split-Path $gameExe -Leaf
    $exeClientMap = @{
        "DeadByDaylight-Win64-Shipping.exe"   = "Steam"
        "DeadByDaylight-EGS-Shipping.exe"     = "Epic"
        "DeadByDaylight-WinGDK-Shipping.exe"  = "Windows"
    }
    $client = if ($exeClientMap.ContainsKey($exeName)) { $exeClientMap[$exeName] } else { "Unknown" }
    $ruleNamePrefix = "MRB_${client}"

    $tempDir = Join-Path $ScriptDir "..\temp"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir | Out-Null
    }
    $outPath = Join-Path $tempDir "${client}_MRB block list.txt"

    $matchingRules = Get-NetFirewallRule -Direction Outbound | Where-Object {
        $_.DisplayName -like "$ruleNamePrefix*"
    }

    if ($matchingRules.Count -eq 0) {
        Write-Host "No outbound rules found for prefix '$ruleNamePrefix'." -ForegroundColor Yellow
        return
    }

    $uniqueRegions = @()
    foreach ($rule in $matchingRules) {
        if ($rule.DisplayName -match "^$ruleNamePrefix\s*-\s*([a-z0-9-]+)\s*-") {
            $region = $matches[1]
            if (-not $uniqueRegions.Contains($region)) {
                $uniqueRegions += $region
            }
        }
    }

    if ($uniqueRegions.Count -eq 0) {
        Write-Host "No unique regions found." -ForegroundColor Yellow
        return
    }

    $uniqueRegions | ForEach-Object { "$ruleNamePrefix - $_" } | Set-Content -Path $outPath

    # Begin interactive region removal interface
    $page = 0
    $perPage = 6
    $markedForRemoval = @()

    while ($true) {
        Clear-Host
        Write-Host "Blocked Regions for $client (Page $($page + 1)/$([math]::Ceiling($uniqueRegions.Count / $perPage))):`n"

        $start = $page * $perPage
        $end = [math]::Min($start + $perPage, $uniqueRegions.Count)

        for ($i = $start; $i -lt $end; $i++) {
            $index = $i - $start + 1
            $region = $uniqueRegions[$i]
            if ($markedForRemoval -contains $region) {
                Write-Host "$index - $region (Marked)" -ForegroundColor Red
            } else {
                Write-Host "$index - $region"
            }
        }

        Write-Host "`nA - Apply" -ForegroundColor Green
        Write-Host "8 - Previous Page"
        Write-Host "9 - Next Page"
        Write-Host "0 - Cancel" -ForegroundColor Red

        $input = Read-Host "`nSelect region to mark/unmark (1-$perPage), or action"
        switch ($input) {
            "8" { if ($page -gt 0) { $page-- } }
            "9" { if ($page -lt [math]::Ceiling($uniqueRegions.Count / $perPage) - 1) { $page++ } }
            "0" { return }
            "A" {
                foreach ($region in $markedForRemoval) {
                    $rulesToRemove = $matchingRules | Where-Object { $_.DisplayName -like "$ruleNamePrefix - $region*" }
                    foreach ($rule in $rulesToRemove) {
                        Remove-NetFirewallRule -Name $rule.Name
                        Write-Host "Removed: $($rule.DisplayName)"
                    }
                }
                Read-Host "Completed. Press Enter to return to menu."
                return
            }
            default {
                if ($input -match "^[1-6]$") {
                    $choice = [int]$input - 1
                    $index = $page * $perPage + $choice
                    if ($index -lt $uniqueRegions.Count) {
                        $region = $uniqueRegions[$index]
                        if ($markedForRemoval -contains $region) {
                            $markedForRemoval = $markedForRemoval | Where-Object { $_ -ne $region }
                        } else {
                            $markedForRemoval += $region
                        }
                    }
                }
            }
        }
    }
}
function Show-MainMenu {
# Read active_dir from preset.txt
    $presetLines = Get-Content $presetFile
    $activeLine = $presetLines | Where-Object { $_ -match "^active_dir\s*=\s*(.+)$" }
    $activePath = if ($activeLine) { $matches[1] } else { "N/A" }

# Detect which client based on exe name
    $exeClientMap = @{
        "DeadByDaylight-Win64-Shipping.exe" = "Steam"
        "DeadByDaylight-EGS-Shipping.exe"   = "Epic Games"
        "DeadByDaylight-WinGDK-Shipping.exe" = "Windows Store"
    }
    $exeName = Split-Path $activePath -Leaf
    $client = if ($exeClientMap.ContainsKey($exeName)) { $exeClientMap[$exeName] } else { "Unknown" }
    while ($true) {
        Clear-Host
        Write-Host "Dead by Daylight AWS Region Firewall Tool`n"
        Write-Host "Current Client: $client"
        Write-Host "Directory: $activePath`n"
        Write-Host "1 - Update IP Ranges"
        Write-Host "2 - Block Server Regions"
        Write-Host "3 - Remove Server Region Blocks (ALL)"
        Write-Host "4 - Remove Server Region Blocks (SELECTED)"
        Write-Host "0 - Exit"
        $choice = Read-Host "`nEnter selection"
        switch ($choice) {
            "1" { Update-IpRanges }
            "2" { Block-Regions }
            "3" { Remove-Rules }
            "4" { Export-ClientBlockList }
            "0" { exit }
        }
    }
}

try {
    Show-MainMenu
} catch {
    if (-not (Test-Path $logDir)) { New-Item $logDir -Force | Out-Null }
    Set-Content -Path $crashLogFile -Value $_.Exception.Message
    Write-Host "Fatal error logged to:`n$crashLogFile" -ForegroundColor Red
    Read-Host "Press Enter to exit."
}