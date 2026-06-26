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
# JetBrains detection
# =========================
function Test-IsJetBrains {

    if ($env:GIT_EDITOR -eq ':') {
        Write-Log "JetBrains fast-path (GIT_EDITOR=:)"
        return $true
    }

    try {
        $procs = Get-CimInstance Win32_Process -Property ProcessId,ParentProcessId,Name,CommandLine
        $map = @{}
        foreach ($p in $procs) { $map[[int]$p.ProcessId] = $p }

        $pid = $PID

        for ($i = 0; $i -lt 8; $i++) {
            if (-not $map.ContainsKey($pid)) { break }

            $cur = $map[$pid]
            $parentPid = [int]$cur.ParentProcessId
            if ($parentPid -le 0 -or $parentPid -eq $pid) { break }
            if (-not $map.ContainsKey($parentPid)) { break }

            $parent = $map[$parentPid]
            $name = $parent.Name -replace '\.exe$', ''
            $cmd  = $parent.CommandLine

            if ($name -match 'idea|webstorm|pycharm|goland|rider|clion|phpstorm|rubymine|junie|jbr') {
                Write-Log "JetBrains match via process name"
                return $true
            }

            if ($name -eq 'java' -and $cmd -match 'jetbrains|intellij|idea|junie|rider|webstorm|goland') {
                Write-Log "JetBrains match via JVM cmd"
                return $true
            }

            $pid = $parentPid
        }
    } catch {
        Write-Log "JetBrains detection error: $_"
    }

    return $false
}

# =========================
# Git AI note loader
# =========================
function Get-AiNote {
    return git notes --ref=refs/notes/ai show HEAD 2>$null
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
# Parse sessions
# =========================
function Parse-AiSessions($status) {
    $aiSessions = @()
    $tools = @()

    foreach ($k in $status.sessions.PSObject.Properties.Name) {
        $s = $status.sessions.$k
        $agent = $s.agent_id

        if (-not $agent) { continue }

        $aiSessions += $k
        $tool = $agent.tool

        if ($tool) {
            $tools += if ($toolMap.ContainsKey($tool)) { $toolMap[$tool] } else { $tool }
        }
    }

    return @{ Sessions = $aiSessions; Tools = $tools }
}

# =========================
# AI % calculation
# =========================
function Get-AiPercent($noteAttribution, $aiSessions) {

    $total = 0
    $ai = 0

    foreach ($chunk in ($noteAttribution -split '\s{3,}')) {
        if ($chunk -notmatch '^(s_\w+)::\w+\s+(.+)$') { continue }

        $session = $Matches[1]
        $refs = $Matches[2]

        $count = 0
        foreach ($r in $refs.Split(',')) {
            if ($r -match '^(\d+)-(\d+)$') {
                $count += ([int]$Matches[2] - [int]$Matches[1] + 1)
            } elseif ($r -match '^\d+$') {
                $count++
            }
        }

        $total += $count
        if ($aiSessions -contains $session) { $ai += $count }
    }

    if ($total -eq 0 -and $aiSessions.Count -gt 0) { return 100 }

    return if ($total -gt 0) { [math]::Round(($ai / $total) * 100) } else { 0 }
}

# =========================
# Add trailers
# =========================
function Add-CoAuthors($msg, $tools) {

    if ($tools.Count -eq 0) {
        $tools = @("AI Agent")
    }

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

    $noteRaw = Get-AiNote

    $aiSessions = @()
    $tools = @()
    $aiPercent = 0
    $attribution = ""

    if (-not $noteRaw) {
        Write-Log "No note found"

        if (Test-IsJetBrains) {
            Write-Log "Fallback: JetBrains assumed full AI"
            $aiPercent = 100
            $tools = @("JetBrains Junie")
        } else {
            exit 0
        }
    }
    else {
        $noteStr = ($noteRaw -join ' ').Trim()
        $parts = $noteStr -split '\s*---\s*', 2

        if ($parts.Count -lt 2) {
            try {
                $status = ConvertFrom-Json $noteStr
            } catch {
                exit 0
            }
        } else {
            $attribution = $parts[0]
            $status = ConvertFrom-Json $parts[1].Trim()
        }

        if (-not $status.sessions) {
            if (Test-IsJetBrains) {
                $aiPercent = 100
                $tools = @("JetBrains Junie")
            } else {
                exit 0
            }
        } else {
            $parsed = Parse-AiSessions $status
            $aiSessions = $parsed.Sessions
            $tools = $parsed.Tools

            if ($aiSessions.Count -eq 0) { exit 0 }

            $aiPercent = Get-AiPercent $attribution $aiSessions
        }
    }

    Write-Log "AI%=$aiPercent tools=$($tools -join ',')"

    if ($aiPercent -lt $aiThreshold) { exit 0 }

    $msg = Add-CoAuthors $msg $tools

    Set-Content -Path $MessageFile -Value $msg -NoNewline

    Write-Log "Co-authors appended"
    exit 0
}
catch {
    Write-Log "ERROR: $_"
    exit 0
}