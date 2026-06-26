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

    # Determine tools: primary from breakdown, fallback from HEAD's refs/notes/ai session data
    $tools = @()
    foreach ($key in $stats.tool_model_breakdown.PSObject.Properties.Name) {
        $tool = ($key -split '[/ ]')[0].ToLower()
        $tools += if ($toolMap.ContainsKey($tool)) { $toolMap[$tool] } else { $tool }
    }

    # Fallback: parse non-human checkpoints when breakdown is empty
    if ($tools.Count -eq 0) {
        Write-Log "Checkpoints: $($status.checkpoints.Count)"
        foreach ($cp in $status.checkpoints) {
            Write-Log "  cp: is_human=$($cp.is_human) tool_model=$($cp.tool_model) additions=$($cp.additions)"
            if ($cp.is_human -or -not $cp.tool_model) { continue }
            $tool = ($cp.tool_model -split '[/ ]')[0].ToLower()
            $tools += if ($toolMap.ContainsKey($tool)) { $toolMap[$tool] } else { $tool }
        }
    }

    # Final fallback: read session tool from HEAD's refs/notes/ai staging note
    if ($tools.Count -eq 0) {
        $noteRaw = git notes --ref=refs/notes/ai show HEAD 2>$null
        if ($noteRaw) {
            $noteStr = ($noteRaw -join ' ').Trim()
            $jsonPart = ($noteStr -split '\s*---\s*', 2)[-1].Trim()
            try {
                $noteStatus = ConvertFrom-Json $jsonPart
                foreach ($k in $noteStatus.sessions.PSObject.Properties.Name) {
                    $tool = $noteStatus.sessions.$k.agent_id.tool
                    if ($tool) {
                        $tools += if ($toolMap.ContainsKey($tool)) { $toolMap[$tool] } else { $tool }
                    }
                }
            } catch {
                Write-Log "Failed to parse HEAD note for tool info: $_"
            }
        }
    }

    if ($tools.Count -eq 0) {
        Write-Log "AI additions found but could not determine tool - skipping"
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
