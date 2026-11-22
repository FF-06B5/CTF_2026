param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [switch]$DryRun,
    [string]$Placeholder = 'hkcert26{REDACTED}'
)

# Replace the body of every hkcert26{...} with a placeholder, so the repo can be published.
# Usage:
#   .\tools\redact.ps1 -DryRun     # preview only, no files touched
#   .\tools\redact.ps1             # apply
#
# NOTE: kept ASCII-only on purpose -- Windows PowerShell 5.1 reads BOM-less
# .ps1 files as ANSI and would mangle non-ASCII literals.

# Only real flag bodies: lowercase alnum / underscore / dot, at least 8 chars.
# This deliberately does NOT match the format placeholders used in the docs
# (hkcert26{...}, hkcert26{[a-z0-9_]+}) nor an already-redacted hkcert26{REDACTED}.
$pattern = 'hkcert26\{[a-z0-9_.]{8,}\}'
$files = Get-ChildItem -Path $Root -Recurse -Include *.md -File |
         Where-Object { $_.FullName -notmatch '\\\.git\\' }

$total = 0
foreach ($f in $files) {
    $raw = Get-Content $f.FullName -Raw -Encoding UTF8
    if (-not $raw) { continue }

    $hits = [regex]::Matches($raw, $pattern)
    if ($hits.Count -eq 0) { continue }

    $rel = $f.FullName.Replace($Root, '.')

    if ($DryRun) {
        "{0}  ({1} hits)" -f $rel, $hits.Count
        $hits | ForEach-Object { $_.Value } | Sort-Object -Unique |
            ForEach-Object { "    $_" }
        $total += $hits.Count
        continue
    }

    $new = [regex]::Replace($raw, $pattern, $Placeholder)
    # Write UTF-8 WITHOUT BOM (Set-Content -Encoding UTF8 would add one in PS 5.1,
    # which shows up as a stray character on some markdown viewers).
    [System.IO.File]::WriteAllText(
        $f.FullName,
        $new,
        (New-Object System.Text.UTF8Encoding($false))
    )
    "REDACTED  {0}  ({1} hits)" -f $rel, $hits.Count
    $total += $hits.Count
}

if ($DryRun) {
    ""
    "Preview done: {0} occurrence(s) would be replaced. Files were NOT modified." -f $total
} else {
    ""
    "Done: {0} occurrence(s) replaced." -f $total
}
