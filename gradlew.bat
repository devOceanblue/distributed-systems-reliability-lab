@echo off
where gradle >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
  echo gradle command not found. Install Gradle to use this lightweight wrapper.
  exit /b 1
)
call gradle %*
