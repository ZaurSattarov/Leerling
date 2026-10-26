import 'package:flutter/material.dart';

/// Vraagt toestemming voordat de app naar Google of Facebook in de browser gaat.
Future<bool> bevestigDoorsturen(BuildContext context, String provider) async {
  final door = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Doorgaan met $provider'),
      content: Text(
        'Je gaat zo naar $provider in de browser om in te loggen. Daarna kom je terug in de app.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuleren'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Doorgaan'),
        ),
      ],
    ),
  );
  return door == true;
}
