# Configuration
$gameExePath = "E:\SteamLibrary\steamapps\common\Dead by Daylight\DeadByDaylight\Binaries\Win64\DeadByDaylight-Win64-Shipping.exe"
$ruleNamePrefix = "MRB_DBD"

# AWS region codes and names
$regionMap = @{
    "us-east-2"     = "US East (Ohio)"
    "us-east-1"     = "US East (N. Virginia)"
    "us-west-1"     = "US West (N. California)"
    "us-west-2"     = "US West (Oregon)"
    "ap-south-1"    = "Asia Pacific (Mumbai)"
    "ap-northeast-2"= "Asia Pacific (Seoul)"
    "ap-southeast-1"= "Asia Pacific (Singapore)"
    "ap-southeast-2"= "Asia Pacific (Sydney)"
    "ap-northeast-1"= "Asia Pacific (Tokyo)"
    "ca-central-1"  = "Canada (Central)"
    "eu-central-1"  = "Europe (Frankfurt)"
    "eu-west-1"     = "Europe (Ireland)"
    "eu-west-2"     = "Europe (London)"
    "sa-east-1"     = "South America (São Paulo)"
}

# Region selection
$regionPages = @(
    @("us-east-2", "us-east-1", "us-west-1", "us-west-2", "ap-south-1"),
    @("ap-northeast-2", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "ca-central-1"),
    @("eu-central-1", "eu-west-1", "eu-west-2", "sa-east-1")
)

function Show-MainMenu {
    while ($true) {
        Clear-Host
        Write-Host "Dead by Daylight AWS Region Firewall Tool`n"
        Write-Host "1 - Block Server Regions"
        Write-Host "2 - Remove Server Region Blocks"
        Write-Host "9 - Cancel"
        $choice = Read-Host "`nEnter selection"
        switch ($choice) {
            "1" { Block-Regions }
            "2" { Remove-Rules }
            "9" { exit }
        }
    }
}

function Block-Regions {
    $selectedRegions = @()
    $currentPage = 0

    while ($true) {
        Clear-Host
        Write-Host "Block Server Regions - Page $($currentPage + 1)`n"
        $regions = $regionPages[$currentPage]
        for ($i = 0; $i -lt $regions.Count; $i++) {
            $region = $regions[$i]
            $name = $regionMap[$region]
            Write-Host "$($i + 1) - $region ($name)"
        }
        Write-Host "8 - Next Page"
        Write-Host "9 - Return"
        Write-Host "0 - Confirm"

        $input = Read-Host "`nSelect a region to block (1 digit only)"
        
        switch ($input) {
            "8" { $currentPage = ($currentPage + 1) % $regionPages.Count }
            "9" { return }
            "0" {
                if ($selectedRegions.Count -eq 0) {
                    Write-Host "No regions selected. Press Enter to return."
                    Read-Host
                    return
                }
                Confirm-Block $selectedRegions
                return
            }
            default {
                if ($input.Length -eq 1 -and $input -match '^\d$') {
                    $idx = [int]$input
                    if ($idx -in 1..$regions.Count) {
                        $regionCode = $regions[$idx - 1]
                        if (-not $selectedRegions.Contains($regionCode)) {
                            $selectedRegions += $regionCode
                            Write-Host "Region added: $regionCode"
                        } else {
                            Write-Host "Region $regionCode already selected."
                        }
                    } else {
                        Write-Host "Invalid selection. Please enter a valid option."
                    }
                } else {
                    Write-Host "Only one number at a time is allowed. Please try again."
                }
                Start-Sleep -Seconds 1.5
            }
        }
    }
}

function Confirm-Block($regions) {
    Clear-Host
    Write-Host "You are about to block the following regions:`n"
    foreach ($region in $regions) {
        Write-Host "$region - $($regionMap[$region])"
    }
    $confirm = Read-Host "`nAre you sure? (Y/N)"
    if ($confirm -ne "Y") {
        Write-Host "Operation cancelled. Press Enter to return."
        Read-Host
        return
    }

    $awsIpJsonUrl = "https://ip-ranges.amazonaws.com/ip-ranges.json"
    $ipData = Invoke-RestMethod -Uri $awsIpJsonUrl

    $newRulesCreated = 0

    foreach ($region in $regions) {
        $prefixes = $ipData.prefixes | Where-Object { $_.region -eq $region }
        foreach ($prefix in $prefixes) {
            $ipRange = $prefix.ip_prefix
            $ruleName = "$ruleNamePrefix - $region - $ipRange"
            if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
                New-NetFirewallRule `
                    -DisplayName $ruleName `
                    -Direction Outbound `
                    -Action Block `
                    -Program $gameExePath `
                    -RemoteAddress $ipRange `
                    -Profile Any `
                    -Enabled True `
                    -Description "Blocks Dead by Daylight from region $region"
                $newRulesCreated++
                Write-Host "Blocked: $region ($ipRange)"
            } else {
                Write-Host "Rule already exists: $ruleName"
            }
        }
    }

    Write-Host "`n$newRulesCreated new firewall rule(s) created."
    Read-Host "Press Enter to return to main menu."
}

function Remove-Rules {
    Clear-Host
    Write-Host "This will remove all region block rules starting with '$ruleNamePrefix'."
    $confirm = Read-Host "Are you sure? (Y/N)"
    if ($confirm -ne "Y") {
        Write-Host "Operation cancelled. Press Enter to return."
        Read-Host
        return
    }

    $rules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "$ruleNamePrefix*" }
    if ($rules.Count -eq 0) {
        Write-Host "No rules found to remove. Press Enter to return."
        Read-Host
        return
    }

    foreach ($rule in $rules) {
        Remove-NetFirewallRule -Name $rule.Name
        Write-Host "Removed: $($rule.DisplayName)"
    }

    Write-Host "`nAll matching rules removed."
    Read-Host "Press Enter to return to main menu."
}

# Start script
Show-MainMenu
