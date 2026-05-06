@echo off
setlocal EnableExtensions

cd /d "%~dp0"

set "APP_ID=nl.rijschool.leerling_app"
set "ADB_EXE=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
set "APK_PATH=%CD%\build\app\outputs\flutter-apk\app-debug.apk"
set "DISABLED_DESKTOP=0"

echo =================================================
echo Rijschool Leerling App - clean build + install debug
echo =================================================
echo.

if not exist "%ADB_EXE%" (
  echo FOUT: adb.exe niet gevonden:
  echo   %ADB_EXE%
  echo.
  goto fail_before_desktop_change
)

where flutter >nul 2>&1
if errorlevel 1 (
  echo FOUT: flutter command niet gevonden in PATH.
  echo Open dit script vanuit een terminal waar Flutter werkt.
  echo.
  goto fail_before_desktop_change
)

echo [1/9] Android device/emulator controleren...
"%ADB_EXE%" devices
if errorlevel 1 (
  echo.
  echo FOUT: adb devices mislukt.
  goto fail_before_desktop_change
)
echo.

echo [2/9] Desktop platformmappen tijdelijk uitschakelen...
echo Dit voorkomt symlink/Developer Mode meldingen tijdens Android builds.
call :disable_desktop_platforms
if errorlevel 1 goto fail
echo.

echo [3/9] Desktop build support in Flutter config uitschakelen...
call flutter config --no-enable-windows-desktop --no-enable-linux-desktop --no-enable-macos-desktop
if errorlevel 1 (
  echo.
  echo FOUT: flutter config mislukt.
  goto fail
)
echo.

echo [4/9] Flutter build cache opschonen...
call flutter clean
if errorlevel 1 (
  echo.
  echo FOUT: flutter clean mislukt.
  goto fail
)
echo.

echo [5/9] Dependencies ophalen...
call flutter pub get
if errorlevel 1 (
  echo.
  echo FOUT: flutter pub get mislukt.
  goto fail
)
echo.

echo [6/9] Debug APK bouwen...
call flutter build apk --debug
if errorlevel 1 (
  echo.
  echo FOUT: Flutter build mislukt.
  goto fail
)

if not exist "%APK_PATH%" (
  echo.
  echo FOUT: APK niet gevonden:
  echo   %APK_PATH%
  goto fail
)
echo.

echo Desktop platformmappen herstellen...
if exist ".android-build-disabled-windows" ren ".android-build-disabled-windows" "windows"
if errorlevel 1 goto fail_before_desktop_change
if exist ".android-build-disabled-linux" ren ".android-build-disabled-linux" "linux"
if errorlevel 1 goto fail_before_desktop_change
if exist ".android-build-disabled-macos" ren ".android-build-disabled-macos" "macos"
if errorlevel 1 goto fail_before_desktop_change
echo.

echo [7/9] Oude app verwijderen...
"%ADB_EXE%" uninstall "%APP_ID%" >nul 2>&1
echo Oude installatie verwijderd of was niet aanwezig.
echo.

echo [8/9] Nieuwe APK installeren...
"%ADB_EXE%" install "%APK_PATH%"
if errorlevel 1 (
  echo.
  echo FOUT: Installeren mislukt.
  goto fail_before_desktop_change
)
echo.

echo [9/9] App starten...
"%ADB_EXE%" shell monkey -p "%APP_ID%" -c android.intent.category.LAUNCHER 1
if errorlevel 1 (
  echo.
  echo App is geinstalleerd, maar starten via adb is mislukt.
  goto fail_before_desktop_change
)

echo.
echo Klaar. Schone debug build is geinstalleerd en gestart.
echo APK:
echo   %APK_PATH%
echo.
pause
exit /b 0

:fail
echo.
echo Desktop platformmappen herstellen...
if exist ".android-build-disabled-windows" ren ".android-build-disabled-windows" "windows"
if exist ".android-build-disabled-linux" ren ".android-build-disabled-linux" "linux"
if exist ".android-build-disabled-macos" ren ".android-build-disabled-macos" "macos"
echo.

:fail_before_desktop_change
pause
exit /b 1

:disable_desktop_platforms
if exist ".android-build-disabled-windows" (
  echo FOUT: tijdelijke map bestaat al: .android-build-disabled-windows
  echo Hernoem deze map eerst terug naar windows of verwijder hem als hij leeg is.
  exit /b 1
)
if exist ".android-build-disabled-linux" (
  echo FOUT: tijdelijke map bestaat al: .android-build-disabled-linux
  echo Hernoem deze map eerst terug naar linux of verwijder hem als hij leeg is.
  exit /b 1
)
if exist ".android-build-disabled-macos" (
  echo FOUT: tijdelijke map bestaat al: .android-build-disabled-macos
  echo Hernoem deze map eerst terug naar macos of verwijder hem als hij leeg is.
  exit /b 1
)

if exist "windows" (
  ren "windows" ".android-build-disabled-windows"
  if errorlevel 1 exit /b 1
  set "DISABLED_DESKTOP=1"
)
if exist "linux" (
  ren "linux" ".android-build-disabled-linux"
  if errorlevel 1 exit /b 1
  set "DISABLED_DESKTOP=1"
)
if exist "macos" (
  ren "macos" ".android-build-disabled-macos"
  if errorlevel 1 exit /b 1
  set "DISABLED_DESKTOP=1"
)

if "%DISABLED_DESKTOP%"=="1" (
  echo Desktop platformmappen tijdelijk uitgeschakeld.
) else (
  echo Geen desktop platformmappen gevonden.
)
exit /b 0
