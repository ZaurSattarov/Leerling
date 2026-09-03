import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/student_service.dart';
import '../../shared/providers/auth_provider.dart';

/// Gedeelde canonical koppelflow voor zowel de handmatige koppelcode-invoer
/// (KoppelcodeInvoerenScreen) als de QR-scanner (QrScanScreen).
///
/// BELANGRIJK -- ABSOLUTE REGEL (opdracht 2026): QR-code en handmatige
/// koppelcode leiden EXACT tot dezelfde canonical backend-aanroep
/// (`StudentService.koppelLeerlingMetCode`) en dezelfde vervolgnavigatie
/// (`mijnProfielProvider` invalidateen, dan `/profiel-afronden` of `/home`).
/// Er is bewust GEEN tweede koppelmechanisme, geen tweede QR-formaat en geen
/// tweede tabel/RPC.
///
/// De QR-payload is exact de 8-tekens koppelcode zoals de Instructeur-app die
/// genereert in `lib/features/leerlingen/quick_student_flow.dart`
/// (`StudentCouplingShareData.qrPayload => code`). We normaliseren die string
/// hieronder en voeden hem aan dezelfde RPC.
class KoppelFlow {
  KoppelFlow._();

  /// Regex voor een geldige koppelcode: 6-12 tekens, uitsluitend
  /// alfanumeriek. De canonical serverkant accepteert 8 tekens hoofdletters
  /// (zie `koppel_leerling_met_code`), maar we blijven client-side iets
  /// toleranter zodat een toekomstige lengteverandering geen client-update
  /// vereist en de server-validatie leidend blijft.
  static final RegExp _koppelcodePatroon = RegExp(r'^[A-Z0-9]{6,12}$');

  /// Normaliseert een ruwe string (van QR-payload of TextField) naar het
  /// canonical formaat dat de RPC verwacht: getrimd, hoofdletters, zonder
  /// witruimte. Retourneert `null` wanneer de string overduidelijk geen
  /// koppelcode kan zijn -- voorkomt dat we bv. een URL of QR-code van een
  /// heel ander product als koppelcode naar de server sturen.
  static String? normalizeCode(String raw) {
    final schoon = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (schoon.isEmpty) return null;
    if (!_koppelcodePatroon.hasMatch(schoon)) return null;
    return schoon;
  }

  /// Voert de canonical koppel-RPC uit en navigeert daarna via GoRouter.
  ///
  /// Bij succes: invalidate `mijnProfielProvider` (zodat StudentProfileGate
  /// de nieuwe koppeling ziet), controleer of het profiel compleet is en
  /// navigeer naar `/profiel-afronden` of `/home`. Bij fout: gooit
  /// [KoppelException] met een NL-vriendelijke boodschap door.
  ///
  /// Deze methode is 1-op-1 dezelfde flow als de originele
  /// `KoppelcodeScreen._koppel` gebruikte -- opzettelijk geen tweede
  /// success-path.
  static Future<void> koppelEnNavigeer({
    required BuildContext context,
    required WidgetRef ref,
    required String ruweCode,
  }) async {
    final code = normalizeCode(ruweCode);
    if (code == null) {
      throw const KoppelException(
        'Deze code herkennen we niet. Controleer of je de juiste QR-code of '
        'koppelcode van je rijinstructeur gebruikt.',
      );
    }

    try {
      await StudentService.koppelLeerlingMetCode(code);
    } on SocketException catch (_) {
      throw const KoppelException(
        'Geen internetverbinding. Controleer je verbinding en probeer het '
        'opnieuw.',
      );
    } on TimeoutException catch (_) {
      throw const KoppelException(
        'De verbinding met de server duurde te lang. Probeer het opnieuw.',
      );
    } catch (e) {
      // De canonical RPC gooit Exceptions met een Nederlandse `fout` uit
      // `res['fout']`. Toon die direct aan de leerling in plaats van een
      // technische Supabase-error.
      final schoon = e.toString().replaceFirst('Exception: ', '').trim();
      throw KoppelException(
        schoon.isEmpty ? 'Koppelen mislukt. Probeer het opnieuw.' : schoon,
      );
    }

    ref.invalidate(mijnProfielProvider);
    var profielCompleet = false;
    try {
      final profiel = await ref.read(mijnProfielProvider.future);
      profielCompleet = profiel?.isProfielCompleet == true;
    } catch (_) {
      // RPC is al geslaagd; profiel laden wordt op het volgende scherm hervat.
    }

    if (!context.mounted) return;
    if (!profielCompleet) {
      ref.invalidate(mijnProfielProvider);
      context.go('/profiel-afronden');
      return;
    }
    context.go('/home');
  }
}

class KoppelException implements Exception {
  const KoppelException(this.boodschap);
  final String boodschap;

  @override
  String toString() => boodschap;
}
