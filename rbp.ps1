# --- PARAMETERS ---
param (
    [string]$RegionCode,
    [string]$GameExePath,
    [string]$RuleNamePrefix = "MRB_DBD",
    [string]$RegionCodesDir = "$PSScriptRoot\..\Region Codes"
)

# --- AUTO-ELEVATE ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argString = "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -RegionCode `"$RegionCode`" -GameExePath `"$GameExePath`""
    Start-Process powershell -ArgumentList $argString -Verb RunAs
    exit
}

# --- SETUP ---
Add-Type -AssemblyName System.Windows.Forms

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogDir = Join-Path $ScriptDir "..\Logs"
$CrashLog = Join-Path $LogDir "rbp_crashlog_$(Get-Date -Format 'ddMMyy_HHmmss').txt"

# --- VALIDATION ---
function Show-Error($msg) {
    [System.Windows.Forms.MessageBox]::Show($msg, "Blocking Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    exit 1
}

if (-not $RegionCode -or -not $GameExePath) {
    Show-Error "Missing RegionCode or GameExePath."
}
if (-not (Test-Path $GameExePath)) {
    Show-Error "Game executable not found at: $GameExePath"
}
$RegionFile = Join-Path $RegionCodesDir "$RegionCode.txt"
if (-not (Test-Path $RegionFile)) {
    Show-Error "Region IP list not found: $RegionFile"
}

# --- MAIN LOGIC ---
function Add-BlockRules {
    $ipRanges = Get-Content $RegionFile
    $newRulesCreated = 0
    $alreadyExists = 0
    $startTime = Get-Date

    Write-Host "`nStarting block operation for $RegionCode..." -ForegroundColor Cyan

    # Load expected IP count from iprange_stat.txt
        $ipStatFile = Join-Path $RegionCodesDir "iprange_stat.txt"
        $expectedCount = "?"
        if (Test-Path $ipStatFile) {
        $statLines = Get-Content $ipStatFile
        foreach ($line in $statLines) {
        if ($line -match "^$RegionCode\s*\|\s*(\d+)$") {
            $expectedCount = [int]$matches[1]
            break
        }
    }
}

        $ruleName = "$RuleNamePrefix - $RegionCode - $ip"
        if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
            Write-Host "Blocking $ip..." -ForegroundColor Yellow
            New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -Action Block `
                -Program $GameExePath -RemoteAddress $ipRanges -Profile Any -Enabled True `
                -Description "Blocks Dead by Daylight from region $RegionCode" | Out-Null
            $newRulesCreated++
        } else {
            Write-Host "Already exists: $ip" -ForegroundColor DarkGray
            $alreadyExists++
        }

    $totalIPs = $ipRanges.Count
    $actualTotal = if ($expectedCount -ne "?") { $expectedCount } else { $totalIPs }
    $missed = $actualTotal - ($newRulesCreated + $alreadyExists)
    $elapsed = (Get-Date) - $startTime

        Write-Host ""
        Write-Host ""
        Write-Host "===== Blocking Summary =====" -ForegroundColor Green
        Write-Host "Region: $RegionCode"
        Write-Host "Blocked IPs: $newRulesCreated"
        Write-Host "Already Blocked: $alreadyExists"
        Write-Host "Expected IPs from Log: $actualTotal"
        Write-Host "Missed IPs: $missed"
        Write-Host "Elapsed Time: $($elapsed.ToString('hh\:mm\:ss'))"
        Write-Host "============================"

    Read-Host "`nPress Enter to close this window..."
}

# --- EXECUTE ---
try {
    Add-BlockRules
} catch {
    $err = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Exception:`n$($_.Exception.Message)`n$($_.ScriptStackTrace)"
    if (-not (Test-Path $LogDir)) { New-Item $LogDir -Force | Out-Null }
    Set-Content -Path $CrashLog -Value $err
    Show-Error "An error occurred while blocking region rules. Crash log saved to:`n$CrashLog"
}
