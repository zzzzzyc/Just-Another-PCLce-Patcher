@echo off
if "%~1"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-PCL.ps1" -Configure
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-PCL.ps1" %*
)
set "code=%errorlevel%"
if "%code%"=="10" goto cleanup
if not "%code%"=="0" pause
exit /b %code%

:cleanup
(goto) 2>nul & del "%~f0"
