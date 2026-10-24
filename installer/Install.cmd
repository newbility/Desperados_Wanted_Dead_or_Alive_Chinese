@echo off
powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File "%~dp0SelectGamePath.ps1" %*
pause
