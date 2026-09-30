import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/favorite_ref.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/favorites_provider.dart';

Future<bool> toggleFavorite(
    BuildContext context, WidgetRef ref, FavoriteType type, String id) async {
  final ok = await ref.read(favoritesProvider.notifier).toggle(type, id);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).favorites_save_failed)));
  }
  return ok;
}
