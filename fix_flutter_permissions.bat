@echo off
echo ========================================================
echo  Fixing Flutter permissions for normal (non-admin) usage
echo ========================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please right-click this file and select 'Run as administrator'.
    pause
    exit /b 1
)

echo Removing stale lockfiles...
del /f /q "C:\Program Files\flutter\bin\cache\*.lock*" 2>nul
del /f /q "C:\Program Files\flutter\bin\cache\lockfile" 2>nul

echo Granting normal user permissions to C:\Program Files\flutter...
icacls "C:\Program Files\flutter" /grant Users:(OI)(CI)F /T /C

echo Adding safe directory in git...
git config --system --add safe.directory "C:/Program Files/flutter"

echo ========================================================
echo  SUCCESS! Flutter can now be run from normal CMD/PowerShell.
echo ========================================================
pause
