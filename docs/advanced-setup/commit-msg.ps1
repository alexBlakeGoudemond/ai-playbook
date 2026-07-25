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
    Add-Content $logPath "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
}

# =========================
# Tool mapping
# =========================
$toolMap = @{
    "github-copilot-cli"        = "GitHub Copilot"
    "github-copilot-jetbrains"  = "GitHub Copilot"
    "copilot"                   = "GitHub Copilot"
    "cursor"                    = "Cursor"
    "git-ai"                    = "Git AI"
    "junie"                     = "JetBrains Junie"
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
    $aiAccepted       = [int]$stats.ai_accepted
    $humanAdditions   = [int]$stats.human_additions
    $unknownAdditions = [int]$stats.unknown_additions
    $totalAdditions   = $aiAdditions + $humanAdditions + $unknownAdditions

    Write-Log "ai=$aiAdditions accepted=$aiAccepted human=$humanAdditions unknown=$unknownAdditions total=$totalAdditions"

    if ($totalAdditions -eq 0 -or $aiAdditions -eq 0) {
        Write-Log "No AI additions found - skipping"
        exit 0
    }

    # Guard against session-only attribution where no AI output was actually accepted.
    if ($aiAccepted -eq 0) {
        Write-Log "AI additions exist but accepted suggestions are zero - skipping"
        exit 0
    }

    $aiPercent = [math]::Round(($aiAdditions / $totalAdditions) * 100)
    Write-Log "AI%=$aiPercent"

    if ($aiPercent -lt $aiThreshold) {
        Write-Log "AI% below threshold ($aiThreshold) - skipping"
        exit 0
    }

    # Determine tools from explicit AI-attribution signals only.
    # Do not use session/note metadata fallbacks: they can exist for human-only commits.
    $tools = @()
    if ($stats.tool_model_breakdown) {
        foreach ($key in $stats.tool_model_breakdown.PSObject.Properties.Name) {
            if ($key -match '@') { continue }                       # skip "Name <email@host>" format
            if ($key -cmatch '^[A-Z][a-z]+ [A-Z]') { continue } # skip human names (e.g. "Alex Blake-Goudemond")
            $tool = ($key -split '[/\s]')[0].ToLower()           # handle both '/' and ' ' separators
            $tools += if ($toolMap.ContainsKey($tool)) { $toolMap[$tool] } else { $tool }
        }
    }

    # Fallback: parse non-human checkpoints when breakdown is empty
    if ($tools.Count -eq 0) {
        foreach ($cp in $status.checkpoints) {
            if ($cp.is_human -eq $true -or -not $cp.tool_model) { continue }
            if ($cp.tool_model -match '@') { continue }                        # skip "Name <email@host>" format
            if ($cp.tool_model -cmatch '^[A-Z][a-z]+ [A-Z]') { continue }  # skip human names (e.g. "Alex Blake-Goudemond")
            $tool = ($cp.tool_model -split '[/\s]')[0].ToLower()
            $tools += if ($toolMap.ContainsKey($tool)) { $toolMap[$tool] } else { $tool }
        }
    }

    if ($tools.Count -eq 0) {
        Write-Log "AI additions found but no explicit tool attribution detected - skipping"
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
