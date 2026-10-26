import 'package:flutter/material.dart';

/// Vraagt bevestiging voor uitloggen. Geeft `true` terug als de gebruiker
/// bevestigt. Gedeeld door de koppel- en profielschermen, zodat Uitloggen
/// nooit per ongeluk (bijv. in plaats van Terug) wordt uitgevoerd.
Future<bool> bevestigUitloggen(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierLabel: 'Sluiten',
    builder: (ctx) => AlertDialog(
      title: const Text('Uitloggen?'),
      content: const Text('Weet je zeker dat je wilt uitloggen?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuleren'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Uitloggen'),
        ),
      ],
    ),
  );
  return result == true;
}
