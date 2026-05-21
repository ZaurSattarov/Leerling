class AppConfig {
  AppConfig._();

  static const String authRedirectUrl = String.fromEnvironment(
    'AUTH_REDIRECT_URL',
    defaultValue: 'leerlingplanner://auth/reset-password',
  );

  static const String authConfirmRedirectUrl = String.fromEnvironment(
    'AUTH_CONFIRM_REDIRECT_URL',
    defaultValue: 'leerlingplanner://auth/confirm',
  );
}
