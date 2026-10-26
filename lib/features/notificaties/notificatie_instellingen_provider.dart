import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/student_service.dart';
import '../../models/leerling_notificatie_voorkeuren.dart';
import '../../shared/providers/auth_provider.dart';

abstract class NotificatieVoorkeurenRepository {
  Future<LeerlingNotificatieVoorkeuren> laad();
  Future<LeerlingNotificatieVoorkeuren> slaOp(
    LeerlingNotificatieVoorkeuren voorkeuren,
  );
  Future<LeerlingNotificatieVoorkeuren> slaEmailOp(
    LeerlingNotificatieVoorkeuren voorkeuren, {
    bool? enabled,
    Map<String, bool>? topics,
  });
}

class StudentNotificatieVoorkeurenRepository
    implements NotificatieVoorkeurenRepository {
  const StudentNotificatieVoorkeurenRepository();

  @override
  Future<LeerlingNotificatieVoorkeuren> laad() {
    return StudentService.getMijnNotificatieVoorkeuren();
  }

  @override
  Future<LeerlingNotificatieVoorkeuren> slaOp(
    LeerlingNotificatieVoorkeuren voorkeuren,
  ) {
    return StudentService.slaMijnNotificatieVoorkeurenOp(voorkeuren);
  }

  @override
  Future<LeerlingNotificatieVoorkeuren> slaEmailOp(
    LeerlingNotificatieVoorkeuren voorkeuren, {
    bool? enabled,
    Map<String, bool>? topics,
  }) {
    return StudentService.slaMijnEmailVoorkeurenOp(
      voorkeuren,
      enabled: enabled,
      topics: topics,
    );
  }
}

final notificatieVoorkeurenRepositoryProvider =
    Provider<NotificatieVoorkeurenRepository>(
  (ref) {
    // Herlaad voorkeuren ook bij accountwissels buiten het profielscherm.
    ref.watch(authStateProvider.select(
      (state) => state.valueOrNull?.session?.user.id,
    ));
    return StudentNotificatieVoorkeurenRepository();
  },
);

final notificatieInstellingenProvider = AutoDisposeAsyncNotifierProvider<
    NotificatieInstellingenNotifier,
    LeerlingNotificatieVoorkeuren>(NotificatieInstellingenNotifier.new);

class NotificatieInstellingenNotifier
    extends AutoDisposeAsyncNotifier<LeerlingNotificatieVoorkeuren> {
  int _generation = 0;
  bool _saving = false;

  @override
  Future<LeerlingNotificatieVoorkeuren> build() {
    ref.onDispose(() {
      _generation++;
      _saving = false;
    });
    return ref.watch(notificatieVoorkeurenRepositoryProvider).laad();
  }

  Future<void> opslaan(LeerlingNotificatieVoorkeuren voorkeuren) async {
    await _opslaan(voorkeuren, email: false);
  }

  Future<void> opslaanEmail(LeerlingNotificatieVoorkeuren voorkeuren) async {
    await _opslaan(voorkeuren, email: true);
  }

  Future<void> _opslaan(
    LeerlingNotificatieVoorkeuren voorkeuren, {
    required bool email,
  }) async {
    if (_saving) throw StateError('Opslaan is nog bezig');
    final vorige = state.valueOrNull;
    if (vorige == null || vorige.userId != voorkeuren.userId) {
      throw StateError('Voorkeuren horen niet bij het huidige account');
    }
    final generation = _generation;
    final repository = ref.read(notificatieVoorkeurenRepositoryProvider);
    final changedTopics = <String, bool>{
      for (final entry in voorkeuren.emailTopics.entries)
        if (vorige.emailTopicEnabled(entry.key) != entry.value)
          entry.key: entry.value,
    };
    final changedEnabled =
        voorkeuren.emailNotificaties != vorige.emailNotificaties
            ? voorkeuren.emailNotificaties
            : null;
    if (email && changedEnabled == null && changedTopics.isEmpty) return;
    _saving = true;
    state = const AsyncLoading<LeerlingNotificatieVoorkeuren>()
        .copyWithPrevious(AsyncData(voorkeuren));
    try {
      final opgeslagen = await (email
          ? repository.slaEmailOp(
              voorkeuren,
              enabled: changedEnabled,
              topics: changedTopics.isEmpty ? null : changedTopics,
            )
          : repository.slaOp(voorkeuren));
      if (generation != _generation) return;
      if (opgeslagen.userId != vorige.userId) {
        throw StateError('Onjuist account in het opslagantwoord');
      }
      state = AsyncData(opgeslagen);
    } catch (_) {
      if (generation == _generation) {
        state = AsyncData(vorige);
      }
      rethrow;
    } finally {
      if (generation == _generation) _saving = false;
    }
  }
}
