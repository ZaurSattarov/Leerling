import 'package:flutter/material.dart';

import 'toast.dart';

/// Bestaande Leerling-API, nu met de toast-stijl van de Instructeur-app
/// ([AppToast]: lichte kaart, gekleurd statusicoon, zwevend boven de navbar).
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
}) {
  if (isError) {
    AppToast.fout(context, message);
  } else if (isSuccess) {
    AppToast.succes(context, message);
  } else {
    AppToast.info(context, message);
  }
}
