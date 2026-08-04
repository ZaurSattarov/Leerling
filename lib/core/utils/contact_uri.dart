class ContactUri {
  ContactUri._();

  static Uri? tel(String? telefoon) {
    final normalized = normalizedPhone(telefoon, keepPlus: true);
    if (normalized == null) return null;
    return Uri(scheme: 'tel', path: normalized);
  }

  static Uri? email(String? email, {String? subject}) {
    final value = email?.trim();
    if (value == null || !_isValidEmail(value)) return null;
    return Uri(
      scheme: 'mailto',
      path: value,
      queryParameters: subject == null || subject.trim().isEmpty
          ? null
          : {'subject': subject.trim()},
    );
  }

  static Uri? whatsapp(String? telefoon) {
    final normalized = normalizedPhone(telefoon, keepPlus: false);
    if (normalized == null) return null;
    return Uri.https('wa.me', '/$normalized');
  }

  static String? normalizedPhone(String? telefoon, {required bool keepPlus}) {
    final raw = telefoon?.trim();
    if (raw == null || raw.isEmpty) return null;
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final char = raw[i];
      final isDigit = char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
      if (isDigit || (keepPlus && char == '+' && buffer.isEmpty)) {
        buffer.write(char);
      }
    }
    final value = buffer.toString();
    final digits = value.replaceAll('+', '');
    if (digits.length < 6) return null;
    return value;
  }

  static bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }
}
