class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fbgjksxrehqyphaidgck.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_ePSE3UhFPmTO3j3sYLC99w_n_Zvq9DG',
  );

  static const String authRedirectUrl = String.fromEnvironment(
    'AUTH_REDIRECT_URL',
    defaultValue: 'leerlingplanner://auth/reset-password',
  );

  static const String authConfirmRedirectUrl = String.fromEnvironment(
    'AUTH_CONFIRM_REDIRECT_URL',
    defaultValue: 'leerlingplanner://auth/confirm',
  );

  /// Web/serverClientId van de bestaande "Klantio Supabase Web" OAuth-client
  /// (Google Cloud-project klantio-32a15) -- nodig zodat het idToken dat
  /// google_sign_in op Android ophaalt de audience heeft die Supabase's
  /// Google-provider verwacht. Geen secret (Client ID's zijn publiek), maar
  /// bewust NIET hardcoded: totdat deze waarde is aangeleverd staat hij leeg
  /// i.p.v. een placeholder-ID, zodat een verkeerd/nep-ID nooit per ongeluk
  /// meegebouwd wordt.
  /// Gebruik: flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
}
