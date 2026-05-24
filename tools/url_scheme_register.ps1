param(
  [string]$ExePath = ""
)

$scheme = "annyanissaya"

if (-not $ExePath) {
  $dir = Split-Path -Parent $PSScriptRoot
  $ExePath = Join-Path $dir "build\windows\arm64\runner\Debug\annya_nissaya.exe"
}

if (-not (Test-Path $ExePath)) {
  Write-Host "Error: executable not found at $ExePath" -ForegroundColor Red
  exit 1
}

Write-Host "Registering ${scheme}:// URL scheme..." -ForegroundColor Green
reg add "HKCU\Software\Classes\${scheme}" /v "URL Protocol" /d "" /f
reg add "HKCU\Software\Classes\${scheme}\shell\open\command" /ve /d "`"$ExePath`" `"%1`"" /f
Write-Host "Done. Test with: ${scheme}://mm.pndaza.annyanissaya/open?id=annya_sadda_01&page=40" -ForegroundColor Green
