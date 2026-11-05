@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Start-TMVisuals.ps1" %*
if errorlevel 1 (
  echo.
  echo TM Visuals could not start. Read the message above or see SETUP.md.
  pause
  exit /b 1
)
