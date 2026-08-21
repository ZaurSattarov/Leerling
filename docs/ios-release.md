# iOS release: Klantio Leerling

Voer vóór een iOS-release eerst de lokale signingcontrole uit:

```zsh
./tooling/ios_release_preflight.sh
```

De controle stopt zonder archive of upload wanneer Firebase, Runner Bundle ID,
Team ID, het App Store-profiel, de Distribution-identity/private key of de
versieconfiguratie niet overeenkomen.

Bij een geslaagde controle maakt Xcode een archive en IPA met de bestaande
Klantio Leerling-gegevens:

```text
Bundle ID: com.klantio.leerling
Team ID: LLTU5D46PX
Profile: Klantio Leerling App Store
```

Gebruik vervolgens Xcode Organizer om uitsluitend naar de bestaande App Store
Connect-app **Klantio Leerling** te uploaden. Het script bevat geen certificaten,
private keys, provisioningprofielen of andere secrets.
