import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../../models/leerling_profiel.dart';
import '../../models/leerling_beschikbaarheid.dart';
import '../../models/les.dart';
import '../../models/factuur.dart';
import '../../models/notificatie.dart';
import '../../models/examen.dart';
import '../../models/instructeur.dart';

class StudentService {
  static String get supabaseUrl => AppConfig.supabaseUrl;
  static String get supabaseAnonKey => AppConfig.supabaseAnonKey;

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static String get userId => currentUser!.id;
  static const String _studentLessenView = 'student_lessen_view';
  static const Duration _profileCheckTimeout = Duration(seconds: 8);

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
    Map<String, dynamic>? metadata,
  }) async {
    final trimmedEmail = email.trim();
    debugPrint('[student.registreren] email=$trimmedEmail');

    try {
      final response = await client.auth.signUp(
        email: trimmedEmail,
        password: wachtwoord,
        data: metadata,
        emailRedirectTo: AppConfig.authConfirmRedirectUrl,
      );
      debugPrint(
          '[student.registreren] user=${response.user?.id ?? 'null'} session=${response.session != null}');
      return response;
    } on AuthException catch (e) {
      debugPrint(
          '[student.registreren] AuthException code=${e.statusCode ?? 'null'} message=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[student.registreren] onverwachte fout=$e');
      rethrow;
    }
  }

  static Future<void> uitloggen() => client.auth.signOut();

  static Future<void> stuurWachtwoordReset(String email) {
    return client.auth.resetPasswordForEmail(
      email,
      redirectTo: AppConfig.authRedirectUrl,
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // KOPPELING
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<void> koppelLeerlingMetCode(String koppelCode) async {
    final raw = await client.rpc(
      'koppel_leerling_met_code',
      params: {'p_koppel_code': koppelCode.trim().toUpperCase()},
    );
    final res = Map<String, dynamic>.from(raw as Map);
    if (res['succes'] != true) {
      throw Exception(res['fout'] ?? 'Koppelen mislukt');
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // LEERLING PROFIEL (eigen profiel via user_id)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<LeerlingProfiel?> getMijnProfiel() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final res = await client
          .from('leerlingen')
          .select()
          .eq('user_id', user.id)
          .maybeSingle()
          .timeout(_profileCheckTimeout);
      return res != null ? LeerlingProfiel.fromJson(res) : null;
    } on TimeoutException {
      debugPrint('[student.profiel] profielcheck timeout, toon koppelcode');
      return null;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // INSTRUCTEUR (read-only, via leerling.instructeur_id)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<String> uploadMijnProfielfoto({
    required String leerlingId,
    required Uint8List bytes,
    required String bestandExtensie,
  }) async {
    final extensie = bestandExtensie.toLowerCase().replaceAll('.', '');
    final veiligeExtensie = extensie == 'png' ? 'png' : 'jpg';
    final contentType = veiligeExtensie == 'png' ? 'image/png' : 'image/jpeg';
    final pad =
        'leerlingen/$leerlingId/profiel_${DateTime.now().millisecondsSinceEpoch}.$veiligeExtensie';

    try {
      await client.storage.from('avatars').uploadBinary(
            pad,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );
      final publicUrl = client.storage.from('avatars').getPublicUrl(pad);

      // TODO backend: voeg avatar_url toe aan public.leerlingen en maak de
      // storage bucket avatars beschikbaar voor leerling uploads.
      await client
          .from('leerlingen')
          .update({'avatar_url': publicUrl})
          .eq('id', leerlingId)
          .eq('user_id', userId);
      return publicUrl;
    } catch (e) {
      debugPrint('[student.avatar] upload/update niet beschikbaar: $e');
      throw Exception(
          'Profielfoto upload is nog niet beschikbaar. Backend nodig: avatars bucket + avatar_url op leerlingen.');
    }
  }

  static Future<Instructeur?> getMijnInstructeur(String instructeurId) async {
    final res = await client
        .from('instructeur_profielen')
        .select(
            'id, rijschool_naam, naam, telefoon, email, adres, postcode, stad, logo_url, whatsapp_nummer')
        .eq('id', instructeurId)
        .maybeSingle();
    return res != null ? Instructeur.fromJson(res) : null;
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // LESSEN
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<List<Les>> getMijnLessen(String leerlingId) async {
    final res = await client
        .from(_studentLessenView)
        .select()
        .eq('leerling_id', leerlingId)
        .order('datum', ascending: false)
        .order('starttijd', ascending: false);
    return (res as List).map((e) => Les.fromJson(e)).toList();
  }

  static Future<List<Les>> getMijnLessenVoorPakket(String leerlingId) async {
    final res = await client
        .from(_studentLessenView)
        .select()
        .eq('leerling_id', leerlingId)
        .order('datum', ascending: false)
        .order('starttijd', ascending: false)
        .limit(250);
    return (res as List).map((e) => Les.fromJson(e)).toList();
  }

  static Future<List<Les>> getMijnKomendeLessen(String leerlingId) async {
    final vandaag = DateTime.now();
    final vandaagStr =
        '${vandaag.year}-${vandaag.month.toString().padLeft(2, '0')}-${vandaag.day.toString().padLeft(2, '0')}';
    final res = await client
        .from(_studentLessenView)
        .select()
        .eq('leerling_id', leerlingId)
        .eq('status', 'gepland')
        .gte('datum', vandaagStr)
        .order('datum')
        .order('starttijd')
        .limit(50);
    return (res as List).map((e) => Les.fromJson(e)).toList();
  }

  static Future<List<Les>> getMijnVorigeLessen(
    String leerlingId, {
    bool alleenZichtbaarLogboek = false,
  }) async {
    final vandaag = DateTime.now();
    final vandaagStr =
        '${vandaag.year}-${vandaag.month.toString().padLeft(2, '0')}-${vandaag.day.toString().padLeft(2, '0')}';
    final query =
        client.from(_studentLessenView).select().eq('leerling_id', leerlingId);

    final filteredQuery = alleenZichtbaarLogboek
        ? query.eq('status', 'afgerond')
        : query.neq('status', 'gepland').or(
            'datum.lt.$vandaagStr,status.eq.afgerond,status.eq.geannuleerd,status.eq.geen_toon');

    final res = await filteredQuery
        .order('datum', ascending: false)
        .order('starttijd', ascending: false)
        .limit(100);
    return (res as List).map((e) => Les.fromJson(e)).toList();
  }

  static Future<Les?> getLes(String lesId) async {
    final res = await client
        .from(_studentLessenView)
        .select()
        .eq('id', lesId)
        .maybeSingle();
    return res != null ? Les.fromJson(res) : null;
  }

  static Future<void> updateMijnLesNotitie({
    required String lesId,
    required String leerlingId,
    String? notitie,
  }) async {
    final schoneNotitie = notitie?.trim();
    await client.rpc(
      'update_student_lesson_note',
      params: {
        'p_les_id': lesId,
        'p_notitie':
            schoneNotitie == null || schoneNotitie.isEmpty ? '' : schoneNotitie,
      },
    );
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
    final res =
        await client.from('facturen').select().eq('id', id).maybeSingle();
    return res != null ? Factuur.fromJson(res) : null;
  }

  static Future<Map<String, dynamic>> requestMollieFactuurPayment(
      String factuurId) async {
    try {
      final result = await client.functions.invoke(
        'create-factuur-payment',
        body: {'factuur_id': factuurId},
      );
      final data = result.data as Map<String, dynamic>? ?? {};
      if (data['code'] == 'MOLLIE_NOT_CONNECTED') {
        return {'error': 'MOLLIE_NOT_CONNECTED'};
      }
      final url = data['checkout_url'] as String?;
      if (url != null) return {'checkout_url': url};
      return {'error': data['error'] ?? 'Onbekende fout'};
    } catch (e) {
      debugPrint('[requestMollieFactuurPayment] fout: $e');
      return {'error': e.toString()};
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // NOTIFICATIES
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<List<Notificatie>> getMijnNotificaties(
      String leerlingId) async {
    List<dynamic> res;
    try {
      debugPrint(
          '[student.notificaties] ophalen leerling=$leerlingId sort=created_at');
      res = await client
          .from('leerling_notificaties')
          .select()
          .eq('leerling_id', leerlingId)
          .order('created_at', ascending: false)
          .limit(50);
    } catch (_) {
      debugPrint(
          '[student.notificaties] created_at niet beschikbaar, fallback sort=aangemaakt_op leerling=$leerlingId');
      res = await client
          .from('leerling_notificaties')
          .select()
          .eq('leerling_id', leerlingId)
          .order('aangemaakt_op', ascending: false)
          .limit(50);
    }
    final now = DateTime.now();
    debugPrint('[student.notificaties] raw count=${res.length}');
    final meldingen = res.map((e) => Notificatie.fromJson(e)).where(
      (melding) {
        final scheduledFor = melding.scheduledFor;
        if (scheduledFor == null || scheduledFor.isEmpty) return true;
        final scheduledAt = DateTime.tryParse(scheduledFor);
        return scheduledAt == null || !scheduledAt.toLocal().isAfter(now);
      },
    ).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final perType = <String, int>{};
    for (final melding in meldingen) {
      perType[melding.type] = (perType[melding.type] ?? 0) + 1;
    }
    debugPrint(
        '[student.notificaties] zichtbaar count=${meldingen.length} types=$perType');
    return meldingen;
  }

  static Future<int> getOngelezenNotificatiesAantal(String leerlingId) async {
    final res = await client
        .from('leerling_notificaties')
        .select('id')
        .eq('leerling_id', leerlingId)
        .eq('gelezen', false);
    return (res as List).length;
  }

  static Future<void> markeerGelezen(
    String notificatieId,
    String leerlingId,
  ) async {
    await client
        .from('leerling_notificaties')
        .update({'gelezen': true})
        .eq('id', notificatieId)
        .eq('leerling_id', leerlingId);
  }

  static Future<void> markeerAllesGelezen(String leerlingId) async {
    await client
        .from('leerling_notificaties')
        .update({'gelezen': true})
        .eq('leerling_id', leerlingId)
        .eq('gelezen', false);
  }

  // ─────────────────────────────────────────────────────────────
  // BESCHIKBAARHEID
  // ─────────────────────────────────────────────────────────────

  static Future<List<LeerlingBeschikbaarheid>> getMijnBeschikbaarheid(
      String leerlingId) async {
    final res = await client
        .from('leerling_beschikbaarheid')
        .select()
        .eq('leerling_id', leerlingId)
        .order('dag_van_week')
        .order('start_tijd');
    return (res as List)
        .map((e) => LeerlingBeschikbaarheid.fromJson(e))
        .toList();
  }

  static Future<void> voegBeschikbaarheidToe({
    required String leerlingId,
    required String instructeurId,
    required int dagVanWeek,
    required String startTijd,
    required String eindTijd,
    int voorkeurScore = 3,
  }) async {
    await client.from('leerling_beschikbaarheid').insert({
      'leerling_id': leerlingId,
      'instructeur_id': instructeurId,
      'dag_van_week': dagVanWeek,
      'start_tijd': startTijd,
      'eind_tijd': eindTijd,
      'voorkeur_score': voorkeurScore,
    });
  }

  static Future<void> updateBeschikbaarheid({
    required String id,
    required int dagVanWeek,
    required String startTijd,
    required String eindTijd,
    int voorkeurScore = 3,
  }) async {
    await client.from('leerling_beschikbaarheid').update({
      'dag_van_week': dagVanWeek,
      'start_tijd': startTijd,
      'eind_tijd': eindTijd,
      'voorkeur_score': voorkeurScore,
    }).eq('id', id);
  }

  static Future<void> verwijderBeschikbaarheid(String id) async {
    await client.from('leerling_beschikbaarheid').delete().eq('id', id);
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
          .inFilter('status', ['concept', 'verstuurd', 'verlopen']).order(
              'aangemaakt_op',
              ascending: false),
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
    final volgendeLes =
        lessenRaw.isNotEmpty ? Les.fromJson(lessenRaw.first) : null;
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

  // ─────────────────────────────────────────────────────────────
  // EXAMENADVIES & EVALUATIES
  // ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getExamReadiness(
      String leerlingId) async {
    try {
      final row = await client
          .from('student_exam_readiness')
          .select()
          .eq('student_id', leerlingId)
          .maybeSingle();
      return row != null ? Map<String, dynamic>.from(row) : null;
    } catch (e) {
      debugPrint('[student.examReadiness] ophalen mislukt: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getLaatsteEvaluatie(
      String leerlingId) async {
    try {
      final row = await client
          .from('lesson_evaluations')
          .select()
          .eq('student_id', leerlingId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row != null ? Map<String, dynamic>.from(row) : null;
    } catch (e) {
      debugPrint('[student.evaluatie] ophalen mislukt: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // EXAMENS (read-only voor leerling)
  // ─────────────────────────────────────────────────────────────

  static Future<List<Examen>> getMijnExamens(String leerlingId) async {
    try {
      final res = await client
          .from('examens')
          .select()
          .eq('leerling_id', leerlingId)
          .order('datum', ascending: false);
      return (res as List).map((e) => Examen.fromJson(e)).toList();
    } catch (e) {
      debugPrint('[student.examens] ophalen mislukt: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // REALTIME SUBSCRIPTIONS
  // ─────────────────────────────────────────────────────────────

  static RealtimeChannel subscribeLessen(
    String leerlingId,
    void Function() onChange,
  ) {
    return client
        .channel('leerling_lessen_$leerlingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'lessen',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'leerling_id',
            value: leerlingId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  static RealtimeChannel subscribeNotificaties(
    String leerlingId,
    void Function() onChange,
  ) {
    return client
        .channel('leerling_notificaties_$leerlingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leerling_notificaties',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'leerling_id',
            value: leerlingId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  static RealtimeChannel subscribeFacturen(
    String leerlingId,
    void Function() onChange,
  ) {
    return client
        .channel('leerling_facturen_$leerlingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'facturen',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'leerling_id',
            value: leerlingId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  static Future<void> removeChannel(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }
}
