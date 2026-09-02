import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/lifecycle/account_scoped_invalidation.dart';

void main() {
  testWidgets(
    'account-scoped invalidation draait pas in de volgende frame '
    '(InheritedElement.debugDeactivated / _dependents.isEmpty)',
    (tester) async {
      final volgorde = <String>[];
      await tester.pumpWidget(const SizedBox());
      scheduleAccountScopedProviderInvalidation(
        () => volgorde.add('invalidate'),
      );
      volgorde.add('same-turn');
      expect(volgorde, ['same-turn']);
      await tester.pump();
      expect(volgorde, ['same-turn', 'invalidate']);
    },
  );
}
