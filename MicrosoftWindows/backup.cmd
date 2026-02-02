@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ================= CONFIGURATION =================
set "DEST=E:\GNEPostRetirement\Windows"
set "SAFETY_FACTOR=1.1"

echo ----------------------------------------
echo Windows Backup - GNE Post Retirement
echo ----------------------------------------

if not exist "%DEST%" mkdir "%DEST%"

REM ================= SPACE CHECK =================
echo Calculating required space...
set "TEMP_PS=%TEMP%\calc_space.ps1"
echo $sources = @('C:\Users', 'F:\') > "%TEMP_PS%"
echo $totalSize = 0 >> "%TEMP_PS%"
echo foreach ($src in $sources) { if (Test-Path $src) { $totalSize += (Get-ChildItem $src -Recurse -Force -Attributes !ReparsePoint -ErrorAction SilentlyContinue ^| Measure-Object -Property Length -Sum).Sum } } >> "%TEMP_PS%"
echo $free = (Get-PSDrive -Name E).Free >> "%TEMP_PS%"
echo $required = [math]::Ceiling($totalSize * %SAFETY_FACTOR%) >> "%TEMP_PS%"
echo $enough = $free -gt $required >> "%TEMP_PS%"
echo Write-Output "$enough|$([math]::Round($free/1GB,2))|$([math]::Round($required/1GB,2))" >> "%TEMP_PS%"

for /f "tokens=1,2,3 delims=|" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP_PS%"') do (
    set "ENOUGH_SPACE=%%A"
    set "FREE_GB=%%B"
    set "REQ_GB=%%C"
)
if exist "%TEMP_PS%" del "%TEMP_PS%"

echo Available space on E:  %FREE_GB% GB
echo Required space:        %REQ_GB% GB
if /I "%ENOUGH_SPACE%"=="False" (
    echo ERROR: Insufficient space.
    pause & exit /b
)

echo.
echo Starting Backup...

REM --- C DRIVE ---
if exist "C:\Users" (
    echo Backing up C:\Users...
    robocopy "C:\Users" "%DEST%\C\Users" /E /COPY:DAT /DCOPY:T /XJ /R:2 /W:2 /V /TEE /XD AppData "Application Data" "Package Cache" /XF *.tmp *.log *.bak *~
)

REM --- F DRIVE ---
if exist "F:\" (
    echo Backing up F:\...
    REM Notice the "F:\ " (with a space) - this prevents the backslash from breaking the quote
    robocopy "F:\ " "%DEST%\F" /E /COPY:DAT /DCOPY:T /XJ /R:2 /W:2 /V /TEE /XD AppData "Application Data" "Package Cache" /XF *.tmp *.log *.bak *~
)

echo.
echo ----------------------------------------
echo Backup process finished.
echo ----------------------------------------
pause
