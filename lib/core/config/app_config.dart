class AppConfig {
  AppConfig._();

  // NB (2026-09-24): `supabaseUrl` + `supabaseAnonKey` blijven bewust een
  // hardcoded fallback houden. De anon-key hieronder is een Supabase
  // *publishable* key (prefix `sb_publishable_`), door Supabase's eigen
  // ontwerp bedoeld om client-side gebundeld te worden -- Row Level
  // Security is de daadwerkelijke autorisatiegrens, niet deze key. Het
  // vervangen door een verplichte `--dart-define` zou dev-flow bemoeilijken
  // zonder security-winst. Wél verplicht via `--dart-define` bij een
  // productie-release als er ooit meer dan één Supabase-project (staging/
  // prod) komt -- dat is dan een aparte omzetting, niet een security-fix.
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

  /// App ID van de Meta for Developers-app ("Facebook Login"-product) --
  /// nodig voor de native Facebook Limited-Login-flow. Gebruik:
  /// flutter run --dart-define=FACEBOOK_APP_ID=xxxxxxxxxx
  static const String facebookAppId = String.fromEnvironment(
    'FACEBOOK_APP_ID',
  );

  /// Client Token van dezelfde Meta for Developers-app (Instellingen >
  /// Geavanceerd > Beveiliging, "Clienttoken"). Vereist door het Facebook
  /// Android/iOS SDK naast de App ID. Gebruik:
  /// flutter run --dart-define=FACEBOOK_CLIENT_TOKEN=xxxxxxxxxx
  static const String facebookClientToken = String.fromEnvironment(
    'FACEBOOK_CLIENT_TOKEN',
  );
}
