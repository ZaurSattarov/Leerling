@echo off
setlocal

set "ROOT=%~dp0"
cd /d "%ROOT%"

set "ADB_EXE=C:\Users\z.sattarov\AppData\Local\Android\Sdk\platform-tools\adb.exe"
set "APK_PATH=%ROOT%android\app\build\outputs\apk\debug\app-debug.apk"
set "PACKAGE_NAME=nl.rijschool.leerling_app"

echo.
echo [1/5] Controleren op adb...
if not exist "%ADB_EXE%" (
  echo adb.exe niet gevonden op:
  echo %ADB_EXE%
  exit /b 1
)

echo.
echo [2/5] Controleren op emulator...
set "HAS_DEVICE="
for /f "skip=1 tokens=1,2" %%A in ('"%ADB_EXE%" devices') do (
  if "%%B"=="device" set "HAS_DEVICE=1"
  if "%%B"=="unauthorized" (
    echo Emulator is unauthorized. Accepteer eerst adb debugging op de emulator.
    exit /b 1
  )
)

if not defined HAS_DEVICE (
  echo Geen draaiende emulator gevonden. Start eerst je Android emulator.
  exit /b 1
)

echo.
echo [3/5] Debug APK bouwen...
cd /d "%ROOT%android"
call gradlew app:assembleDebug
if errorlevel 1 (
  echo Build mislukt.
  exit /b 1
)

if not exist "%APK_PATH%" (
  echo APK niet gevonden:
  echo %APK_PATH%
  exit /b 1
)

echo.
echo [4/5] APK installeren...
"%ADB_EXE%" install -r "%APK_PATH%"
if errorlevel 1 (
  echo Installatie mislukt.
  exit /b 1
)

echo.
echo [5/5] App starten...
"%ADB_EXE%" shell monkey -p %PACKAGE_NAME% -c android.intent.category.LAUNCHER 1 >nul

echo.
echo Klaar. De leerling-app staat opnieuw op de emulator.
exit /b 0
