$scheme = "annyanissaya"

Write-Host "Removing ${scheme}:// URL scheme..." -ForegroundColor Yellow
reg delete "HKCU\Software\Classes\$scheme" /f 2>$null
reg delete "HKLM\Software\Classes\$scheme" /f 2>$null
Write-Host "Done." -ForegroundColor Green
