import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'student_service.dart';

class CommunicationService {
  CommunicationService._();

  static SupabaseClient get _client => Supabase.instance.client;
  static String? lastEmailError;

  /// AVG-hardening (2026-09-24): e-mailadressen mogen niet plaintext in de
  /// systeemlog belanden (debugPrint schrijft in release óók naar logcat/
  /// oslog — hoewel [installReleaseLogGuard] dat in release al blokkeert,
  /// blijft dit een defense-in-depth-masker voor debug-builds).
  /// `john.doe@example.com` -> `j***@example.com`.
  static String _maskEmail(String email) {
    final trimmed = email.trim();
    final at = trimmed.indexOf('@');
    if (at <= 0) return '***';
    final first = trimmed.substring(0, 1);
    return '$first***${trimmed.substring(at)}';
  }

  static Future<bool> sendPasswordChangedSecurityEmail({
    required String to,
  }) {
    final email = to.trim();
    debugPrint('[email] sendPasswordChangedSecurityEmail(to: ${_maskEmail(email)})');
    if (email.isEmpty) {
      lastEmailError = 'Geen e-mailadres voor securitymail';
      return Future.value(false);
    }
    return sendEmail(
      template: 'password_changed',
      to: email,
      subject: 'Je wachtwoord is gewijzigd',
    );
  }

  static Future<bool> sendEmail({
    required String template,
    required String to,
    Map<String, String> variables = const {},
    String? subject,
  }) async {
    lastEmailError = null;
    final url = Uri.parse(
        '${StudentService.supabaseUrl}/functions/v1/send-email');
    // Security (2026-09-24): geen fallback meer naar de publishable/anon-key
    // als er geen sessie is. Die fallback was zowel een AVG-risico (een
    // unauthenticated caller kon e-mails triggeren) áls stuk sinds de
    // Instrecteur `send-email` authz-gate publishable keys weigert. Zonder
    // sessie: hard falen met een leesbare fout.
    final session = _client.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null || accessToken.trim().isEmpty) {
      lastEmailError = 'Geen actieve sessie — e-mail niet verstuurd';
      debugPrint('[email] geweigerd: geen sessie');
      return false;
    }
    final payload = <String, dynamic>{
      'template': template,
      'to': to,
      if (subject != null) 'subject': subject,
      if (variables.isNotEmpty) 'variables': variables,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'apikey': StudentService.supabaseAnonKey,
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[email] verzonden: $template naar ${_maskEmail(to)}');
        return true;
      }
      // Response-body kan een echo van de payload bevatten (inclusief `to`);
      // dus niet volledig loggen, alleen statuscode.
      lastEmailError = 'HTTP ${response.statusCode}';
      debugPrint('[email] fout: HTTP ${response.statusCode}');
      return false;
    } catch (e) {
      lastEmailError = e.toString();
      debugPrint('[email] exception: ${e.runtimeType}');
      return false;
    }
  }
}
