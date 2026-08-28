/// Canonical mapping tussen zichtbare Leerling-app toggles en backend types.
/// Spiegelt `LEERLING_NOTIFICATION_CONTRACTS` in push_logic.ts — bij wijziging
/// daar ook hier en in `test/leerling_notification_preference_registry_test.dart`.
library;

class LeerlingPreferenceToggle {
  final String uiLabel;
  final String dbKey;
  final List<String> canonicalTypes;
  final String subtitle;

  const LeerlingPreferenceToggle({
    required this.uiLabel,
    required this.dbKey,
    required this.canonicalTypes,
    required this.subtitle,
  });
}

class LeerlingSystemLockedNotification {
  final String uiLabel;
  final List<String> canonicalTypes;
  final String subtitle;

  const LeerlingSystemLockedNotification({
    required this.uiLabel,
    required this.canonicalTypes,
    required this.subtitle,
  });
}

/// Optionele toggles — elk type heeft een actieve server/client producer.
const leerlingOptionalPreferenceToggles = <LeerlingPreferenceToggle>[
  LeerlingPreferenceToggle(
    uiLabel: 'Nieuwe les',
    dbKey: 'nieuwe_les',
    canonicalTypes: ['lesson_planned'],
    subtitle: 'Wanneer er een les voor je klaarstaat.',
  ),
  LeerlingPreferenceToggle(
    uiLabel: 'Les verplaatst',
    dbKey: 'les_verplaatst',
    canonicalTypes: ['lesson_changed'],
    subtitle: 'Bij wijzigingen in je lesplanning.',
  ),
  LeerlingPreferenceToggle(
    uiLabel: 'Lesherinneringen',
    dbKey: 'les_herinnering',
    canonicalTypes: ['lesson_reminder_day_before', 'lesson_reminder_1h'],
    subtitle: 'Herinneringen 1 dag en 1 uur voor je rijles.',
  ),
  LeerlingPreferenceToggle(
    uiLabel: 'Nieuwe factuur',
    dbKey: 'nieuwe_factuur',
    canonicalTypes: ['invoice_created'],
    subtitle: 'Wanneer een factuur beschikbaar is.',
  ),
  LeerlingPreferenceToggle(
    uiLabel: 'Betaling verwerkt',
    dbKey: 'betaling_ontvangen',
    canonicalTypes: ['invoice_paid'],
    subtitle:
        'Bevestiging wanneer je betaling is ontvangen en verwerkt.',
  ),
  LeerlingPreferenceToggle(
    uiLabel: 'Factuurherinneringen',
    dbKey: 'factuur_herinnering',
    canonicalTypes: [
      'invoice_reminder',
      'invoice_reminder_3d',
      'invoice_reminder_due_today',
      'invoice_overdue_1d',
      'invoice_overdue_7d',
      'factuur',
    ],
    subtitle: 'Herinneringen rond openstaande facturen.',
  ),
  LeerlingPreferenceToggle(
    uiLabel: 'Examen ingepland',
    dbKey: 'examen_gepland',
    canonicalTypes: ['exam_scheduled'],
    subtitle: 'Als je instructeur een examen voor je plant.',
  ),
  LeerlingPreferenceToggle(
    uiLabel: 'Examenherinneringen',
    dbKey: 'examen_herinnering',
    canonicalTypes: ['exam_reminder_7d', 'exam_reminder_1d'],
    subtitle: 'Herinneringen 7 dagen en 1 dag voor je examen.',
  ),
  LeerlingPreferenceToggle(
    uiLabel: 'Examenresultaat',
    dbKey: 'examen_resultaat',
    canonicalTypes: ['exam_result'],
    subtitle: 'Als je instructeur je examenresultaat toevoegt.',
  ),
  LeerlingPreferenceToggle(
    uiLabel: 'Examenadvies',
    dbKey: 'examenadvies',
    canonicalTypes: ['examenadvies'],
    subtitle: 'Updates over je examenadvies.',
  ),
  LeerlingPreferenceToggle(
    uiLabel: 'Nieuwe evaluatie',
    dbKey: 'nieuwe_evaluatie',
    canonicalTypes: ['lesson_feedback'],
    subtitle: 'Wanneer je instructeur feedback deelt.',
  ),
  LeerlingPreferenceToggle(
    uiLabel: 'Lespakket bijna op',
    dbKey: 'lespakket_bijna_op',
    canonicalTypes: ['package_almost_empty'],
    subtitle: 'Als je lessen bijna op zijn.',
  ),
];

/// Niet uitschakelbaar — elk item heeft minstens één actieve canonical producer.
const leerlingSystemLockedNotifications = <LeerlingSystemLockedNotification>[
  LeerlingSystemLockedNotification(
    uiLabel: 'Les geannuleerd',
    canonicalTypes: ['lesson_cancelled'],
    subtitle: 'Je hoort altijd wanneer een geplande les niet doorgaat.',
  ),
  LeerlingSystemLockedNotification(
    uiLabel: 'Les start binnenkort',
    canonicalTypes: ['les_reminder'],
    subtitle:
        'Korte verplichte melding vlak voor aanvang van je rijles.',
  ),
  LeerlingSystemLockedNotification(
    uiLabel: 'Bericht van je instructeur',
    canonicalTypes: ['admin_message'],
    subtitle: 'Directe berichten via Klantio — niet uit te zetten.',
  ),
];

/// push_logic.ts `LEERLING_NOTIFICATION_CONTRACTS` — optionele types moeten een toggle hebben.
const leerlingOptionalCanonicalTypes = <String, String>{
  'lesson_planned': 'nieuwe_les',
  'lesson_changed': 'les_verplaatst',
  'lesson_reminder_day_before': 'les_herinnering',
  'lesson_reminder_1h': 'les_herinnering',
  'lesson_feedback': 'nieuwe_evaluatie',
  'invoice_created': 'nieuwe_factuur',
  'invoice_paid': 'betaling_ontvangen',
  'invoice_reminder': 'factuur_herinnering',
  'invoice_reminder_3d': 'factuur_herinnering',
  'invoice_reminder_due_today': 'factuur_herinnering',
  'invoice_overdue_1d': 'factuur_herinnering',
  'invoice_overdue_7d': 'factuur_herinnering',
  'factuur': 'factuur_herinnering',
  'package_almost_empty': 'lespakket_bijna_op',
  'exam_scheduled': 'examen_gepland',
  'exam_result': 'examen_resultaat',
  'examenadvies': 'examenadvies',
  'exam_reminder_7d': 'examen_herinnering',
  'exam_reminder_1d': 'examen_herinnering',
};

const leerlingSystemNonOptionalTypes = <String>{
  'lesson_cancelled',
  'les_reminder',
  'admin_message',
};
