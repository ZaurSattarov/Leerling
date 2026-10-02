#!/bin/zsh
# Dubbelklik in Finder, of voer uit met: ./Leerling\ Simulator.command
# Start de leerlingen-app in de iPhone Simulator in debugmodus, met hot reload.
set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
# Werkt ook als dit bestand op het bureaublad staat.
PROJECT_DIR="/Volumes/Externe SSD/Leerling"
cd "$PROJECT_DIR" || {
  echo "Projectmap niet gevonden: $PROJECT_DIR"
  read -r "?Druk op Enter om te sluiten... "
  exit 1
}

GOOGLE_SERVER_CLIENT_ID="864861187721-i87tu2n5l2aubmpi6oqs57t5bf1uqnkq.apps.googleusercontent.com"

fail() {
  echo
  echo "$1"
  read -r "?Druk op Enter om te sluiten... "
  exit 1
}

if ! command -v flutter >/dev/null 2>&1; then
  fail "Flutter niet gevonden. Installeer Flutter en probeer opnieuw."
fi

if ! xcrun simctl help >/dev/null 2>&1; then
  fail "Xcode-simulator niet gevonden. Installeer Xcode en de command line tools."
fi

echo "[1/3] iPhone-simulator zoeken..."

# Al opgestarte iPhone eerst, anders iPhone 18 Pro, anders de eerste iPhone.
UDID=$(xcrun simctl list devices available | awk '
  /iPhone/ && /Booted/ && udid == "" {
    if (match($0, /\([A-F0-9-]+\)/)) udid = substr($0, RSTART + 1, RLENGTH - 2)
  }
  END { print udid }
')

if [[ -z "${UDID}" ]]; then
  UDID=$(xcrun simctl list devices available | awk '
    /iPhone 18 Pro \(/ && $0 !~ /Max/ {
      if (match($0, /\([A-F0-9-]+\)/)) {
        print substr($0, RSTART + 1, RLENGTH - 2)
        exit
      }
    }
  ')
fi

if [[ -z "${UDID}" ]]; then
  UDID=$(xcrun simctl list devices available | awk '
    /iPhone/ {
      if (match($0, /\([A-F0-9-]+\)/)) {
        print substr($0, RSTART + 1, RLENGTH - 2)
        exit
      }
    }
  ')
fi

if [[ -z "${UDID}" ]]; then
  fail "Geen iPhone-simulator gevonden. Open Xcode en installeer een iOS-simulator."
fi

NAME=$(xcrun simctl list devices available | awk -v id="$UDID" '
  index($0, id) { sub(/ *\(.*/, ""); print; exit }
')

echo "[2/3] Simulator openen: ${NAME## } ..."
xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b

# Xcode 27 toont de simulator via Device Hub, niet via Simulator.app.
DEV_DIR="$(xcode-select -p)"
SIM_APP=""
for candidate in \
  "${DEV_DIR}/../Applications/DeviceHub.app" \
  "${DEV_DIR}/Applications/DeviceHub.app" \
  "${DEV_DIR}/Applications/Simulator.app" \
  "/Applications/Xcode.app/Contents/Applications/DeviceHub.app" \
  "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app"
do
  if [[ -d "$candidate" ]]; then
    SIM_APP="$candidate"
    break
  fi
done

if [[ -n "$SIM_APP" ]]; then
  open "$SIM_APP" --args -CurrentDeviceUDID "$UDID"
else
  open -a Simulator --args -CurrentDeviceUDID "$UDID" >/dev/null 2>&1 || true
fi

echo "[3/3] Debug-sessie starten (hot reload)..."
xcrun simctl terminate "$UDID" com.klantio.leerling >/dev/null 2>&1 || true
echo
echo "Laat dit venster open. Dit is de debug-sessie."
echo "  r  = hot reload"
echo "  R  = hot restart"
echo "  q  = stoppen"
echo

flutter run \
  -d "$UDID" \
  --debug \
  --hot \
  --pid-file "/tmp/klantio-leerling-debug.pid" \
  --dart-define="GOOGLE_SERVER_CLIENT_ID=${GOOGLE_SERVER_CLIENT_ID}"
exit_code=$?

echo
if [[ $exit_code -ne 0 ]]; then
  echo "Debug-start mislukt (code $exit_code)."
else
  echo "Debug-sessie gestopt."
fi
read -r "?Druk op Enter om te sluiten... "
exit $exit_code
