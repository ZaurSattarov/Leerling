import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/student_service.dart';
import '../../models/leerling_notificatie_voorkeuren.dart';

abstract class NotificatieVoorkeurenRepository {
  Future<LeerlingNotificatieVoorkeuren> laad();
  Future<LeerlingNotificatieVoorkeuren> slaOp(
    LeerlingNotificatieVoorkeuren voorkeuren,
  );
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
}

final notificatieVoorkeurenRepositoryProvider =
    Provider<NotificatieVoorkeurenRepository>(
  (_) => const StudentNotificatieVoorkeurenRepository(),
);

final notificatieInstellingenProvider = AutoDisposeAsyncNotifierProvider<
    NotificatieInstellingenNotifier,
    LeerlingNotificatieVoorkeuren>(NotificatieInstellingenNotifier.new);

class NotificatieInstellingenNotifier
    extends AutoDisposeAsyncNotifier<LeerlingNotificatieVoorkeuren> {
  @override
  Future<LeerlingNotificatieVoorkeuren> build() {
    return ref.watch(notificatieVoorkeurenRepositoryProvider).laad();
  }

  Future<void> opslaan(LeerlingNotificatieVoorkeuren voorkeuren) async {
    final vorige = state.valueOrNull;
    state = AsyncData(voorkeuren);
    try {
      final opgeslagen =
          await ref.read(notificatieVoorkeurenRepositoryProvider).slaOp(
                voorkeuren,
              );
      state = AsyncData(opgeslagen);
    } catch (e, st) {
      if (vorige != null) {
        state = AsyncData(vorige);
      } else {
        state = AsyncError(e, st);
      }
      rethrow;
    }
  }
}
