@echo off
setlocal
chcp 65001 >nul
title Student360 - Portable Edition

set "PKG_DIR=%~dp0"
set "PY_EXE=%PKG_DIR%runtime\python.exe"
set "LAUNCHER=%PKG_DIR%app\launch_portable.py"

echo ==========================================================
echo   Student360 - Samane Hoshmand Barnameh-rizi Darsi (Portable)
echo ==========================================================
echo Folder : %PKG_DIR%
echo.

if exist "%PY_EXE%" if exist "%LAUNCHER%" if exist "%PKG_DIR%web\index.html" goto RUN

echo.
echo [ERROR] Required files were NOT found in this folder:
echo         - %PY_EXE%
echo         - %LAUNCHER%
echo         - %PKG_DIR%web\index.html
echo.
echo ----------------------------------------------------------
echo   HOW TO FIX (please read):
echo ----------------------------------------------------------
echo   1) Run this file from INSIDE the ZIP viewer? You must
echo      EXTRACT the whole ZIP first:
echo         Right-click on Student360-Portable-Windows.zip
echo         -^> "Extract All..." -^> open the extracted folder
echo         -^> run start_student360.bat from there.
echo   2) Downloaded the wrong file? From the GitHub Releases
echo      page download the asset named
echo      "Student360-Portable-Windows.zip"  (about 280 MB),
echo      NOT "Source code (zip)".
echo   3) Antivirus may have removed some files - add the
echo      folder to exclusions and re-extract the ZIP.
echo.
echo ----------------------------------------------------------
echo   HOW TO FIX:
echo ----------------------------------------------------------
echo   1) agar in file ra az dakhele ZIP ejra karde-id, avval
echo      kol-e ZIP ra Extract konid (Right-click - Extract All),
echo      sepas dakhel-e posheye estekhraj-shode, in file ra
echo      dobare ejra konid.
echo   2) az safheye Releases dar GitHub fayle
echo      "Student360-Portable-Windows.zip" (taghiban 280 MB)
echo      ra download konid, NA "Source code (zip)" ra.
echo   3) momken ast antivirus baazi file-ha ra hazf karde bashad.
echo.
pause
goto END

:RUN
set "PYTHONIOENCODING=utf-8"
set "PYTHONUTF8=1"
"%PY_EXE%" "%LAUNCHER%"
if errorlevel 1 goto FAILED
goto END

:FAILED
echo.
echo [ERROR] Student360 exited with an error. Read the message above.
echo [khata] Barname ba khata motavaghef shod - peyghame bala ra bekhanid.
pause
goto END

:END
endlocal
