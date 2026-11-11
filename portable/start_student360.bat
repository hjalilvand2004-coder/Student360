@echo off
title Student360 - Portable Edition
cd /d "%~dp0"
set PYTHONIOENCODING=utf-8
set PYTHONUTF8=1
echo Starting Student360 (portable mode) ...
"runtime\python.exe" "app\launch_portable.py"
if errorlevel 1 (
  echo.
  echo [ERROR] Student360 failed to start. Read the message above.
  pause
)
