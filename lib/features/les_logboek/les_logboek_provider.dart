import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../shared/providers/auth_provider.dart';
import 'les_logboek_item.dart';
import 'les_logboek_mapper.dart';

const mockLesLogboek = [
  LesLogboekItem(
    id: 'mock-les-1',
    datumLabel: 'Maandag 4 mei',
    tijdLabel: '15:00 - 16:00',
    instructeur: 'Samir',
    onderwerpen: ['Rotondes', 'Spiegelgebruik', 'Parkeren'],
    feedback: 'Je keek beter vooruit, blijf rust houden bij kruispunten.',
    beoordeling: 'Goed op weg',
  ),
  LesLogboekItem(
    id: 'mock-les-2',
    datumLabel: 'Vrijdag 1 mei',
    tijdLabel: '10:30 - 11:30',
    instructeur: 'Samir',
    onderwerpen: ['Kijkgedrag', 'Voorrang', 'Rijstroken'],
    feedback:
        'Je nam meer tijd bij voorrangssituaties. Let nog op je dode hoek.',
    beoordeling: 'Blijven oefenen',
  ),
  LesLogboekItem(
    id: 'mock-les-3',
    datumLabel: 'Woensdag 29 april',
    tijdLabel: '13:00 - 14:00',
    instructeur: 'Samir',
    onderwerpen: ['Schakelen', 'Bochten', 'Snelheid'],
    feedback: 'Schakelen gaat soepeler. Probeer eerder snelheid aan te passen.',
    beoordeling: 'Verbeterd',
  ),
];

final lesLogboekProvider =
    FutureProvider.autoDispose<List<LesLogboekItem>>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return mockLesLogboek;

  try {
    final lessen = await StudentService.getMijnVorigeLessen(
      profiel.id,
      alleenZichtbaarLogboek: true,
    );
    final items = lessen
        .where(
            (les) => les.status.name == 'afgerond' && les.zichtbaarVoorLeerling)
        .map(LesLogboekMapper.fromLes)
        .toList();
    return items.isEmpty ? mockLesLogboek : items;
  } catch (_) {
    return mockLesLogboek;
  }
});

final laatsteLesLogboekItemProvider =
    FutureProvider.autoDispose<LesLogboekItem>((ref) async {
  final items = await ref.watch(lesLogboekProvider.future);
  return items.isNotEmpty ? items.first : mockLesLogboek.first;
});
