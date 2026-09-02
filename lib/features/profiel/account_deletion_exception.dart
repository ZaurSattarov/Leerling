class AccountDeletionException implements Exception {
  AccountDeletionException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
