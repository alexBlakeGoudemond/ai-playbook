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
        if ($key -match '@') { continue }          # skip "Name <email@host>" format
        if ($key -cmatch '^[A-Z]') { continue }     # skip human names (tool IDs are always lowercase)
        $tool = ($key -split '[/\s]')[0]            # handle both '/' and ' ' separators
        $tools += if ($toolMap.ContainsKey($tool)) { $toolMap[$tool] } else { $tool }
    }

    # Fallback: parse non-human checkpoints when breakdown is empty
    if ($tools.Count -eq 0) {
        foreach ($cp in $status.checkpoints) {
            if ($cp.is_human -eq $true -or -not $cp.tool_model) { continue }
            if ($cp.tool_model -match '@') { continue }           # skip "Name <email@host>" format
            if ($cp.tool_model -cmatch '^[A-Z]') { continue }    # skip human names (tool IDs are always lowercase)
            $tool = ($cp.tool_model -split '[/\s]')[0]
            $tools += if ($toolMap.ContainsKey($tool)) { $toolMap[$tool] } else { $tool }
        }
    }

    # Fallback: read session tool directly from git-ai status sessions
    if ($tools.Count -eq 0 -and $status.sessions) {
        foreach ($k in $status.sessions.PSObject.Properties.Name) {
            $tool = $status.sessions.$k.agent_id.tool
            if (-not $tool -or $tool -match '@' -or $tool -cmatch '^[A-Z]') { continue }
            $tools += if ($toolMap.ContainsKey($tool)) { $toolMap[$tool] } else { $tool }
        }
    }

    # Helper: parse sessions tool from a refs/notes/ai note on a given ref
    function Get-ToolsFromNote($ref) {
        $noteRaw = git notes --ref=refs/notes/ai show $ref 2>$null
        if (-not $noteRaw) { return @() }
        $noteStr = ($noteRaw -join ' ').Trim()
        $jsonPart = ($noteStr -split '\s*---\s*', 2)[-1].Trim()
        $result = @()
        try {
            $noteStatus = ConvertFrom-Json $jsonPart
            foreach ($k in $noteStatus.sessions.PSObject.Properties.Name) {
                $tool = $noteStatus.sessions.$k.agent_id.tool
                if ($tool) {
                    $result += if ($toolMap.ContainsKey($tool)) { $toolMap[$tool] } else { $tool }
                }
            }
        } catch {
            Write-Log "Failed to parse note for $ref`: $_"
        }
        return $result
    }

    # Fallback: after git reset --soft, ORIG_HEAD points to the previous commit which already has a git-ai note
    if ($tools.Count -eq 0) {
        $origHead = git rev-parse ORIG_HEAD 2>$null
        if ($origHead) {
            Write-Log "Trying ORIG_HEAD ($origHead) note for tool info"
            $tools += Get-ToolsFromNote $origHead
        }
    }

    # Fallback: HEAD's note (useful if parent commit had a session note)
    if ($tools.Count -eq 0) {
        Write-Log "Trying HEAD note for tool info"
        $tools += Get-ToolsFromNote "HEAD"
    }

    if ($tools.Count -eq 0) {
        Write-Log "AI additions found but no tool session identified - skipping attribution"
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
