import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/leerling_profiel.dart';
import '../../models/les.dart';
import '../../models/factuur.dart';
import '../../models/notificatie.dart';
import '../../models/instructeur.dart';

class StudentService {
  static const String supabaseUrl =
      'https://fbgjksxrehqyphaidgck.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_ePSE3UhFPmTO3j3sYLC99w_n_Zvq9DG';

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static String get userId => currentUser!.id;

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // AUTH
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<AuthResponse> inloggen({
    required String email,
    required String wachtwoord,
  }) {
    return client.auth.signInWithPassword(
      email: email,
      password: wachtwoord,
    );
  }

  static Future<AuthResponse> registreren({
    required String email,
    required String wachtwoord,
  }) async {
    final trimmedEmail = email.trim();
    debugPrint('[student.registreren] email=' + trimmedEmail);

    try {
      final response = await client.auth.signUp(
        email: trimmedEmail,
        password: wachtwoord,
      );
      debugPrint('[student.registreren] user=' + (response.user?.id ?? 'null') + ' session=' + (response.session != null).toString());
      return response;
    } on AuthException catch (e) {
      debugPrint('[student.registreren] AuthException code=' + (e.statusCode ?? 'null') + ' message=' + e.message);
      rethrow;
    } catch (e) {
      debugPrint('[student.registreren] onverwachte fout=' + e.toString());
      rethrow;
    }
  }

  static Future<void> uitloggen() => client.auth.signOut();

  static Future<void> stuurWachtwoordReset(String email) {
    return client.auth.resetPasswordForEmail(email);
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // KOPPELING
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<void> koppelLeerlingMetCode(String koppelCode) async {
    final res = await client.rpc(
      'koppel_leerling_met_code',
      params: {'p_koppel_code': koppelCode.trim().toUpperCase()},
    ) as Map<String, dynamic>;
    if (res['succes'] != true) {
      throw Exception(res['fout'] ?? 'Koppelen mislukt');
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // LEERLING PROFIEL (eigen profiel via user_id)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<LeerlingProfiel?> getMijnProfiel() async {
    final res = await client
        .from('leerlingen')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return res != null ? LeerlingProfiel.fromJson(res) : null;
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // INSTRUCTEUR (read-only, via leerling.instructeur_id)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<Instructeur?> getMijnInstructeur(String instructeurId) async {
    final res = await client
        .from('instructeur_profielen')
        .select('id, rijschool_naam, naam, telefoon, email, adres, postcode, stad, logo_url, whatsapp_nummer')
        .eq('id', instructeurId)
        .maybeSingle();
    return res != null ? Instructeur.fromJson(res) : null;
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // LESSEN
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<List<Les>> getMijnLessen(String leerlingId) async {
    final res = await client
        .from('lessen')
        .select('*, instructeur_profielen(naam, telefoon)')
        .eq('leerling_id', leerlingId)
        .order('datum', ascending: false)
        .order('starttijd', ascending: false);
    return (res as List).map((e) => Les.fromJson(e)).toList();
  }

  static Future<List<Les>> getMijnKomendeLessen(String leerlingId) async {
    final vandaag = DateTime.now();
    final vandaagStr =
        '${vandaag.year}-${vandaag.month.toString().padLeft(2, '0')}-${vandaag.day.toString().padLeft(2, '0')}';
    final res = await client
        .from('lessen')
        .select('*, instructeur_profielen(naam, telefoon)')
        .eq('leerling_id', leerlingId)
        .eq('status', 'gepland')
        .gte('datum', vandaagStr)
        .order('datum')
        .order('starttijd')
        .limit(50);
    return (res as List).map((e) => Les.fromJson(e)).toList();
  }

  static Future<List<Les>> getMijnVorigeLessen(String leerlingId) async {
    final vandaag = DateTime.now();
    final vandaagStr =
        '${vandaag.year}-${vandaag.month.toString().padLeft(2, '0')}-${vandaag.day.toString().padLeft(2, '0')}';
    final res = await client
        .from('lessen')
        .select('*, instructeur_profielen(naam, telefoon)')
        .eq('leerling_id', leerlingId)
        .neq('status', 'gepland')
        .or('datum.lt.$vandaagStr,status.eq.afgerond,status.eq.geannuleerd,status.eq.geen_toon')
        .order('datum', ascending: false)
        .order('starttijd', ascending: false)
        .limit(100);
    return (res as List).map((e) => Les.fromJson(e)).toList();
  }

  static Future<Les?> getLes(String lesId) async {
    final res = await client
        .from('lessen')
        .select('*, instructeur_profielen(naam, telefoon, whatsapp_nummer)')
        .eq('id', lesId)
        .maybeSingle();
    return res != null ? Les.fromJson(res) : null;
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // FACTUREN
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<List<Factuur>> getMijnFacturen(String leerlingId) async {
    final res = await client
        .from('facturen')
        .select()
        .eq('leerling_id', leerlingId)
        .order('aangemaakt_op', ascending: false);
    return (res as List).map((e) => Factuur.fromJson(e)).toList();
  }

  static Future<Factuur?> getFactuur(String id) async {
    final res = await client
        .from('facturen')
        .select()
        .eq('id', id)
        .maybeSingle();
    return res != null ? Factuur.fromJson(res) : null;
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // NOTIFICATIES
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<List<Notificatie>> getMijnNotificaties(
      String leerlingId) async {
    final res = await client
        .from('leerling_notificaties')
        .select()
        .eq('leerling_id', leerlingId)
        .order('aangemaakt_op', ascending: false)
        .limit(50);
    return (res as List).map((e) => Notificatie.fromJson(e)).toList();
  }

  static Future<void> markeerGelezen(String notificatieId) async {
    await client
        .from('leerling_notificaties')
        .update({'gelezen': true}).eq('id', notificatieId);
  }

  static Future<void> markeerAllesGelezen(String leerlingId) async {
    await client
        .from('leerling_notificaties')
        .update({'gelezen': true})
        .eq('leerling_id', leerlingId)
        .eq('gelezen', false);
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // HOME DASHBOARD (parallel fetch)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<Map<String, dynamic>> getHomeDashboard(
      String leerlingId, String instructeurId) async {
    final vandaag = DateTime.now();
    final vandaagStr =
        '${vandaag.year}-${vandaag.month.toString().padLeft(2, '0')}-${vandaag.day.toString().padLeft(2, '0')}';

    final results = await Future.wait([
      // 0: volgende les
      client
          .from('lessen')
          .select('*, instructeur_profielen(naam, telefoon)')
          .eq('leerling_id', leerlingId)
          .eq('status', 'gepland')
          .gte('datum', vandaagStr)
          .order('datum')
          .order('starttijd')
          .limit(1),
      // 1: open facturen
      client
          .from('facturen')
          .select()
          .eq('leerling_id', leerlingId)
          .inFilter('status', ['concept', 'verstuurd', 'verlopen'])
          .order('aangemaakt_op', ascending: false),
      // 2: ongelezen notificaties tellen
      client
          .from('leerling_notificaties')
          .select('id')
          .eq('leerling_id', leerlingId)
          .eq('gelezen', false),
      // 3: recente notificaties
      client
          .from('leerling_notificaties')
          .select()
          .eq('leerling_id', leerlingId)
          .order('aangemaakt_op', ascending: false)
          .limit(3),
    ]);

    final lessenRaw = results[0] as List;
    final volgendeLes = lessenRaw.isNotEmpty ? Les.fromJson(lessenRaw.first) : null;
    final openFacturen =
        (results[1] as List).map((e) => Factuur.fromJson(e)).toList();
    final ongelezen = (results[2] as List).length;
    final recenteNotificaties =
        (results[3] as List).map((e) => Notificatie.fromJson(e)).toList();

    return {
      'volgendeLes': volgendeLes,
      'openFacturen': openFacturen,
      'ongelezenNotificaties': ongelezen,
      'recenteNotificaties': recenteNotificaties,
    };
  }
}

