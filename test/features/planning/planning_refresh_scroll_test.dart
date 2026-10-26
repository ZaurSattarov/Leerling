import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/planning/widgets/framer_animated_timeline.dart';
import 'package:leerling_app/models/les.dart';

void main() {
  testWidgets('een korte planninglijst blijft omlaag te trekken', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {},
            child: AnimatedFramerTimeline(
              lessen: const [
                Les(
                  id: 'les-1',
                  instructeurId: 'instr',
                  leerlingId: 'leerling',
                  datum: '2026-10-26',
                  starttijd: '10:00',
                  eindtijd: '11:00',
                  duurMinuten: 60,
                  status: LesStatus.gepland,
                  aangemaaktOp: '2026-10-01',
                  bijgewerktOp: '2026-10-01',
                ),
              ],
              isKomend: true,
              bottomPadding: 0,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scroll.physics, isA<AlwaysScrollableScrollPhysics>());

    await tester.fling(find.byType(SingleChildScrollView), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });
}
