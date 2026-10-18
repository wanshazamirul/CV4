@echo off
rem CV4 trust helper for cmd and PowerShell: locates Git Bash and runs trust-home.sh.
rem Usage:  trust-home.cmd     (from anywhere; double-click also works)
setlocal
for %%B in ("%ProgramFiles%\Git\bin\bash.exe" "%ProgramFiles(x86)%\Git\bin\bash.exe" "%LocalAppData%\Programs\Git\bin\bash.exe") do (
  if exist %%B (
    "%%~B" "%~dp0trust-home.sh" %*
    exit /b %errorlevel%
  )
)
where bash >nul 2>nul
if %errorlevel%==0 (
  bash "%~dp0trust-home.sh" %*
  exit /b %errorlevel%
)
echo trust-home: Git Bash (Git for Windows) is required for this helper.
echo Get it at https://git-scm.com/download/win, then rerun.
exit /b 1
