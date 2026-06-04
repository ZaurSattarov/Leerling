import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'student_service.dart';

class CommunicationService {
  CommunicationService._();

  static SupabaseClient get _client => Supabase.instance.client;
  static String? lastEmailError;

  static Future<bool> sendPasswordChangedSecurityEmail({
    required String to,
  }) {
    final email = to.trim();
    debugPrint('[email] sendPasswordChangedSecurityEmail(to: $email)');
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
    final session = _client.auth.currentSession;
    final accessToken = session?.accessToken;
    final authorizationToken = accessToken?.trim().isNotEmpty == true
        ? accessToken!
        : StudentService.supabaseAnonKey;
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
          'Authorization': 'Bearer $authorizationToken',
          'apikey': StudentService.supabaseAnonKey,
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[email] verzonden: $template naar $to');
        return true;
      }
      lastEmailError = 'HTTP ${response.statusCode}: ${response.body}';
      debugPrint('[email] fout: $lastEmailError');
      return false;
    } catch (e) {
      lastEmailError = e.toString();
      debugPrint('[email] exception: $e');
      return false;
    }
  }
}
