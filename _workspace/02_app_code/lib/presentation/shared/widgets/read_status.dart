import 'package:flutter/material.dart';
import '../../../domain/repositories/read_result.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'state_views.dart';

String readErrorMessage(Object error, AppLocalizations l, String fallback) =>
    error is OfflineDataUnavailable ? l.data_offline_unavailable : fallback;

/// Per-request status, not a global connectivity guess. Also protects filtered
/// cached-empty results from being presented as authoritative absence.
class ReadStatusContent extends StatelessWidget {
  const ReadStatusContent(
      {super.key,
      required this.data,
      required this.onRetry,
      required this.child,
      this.warning});
  final List<Object?> data;
  final VoidCallback onRetry;
  final Widget child;
  final String? warning;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cached = isCachedRead(data);
    final incomplete = isIncompleteRead(data);
    if (!cached && !incomplete && warning == null) return child;
    final message = [
      if (cached) data.isEmpty ? l.data_cached_empty : l.data_cached,
      if (warning != null) warning! else if (incomplete) l.data_incomplete,
    ].join(' ');
    if (data.isEmpty) {
      return ErrorStateView(
          message: message, retryLabel: l.common_retry, onRetry: onRetry);
    }
    return Column(children: [
      Material(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(children: [
                Expanded(child: Text(message)),
                TextButton(onPressed: onRetry, child: Text(l.common_retry)),
              ]))),
      Expanded(child: child),
    ]);
  }
}
