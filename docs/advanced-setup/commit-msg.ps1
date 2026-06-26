#!/usr/bin/env pwsh

param (
    [string]$MessageFile
)

# =========================
# CONFIG
# =========================
$aiThreshold = 10
$logPath = "$env:TEMP\git-ai-hook.log"

function Write-Log($msg) {
    Add-Content $logPath "[$(Get-Date)] $msg"
}

# =========================
# Tool mapping
# =========================
$toolMap = @{
    "github-copilot-cli" = "GitHub Copilot"
    "copilot"            = "GitHub Copilot"
    "cursor"             = "Cursor"
    "git-ai"             = "Git AI"
    "junie"              = "JetBrains Junie"
}

# =========================
# Add trailers
# =========================
function Add-CoAuthors($msg, $tools) {

    $tools | Select-Object -Unique | ForEach-Object {
        $line = "<commit-msg hook> Co-authored-by: $_ <ai@local>"
        if ($msg -notmatch [regex]::Escape($line)) {
            $msg = $msg.TrimEnd() + "`n`n$line"
        }
    }

    return $msg
}

# =========================
# MAIN
# =========================
try {

    git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) { exit 0 }

    $msg = Get-Content $MessageFile -Raw
    Write-Log "Hook fired"

    $statusRaw = git-ai status --json 2>$null
    if (-not $statusRaw) {
        Write-Log "git-ai status returned nothing - skipping"
        exit 0
    }

    try {
        $status = ConvertFrom-Json $statusRaw
    } catch {
        Write-Log "Failed to parse git-ai status JSON: $_"
        exit 0
    }

    $stats = $status.stats
    $aiAdditions      = [int]$stats.ai_additions
    $humanAdditions   = [int]$stats.human_additions
    $unknownAdditions = [int]$stats.unknown_additions
    $totalAdditions   = $aiAdditions + $humanAdditions + $unknownAdditions

    Write-Log "ai=$aiAdditions human=$humanAdditions unknown=$unknownAdditions total=$totalAdditions"

    if ($totalAdditions -eq 0 -or $aiAdditions -eq 0) {
        Write-Log "No AI additions found - skipping"
        exit 0
    }

    $aiPercent = [math]::Round(($aiAdditions / $totalAdditions) * 100)
    Write-Log "AI%=$aiPercent"

    if ($aiPercent -lt $aiThreshold) {
        Write-Log "AI% below threshold ($aiThreshold) - skipping"
        exit 0
    }

    # Determine tools from breakdown (keys are "tool/model" or "tool")
    $tools = @()
    foreach ($key in $stats.tool_model_breakdown.PSObject.Properties.Name) {
        $tool = ($key -split '/')[0]
        $tools += if ($toolMap.ContainsKey($tool)) { $toolMap[$tool] } else { $tool }
    }

    if ($tools.Count -eq 0) {
        Write-Log "AI additions found but no tool breakdown - skipping"
        exit 0
    }

    Write-Log "Tools: $($tools -join ', ')"

    $msg = Add-CoAuthors $msg $tools
    Set-Content -Path $MessageFile -Value $msg -NoNewline

    Write-Log "Co-authors appended"
    exit 0
}
catch {
    Write-Log "ERROR: $_"
    exit 0
}
