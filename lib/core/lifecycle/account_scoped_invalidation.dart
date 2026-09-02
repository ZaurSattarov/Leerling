import 'package:flutter/widgets.dart';

/// Invalidatie van account-scoped state mag niet in dezelfde turn als het
/// unmounten van de shell (logout/delete → `go('/login')`).
/// [InheritedElement.debugDeactivated] eist `_dependents.isEmpty`; synchrone
/// provider-writes + route-teardown in dezelfde frame laten dependents achter.
void scheduleAccountScopedProviderInvalidation(VoidCallback invalidate) {
  final binding = WidgetsBinding.instance;
  binding.addPostFrameCallback((_) => invalidate());
  binding.ensureVisualUpdate();
}
