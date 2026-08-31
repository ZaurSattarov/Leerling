import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architectuur-bewaking (Feature 2, Fase 2C): de Leerling-app is
/// UITSLUITEND consumer van Live Aankomst. Deze test leest de broncode van
/// arrival_repository.dart (de enige plek die deze tabellen mag aanraken)
/// en faalt zodra daar ooit een write of een arrival-RPC-aanroep insluipt.
void main() {
  test(
    'arrival_repository.dart schrijft nooit naar arrival_sessions/'
    'current_arrival_location en roept nooit een arrival-RPC aan',
    () {
      final bestand = File('lib/core/services/arrival_repository.dart');
      expect(bestand.existsSync(), true,
          reason: 'verwacht bestand niet gevonden -- pad gewijzigd?');
      final inhoud = bestand.readAsStringSync();

      final verbodenPatronen = [
        RegExp(r"from\('arrival_sessions'\)\s*\.\s*(insert|update|upsert|delete)"),
        RegExp(
            r"from\('current_arrival_location'\)\s*\.\s*(insert|update|upsert|delete)"),
        RegExp(r"rpc\(\s*'fn_arrival_start'"),
        RegExp(r"rpc\(\s*'fn_arrival_publish_location'"),
        RegExp(r"rpc\(\s*'fn_arrival_stop'"),
      ];
      for (final patroon in verbodenPatronen) {
        expect(
          inhoud.contains(patroon),
          false,
          reason:
              'Verboden write/RPC-aanroep gevonden in de Leerling-app -- '
              'de Leerling-app is uitsluitend consumer. Patroon: $patroon',
        );
      }

      // Positieve controle: de verwachte reads moeten wél aanwezig zijn --
      // anders is de negatieve check hierboven zinloos ("niets doet niets
      // fout").
      expect(inhoud.contains("from('arrival_sessions')"), true);
      expect(inhoud.contains("from('current_arrival_location')"), true);
    },
  );
}
