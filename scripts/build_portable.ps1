# scripts/build_portable.ps1
# ساخت بسته پرتیبل ویندوز Student360
# - پایتون Embeddable 3.11 + همه کتابخانه‌ها + بک‌اند + فرانت‌اند ساخته‌شده
# - خروجی: build/Student360-Portable  (سپس zip می‌شود)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$build    = Join-Path $repoRoot "build"
$pkg      = Join-Path $build "Student360-Portable"

if (Test-Path $build) { Remove-Item $build -Recurse -Force }
foreach ($d in @($pkg, "$pkg\runtime", "$pkg\app", "$pkg\web", "$pkg\data")) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

# ===== 1) دانلود و استخراج پایتون Embeddable =====
$pyVer    = "3.11.9"
$embedUrl = "https://www.python.org/ftp/python/$pyVer/python-$pyVer-embed-amd64.zip"
$embedZip = Join-Path $build "python-embed.zip"
Write-Host "==> Downloading embedded Python $pyVer ..."
Invoke-WebRequest -Uri $embedUrl -OutFile $embedZip -MaximumRetryCount 3 -RetryIntervalSec 5
Expand-Archive -Path $embedZip -DestinationPath "$pkg\runtime" -Force

# ===== 2) فعال‌سازی site-packages و نصب pip =====
# نکته: فایل ._pth را از صفر بازنویسی می‌کنیم (Add-Content در صورت نبود newline
# انتهای فایل، خط‌ها را به هم می‌چسباند و مسیرها نادیده گرفته می‌شوند)
$pth = "$pkg\runtime\python311._pth"
Write-Host "==> Rewriting python311._pth ..."
$pthContent = "python311.zip`r`n.`r`nLib\site-packages`r`nimport site`r`n"
[System.IO.File]::WriteAllText($pth, $pthContent, [System.Text.Encoding]::ASCII)
Get-Content $pth | ForEach-Object { Write-Host "    _pth line: [$_]" }

$getPip = Join-Path $build "get-pip.py"
Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile $getPip -MaximumRetryCount 3 -RetryIntervalSec 5
$py = "$pkg\runtime\python.exe"

Write-Host "==> Installing pip into embedded Python ..."
& $py $getPip --no-warn-script-location --no-cache-dir --no-input
if ($LASTEXITCODE -ne 0) { throw "get-pip failed with exit code $LASTEXITCODE" }

Write-Host "==> Python diagnostics:"
& $py -c "import sys, sysconfig; print('PREFIX:', sys.prefix); print('SYSPATHS:', sys.path); print('PURELIB:', sysconfig.get_paths().get('purelib'))"
if (Test-Path "$pkg\runtime\Lib\site-packages") {
    Get-ChildItem "$pkg\runtime\Lib\site-packages" | Select-Object -First 15 | ForEach-Object { Write-Host "    site-packages: $($_.Name)" }
} else {
    Write-Host "    WARNING: runtime\Lib\site-packages does not exist!"
}

& $py -m pip --version
if ($LASTEXITCODE -ne 0) { throw "pip module not importable after get-pip (exit $LASTEXITCODE)" }

$env:PIP_DISABLE_PIP_VERSION_CHECK = "1"
$env:PIP_DEFAULT_TIMEOUT = "180"
Write-Host "==> Installing backend requirements (this may take a few minutes) ..."
& $py -m pip install --no-warn-script-location --no-cache-dir --no-input -r "$repoRoot\backend\requirements.txt"
if ($LASTEXITCODE -ne 0) { throw "pip install failed with exit code $LASTEXITCODE" }

# ===== 3) کد بک‌اند =====
Write-Host "==> Copying backend source ..."
robocopy "$repoRoot\backend" "$pkg\app" /E /NFL /NDL /NJH /NJS /NP /XD __pycache__ .pytest_cache tests /XF *.pyc *.db report.json
if ($LASTEXITCODE -ge 8) { throw "robocopy backend failed ($LASTEXITCODE)" }
$LASTEXITCODE = 0

# ===== 4) فرانت‌اند ساخته‌شده =====
Write-Host "==> Copying frontend dist ..."
if (-not (Test-Path "$repoRoot\frontend\dist\index.html")) { throw "frontend/dist/index.html not found - build the frontend first" }
robocopy "$repoRoot\frontend\dist" "$pkg\web" /E /NFL /NDL /NJH /NJS /NP
if ($LASTEXITCODE -ge 8) { throw "robocopy web failed ($LASTEXITCODE)" }
$LASTEXITCODE = 0

# ===== 5) دیتابیس اولیه (داده‌های موجود) =====
$dbSrc = "$repoRoot\backend\university_scheduler.db"
if (Test-Path $dbSrc) {
    Copy-Item $dbSrc "$pkg\data\university_scheduler.db" -Force
    Write-Host "==> Seed database copied to data/university_scheduler.db"
}

# ===== 6) لانچر و راهنما =====
Copy-Item "$repoRoot\portable\start_student360.bat" $pkg -Force
Copy-Item "$repoRoot\portable\README.txt" $pkg -Force

# ===== 7) تست سلامت: import کل برنامه با پایتون داخلی =====
Write-Host "==> Smoke test: importing app.main with embedded Python ..."
& $py -c "import sys; sys.path.insert(0, r'$pkg\app'); import app.main; print('IMPORT_OK')"
if ($LASTEXITCODE -ne 0) { throw "smoke test failed - app.main could not be imported" }

Write-Host ""
Write-Host "SUCCESS: portable package assembled at $pkg"
$sizeMB = [math]::Round(((Get-ChildItem $pkg -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB), 1)
Write-Host "Package size: $sizeMB MB"
