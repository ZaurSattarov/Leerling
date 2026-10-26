@echo off
set "PROJECT_DIR=%~dp0"
set "FLUTTER=%USERPROFILE%\Documents\flutter\bin\flutter.bat"
set "FLUTTER_LOCAL=C:\flutter\bin\flutter.bat"
set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
set "EMULATOR=%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe"
set "APP_ID=com.klantio.leerling"
set "MAIN_ACTIVITY=com.klantio.leerling.MainActivity"
rem Standaard geen runtime-rechten en geen wissen. Alleen met --grant of --wipe.
set "GRANT=0"
set "WIPE=0"
for %%A in (%*) do (
    if /I "%%A"=="--grant" set "GRANT=1"
    if /I "%%A"=="--wipe" set "WIPE=1"
)
set "INSTALL_FLAGS=-r -d --no-streaming"
if "%GRANT%"=="1" set "INSTALL_FLAGS=-r -d -g --no-streaming"
rem Google-login (google_sign_in) heeft op Android een serverClientId nodig
rem zodat het idToken de audience heeft die Supabase's Google-provider
rem verwacht -- zonder deze dart-define blijft AppConfig.googleServerClientId
rem leeg en faalt Google-login met "Google-login is momenteel niet
rem beschikbaar." Client ID is publiek (geen secret), Client Secret staat
rem hier bewust NIET.
set "GOOGLE_DART_DEFINE=--dart-define=GOOGLE_SERVER_CLIENT_ID=864861187721-i87tu2n5l2aubmpi6oqs57t5bf1uqnkq.apps.googleusercontent.com"

if not exist "%PROJECT_DIR%pubspec.yaml" (
    echo PROJECTMAP NIET GEVONDEN: %PROJECT_DIR%
    pause
    exit /b 1
)

if not exist "%FLUTTER%" (
    if exist "%FLUTTER_LOCAL%" (
        set "FLUTTER=%FLUTTER_LOCAL%"
    ) else (
        set "FLUTTER=flutter"
    )
)

if not exist "%ADB%" (
    echo ADB NIET GEVONDEN: %ADB%
    pause
    exit /b 1
)

if not exist "%EMULATOR%" (
    echo EMULATOR.EXE NIET GEVONDEN: %EMULATOR%
    pause
    exit /b 1
)

rem Zoek de draaiende emulator (serial is niet altijd emulator-5554)
set "SERIAL="
"%ADB%" start-server >nul 2>&1
"%ADB%" devices > "%TEMP%\adb_devices.txt" 2>&1
for /f "tokens=1,2" %%S in ('findstr /b "emulator-" "%TEMP%\adb_devices.txt"') do (
    if "%%T"=="device" if not defined SERIAL set "SERIAL=%%S"
)
if not defined SERIAL (
    echo GEEN DRAAIENDE EMULATOR GEVONDEN. Start eerst een emulator.
    "%ADB%" devices
    pause
    exit /b 1
)
echo Emulator: %SERIAL%
"%ADB%" -s %SERIAL% wait-for-device
call :WaitForBoot

set "AVD_NAME="
"%ADB%" -s %SERIAL% emu avd name > "%TEMP%\adb_avd.txt" 2>nul
for /f "tokens=* usebackq" %%A in (`findstr /v /r "^OK$" "%TEMP%\adb_avd.txt"`) do (
    if not defined AVD_NAME set "AVD_NAME=%%A"
)
if not defined AVD_NAME set "AVD_NAME=Pixel_10_Pro"

cd /d "%PROJECT_DIR%"

echo [1/4] Emulator ruimte vrijmaken...
call :CleanEmulator

echo [2/4] Bouwen...
call "%FLUTTER%" build apk --debug --target-platform android-x64 %GOOGLE_DART_DEFINE%
if errorlevel 1 (
    echo BUILD MISLUKT
    pause
    exit /b 1
)

echo [3/4] Installeren...
echo APK installeren zonder streamed install...
"%ADB%" -s %SERIAL% install %INSTALL_FLAGS% "build\app\outputs\flutter-apk\app-debug.apk"
if errorlevel 1 (
    echo Eerste installatiepoging mislukt. Extra opruimen en opnieuw proberen...
    call :CleanEmulatorDeep
    "%ADB%" -s %SERIAL% install %INSTALL_FLAGS% "build\app\outputs\flutter-apk\app-debug.apk"
    if errorlevel 1 (
        echo INSTALLATIE MISLUKT
        if not "%WIPE%"=="1" (
            echo Wissen staat uit. Start het script opnieuw met --wipe als je de emulator-data bewust wilt wissen.
            pause
            exit /b 1
        )
        echo Emulator stoppen...
        "%ADB%" -s %SERIAL% emu kill >nul 2>&1
        timeout /t 5 >nul
        echo Emulator opnieuw starten met wipe-data...
        start "" "%EMULATOR%" -avd "%AVD_NAME%" -wipe-data -no-snapshot-load
        echo Wachten tot emulator klaar is...
        "%ADB%" -s %SERIAL% wait-for-device
        call :WaitForBoot
        timeout /t 5 >nul
        echo Opnieuw installeren na wipe...
        call :CleanEmulator
        "%ADB%" -s %SERIAL% install %INSTALL_FLAGS% "build\app\outputs\flutter-apk\app-debug.apk"
        if errorlevel 1 (
            echo INSTALLATIE MISLUKT NA WIPE
            pause
            exit /b 1
        )
    )
)

echo [4/4] Openen...
"%ADB%" -s %SERIAL% shell am start -n "%APP_ID%/%MAIN_ACTIVITY%"
if errorlevel 1 (
    echo STARTEN MISLUKT
    pause
    exit /b 1
)

echo.
echo Klaar!
timeout /t 2 >nul
exit /b 0

:CleanEmulator
echo Opslag emulator voor opruimen:
"%ADB%" -s %SERIAL% shell df -h /data
echo Oude app en tijdelijke bestanden opruimen...
"%ADB%" -s %SERIAL% uninstall "%APP_ID%" >nul 2>&1
"%ADB%" -s %SERIAL% shell pm trim-caches 999G >nul 2>&1
"%ADB%" -s %SERIAL% shell rm -f /data/local/tmp/*.apk >nul 2>&1
"%ADB%" -s %SERIAL% shell rm -f /data/local/tmp/*.tmp >nul 2>&1
"%ADB%" -s %SERIAL% shell rm -f /data/local/tmp/flutter_* >nul 2>&1
echo Opslag emulator na opruimen:
"%ADB%" -s %SERIAL% shell df -h /data
exit /b 0

:CleanEmulatorDeep
echo Extra emulator-opruiming...
"%ADB%" -s %SERIAL% shell df -h /data
"%ADB%" -s %SERIAL% uninstall "%APP_ID%" >nul 2>&1
"%ADB%" -s %SERIAL% shell pm trim-caches 999G >nul 2>&1
"%ADB%" -s %SERIAL% shell rm -rf /data/local/tmp/* >nul 2>&1
"%ADB%" -s %SERIAL% shell rm -rf /data/data/%APP_ID%/cache >nul 2>&1
"%ADB%" -s %SERIAL% shell rm -rf /sdcard/Android/data/%APP_ID%/cache >nul 2>&1
"%ADB%" -s %SERIAL% shell df -h /data
exit /b 0

:WaitForBoot
set "BOOT_DONE="
"%ADB%" -s %SERIAL% shell getprop sys.boot_completed > "%TEMP%\adb_boot.txt" 2>nul
for /f "tokens=* usebackq" %%B in (`type "%TEMP%\adb_boot.txt"`) do set "BOOT_DONE=%%B"
if not "%BOOT_DONE%"=="1" (
    timeout /t 3 >nul
    goto WaitForBoot
)
exit /b 0

