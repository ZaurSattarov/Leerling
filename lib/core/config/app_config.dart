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
}
