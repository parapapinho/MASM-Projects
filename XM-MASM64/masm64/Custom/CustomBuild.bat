@echo off
rem Easy Code custom-build entry point. Build both locations used by the IDE.
call "%~dp0..\build.bat" release
if errorlevel 1 exit /b 1
call "%~dp0..\build.bat" debug
exit /b %errorlevel%
