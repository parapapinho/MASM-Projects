@echo off
setlocal EnableExtensions DisableDelayedExpansion
pushd "%~dp0"
set "XM_CONFIG=Release"
set "XM_ASM_DEBUG="
set "XM_LINK_DEBUG="
if /i "%~1"=="debug" (
    set "XM_CONFIG=Debug"
    set "XM_ASM_DEBUG=/Zi"
    set "XM_LINK_DEBUG=/DEBUG"
)

rem Prefer a correctly configured x64 Visual Studio toolchain.
if /i "%VSCMD_ARG_TGT_ARCH%"=="x64" goto tools
set "XM_VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%XM_VSWHERE%" goto tools
set "XM_VSROOT="
for /f "usebackq tokens=*" %%V in (`"%XM_VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "XM_VSROOT=%%V"
if not defined XM_VSROOT goto tools
call "%XM_VSROOT%\Common7\Tools\VsDevCmd.bat" -no_logo -arch=x64 -host_arch=x64
if errorlevel 1 goto failed

:tools
for %%T in (ml64.exe link.exe lib.exe rc.exe powershell.exe) do (
    where %%T >nul 2>nul
    if errorlevel 1 (
        echo Missing %%T. Use an x64 Native Tools Command Prompt with the Windows SDK installed.
        goto failed
    )
)
if not exist "build\%XM_CONFIG%" mkdir "build\%XM_CONFIG%"
if not exist "%XM_CONFIG%" mkdir "%XM_CONFIG%"
if not exist "lib" mkdir "lib"

rem Easy Code may save modules as UTF-16. Normalize only build copies.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $enc=New-Object System.Text.UTF8Encoding($false); foreach($name in @('XM64','XMPlayer64')) { $text=[IO.File]::ReadAllText((Join-Path $pwd ('src\'+$name+'.asm'))); [IO.File]::WriteAllText((Join-Path $pwd ('build\'+$env:XM_CONFIG+'\'+$name+'.asm')),$text,$enc) }; $text=[IO.File]::ReadAllText((Join-Path $pwd 'include\XMPlayer64.inc')); [IO.File]::WriteAllText((Join-Path $pwd ('build\'+$env:XM_CONFIG+'\XMPlayer64.inc')),$text,$enc)"
if errorlevel 1 goto failed

ml64.exe /nologo /c %XM_ASM_DEBUG% /I"build\%XM_CONFIG%" /Fo"build\%XM_CONFIG%\XMPlayer64.obj" "build\%XM_CONFIG%\XMPlayer64.asm"
if errorlevel 1 goto failed
lib.exe /nologo /machine:x64 /out:"lib\XMPlayer64.lib" "build\%XM_CONFIG%\XMPlayer64.obj"
if errorlevel 1 goto failed
ml64.exe /nologo /c %XM_ASM_DEBUG% /I"build\%XM_CONFIG%" /Fo"build\%XM_CONFIG%\XM64.obj" "build\%XM_CONFIG%\XM64.asm"
if errorlevel 1 goto failed
rc.exe /nologo /fo "build\%XM_CONFIG%\XM64.res" Res\XM64.rc
if errorlevel 1 goto failed
link.exe /nologo /machine:x64 /subsystem:windows /entry:start /dynamicbase /nxcompat /highentropyva /incremental:no %XM_LINK_DEBUG% /out:"%XM_CONFIG%\XM64.exe" "build\%XM_CONFIG%\XM64.obj" "build\%XM_CONFIG%\XM64.res" lib\XMPlayer64.lib third_party\bass\x64\bass.lib kernel32.lib user32.lib
if errorlevel 1 goto failed
copy /y third_party\bass\x64\bass.dll "%XM_CONFIG%\bass.dll" >nul
if errorlevel 1 goto failed
echo.
echo Built: %XM_CONFIG%\XM64.exe
echo Library: lib\XMPlayer64.lib
popd
endlocal
exit /b 0

:failed
echo.
echo Build failed. See the first error above.
popd
endlocal
exit /b 1
