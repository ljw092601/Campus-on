import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/gen/app_localizations.dart';

/// Opens [uri] outside the app (browser, dialer, mail client) and tells the
/// user when nothing could handle it — audit L-8: every launch site used to
/// fail silently. Returns whether the launch succeeded.
Future<bool> openExternal(
  BuildContext context,
  Uri uri, {
  LaunchMode mode = LaunchMode.platformDefault,
}) async {
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: mode);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).common_openFailed)));
  }
  return ok;
}
