@echo off
setlocal

set "ROOT=%~dp0"
cd /d "%ROOT%"

echo Flutter dev sessie starten voor leerling-app...
echo.
echo Gebruik daarna in deze terminal:
echo   r = hot reload
echo   R = hot restart
echo   q = stoppen
echo.

flutter run -d emulator-5554
