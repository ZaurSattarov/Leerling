import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/app.dart';

void main() {
  testWidgets('app smoke test', (WidgetTester tester) async {
    expect(const LeerlingApp(), isNotNull);
  });
}
