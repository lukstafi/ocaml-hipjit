@echo off
rem Resolves the AMD HIP SDK location and exposes it through an NTFS junction
rem whose path contains no spaces (the SDK installs under "C:\Program Files").
rem This addresses: https://github.com/ocaml/ocaml/issues/13917
setlocal EnableDelayedExpansion
set "HP=%HIP_PATH%"
if not defined HP (
  for /f "tokens=2,*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v HIP_PATH 2^>nul ^| findstr HIP_PATH') do set "HP=%%B"
)
if not defined HP (
  for /d %%D in ("C:\Program Files\AMD\ROCm\*") do set "HP=%%D"
)
if "!HP:~-1!"=="\" set "HP=!HP:~0,-1!"
echo | set /p="%LOCALAPPDATA:\=/%/hip_path_link" > .\hip-path.txt
if not exist "%LOCALAPPDATA%\hip_path_link" (mklink /J "%LOCALAPPDATA%\hip_path_link" "!HP!")
endlocal
rem The no-newline "echo | set /p=" trick above leaves ERRORLEVEL=1; when the junction
rem already exists nothing resets it, which would fail every rebuild after the first.
exit /b 0
