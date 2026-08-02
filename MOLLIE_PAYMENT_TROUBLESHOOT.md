# Mollie iDEAL Betaling - Troubleshoot Log

## Probleem
Leerling app toont "Kon betaallink niet aanmaken" bij iDEAL betaling.

## Wat al gedaan is

### 1. Edge Function `create-factuur-payment` opnieuw gedeployed
- Samen met `mollie-connect-refresh` (import dependency)
- Beide staan live op Supabase project `fbgjksxrehqyphaidgck`

### 2. Database gecheckt
- Facturen tabel heeft alle benodigde kolommen (mollie_payment_id, mollie_checkout_url, mollie_status, payment_method, payment_expires_at)
- Factuur KLT027 bestaat met correcte data (bedrag_cents=13915, instructeur_id, leerling_id)

### 3. Supabase Secrets gecheckt
- Alle secrets staan er: `SERVICE_ROLE_KEY`, `PROJECT_URL`, `MOLLIE_WEBHOOK_URL`, `MOLLIE_API_KEY`, `MOLLIE_CLIENT_ID`, `MOLLIE_CLIENT_SECRET`, `MOLLIE_CONNECT_REDIRECT_URL`

### 4. Debug logging toegevoegd aan edge function
- ENV check logging
- Mollie API error details worden nu als status 200 teruggestuurd (ipv 500) zodat Flutter client de data kan lezen
- Exacte Mollie error wordt meegestuurd in response

### 5. Debug logging toegevoegd aan Leerling app (NOG NIET GEBOUWD)
Twee bestanden zijn aangepast maar de APK is nog niet opnieuw gebouwd:

**`lib/core/services/student_service.dart` regel 284-286:**
```dart
// WAS:
} catch (e) {
  debugPrint('[requestMollieFactuurPayment] fout: $e');
  return {'error': e.toString()};
}

// NU:
} catch (e, st) {
  debugPrint('[requestMollieFactuurPayment] fout: $e\n$st');
  return {'error': 'DEBUG: $e'};
}
```

**`lib/features/facturen/factuur_detail_screen.dart` regel 362-368:**
```dart
// WAS:
} else {
  showAppSnackBar(
    context,
    'Kon betaallink niet aanmaken. Probeer later opnieuw.',
    isError: true,
  );
}

// NU:
} else {
  final errMsg = result['error']?.toString() ?? 'Onbekende fout';
  final mollieErr = result['mollie_error']?.toString() ?? '';
  showAppSnackBar(
    context,
    'Fout: $errMsg ${mollieErr.isNotEmpty ? "| $mollieErr" : ""}',
    isError: true,
  );
}
```

## Wat nu moet gebeuren

1. **Bouw nieuwe Leerling APK** met bovenstaande debug wijzigingen
2. **Test iDEAL betaling opnieuw** — de foutmelding toont nu de exacte error
3. **Stuur screenshot** van de nieuwe foutmelding naar Claude
4. **Mogelijke oorzaken:**
   - Mollie API key is test key en accepteert geen payments boven bepaald bedrag
   - Mollie API key is verlopen of niet actief
   - MOLLIE_WEBHOOK_URL is niet bereikbaar vanuit Mollie
   - Supabase Edge Function crasht bij import van `mollie-connect-refresh`
5. **Na fix:** verwijder debug code en zet error responses terug naar status 500

## Relevante bestanden (Instrecteur repo)
- `supabase/functions/create-factuur-payment/index.ts` — edge function die Mollie payment aanmaakt
- `supabase/functions/mollie-connect-refresh/index.ts` — token management (OAuth + API key fallback)
- `supabase/functions/mollie-factuur-webhook/index.ts` — webhook voor betaalstatus updates
- `supabase/functions/mollie-factuur-return/index.ts` — return URL na betaling

## Relevante bestanden (Leerling repo)
- `lib/core/services/student_service.dart` — `requestMollieFactuurPayment()` op regel 270
- `lib/features/facturen/factuur_detail_screen.dart` — `_startBetaling()` op regel 342
