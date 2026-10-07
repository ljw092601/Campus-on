import 'package:flutter/material.dart';

import '../../domain/entities/dining_menu.dart';
import '../../l10n/gen/app_localizations.dart';

/// Localized labels for the dining model enums and the hours line. Kept in
/// one place so the screen, the card and tests format them identically.
extension CampusGroupLabel on CampusGroup {
  String label(AppLocalizations l) => switch (this) {
        CampusGroup.seunghak => l.dining_campusGroup_seunghak,
        CampusGroup.gudeokBumin => l.dining_campusGroup_gudeokBumin,
      };
}

extension MealSlotLabel on MealSlot {
  String label(AppLocalizations l) => switch (this) {
        MealSlot.breakfast => l.dining_slot_breakfast,
        MealSlot.lunch => l.dining_slot_lunch,
        MealSlot.dinner => l.dining_slot_dinner,
        MealSlot.allDay => l.dining_slot_allDay,
      };
}

extension MenuKindLabel on MenuKind {
  String label(AppLocalizations l) => switch (this) {
        MenuKind.set => l.dining_kind_set,
        MenuKind.alacarte => l.dining_kind_alacarte,
        MenuKind.snack => l.dining_kind_snack,
        MenuKind.thousandWon => l.dining_kind_thousandWon,
      };
}

/// "09:00~16:30 · 휴게 09:30~10:00, 14:30~15:00" from structured hours, the
/// free-text note when the school publishes no windows (공과대학 식당), or
/// null when there is nothing to show.
String? diningHoursLine(AppLocalizations l, Locale locale, CafeteriaMenu menu) {
  final summary = menu.hoursSummary;
  if (summary == null) return menu.hoursNote(locale);
  final hours = l.dining_hours_summary(summary.open, summary.close);
  if (summary.breaks.isEmpty) return hours;
  final ranges = summary.breaks
      .map((b) => l.dining_hours_summary(b.open, b.close))
      .join(', ');
  return l.dining_hours_withBreaks(hours, l.dining_hours_break(ranges));
}

/// Status wording for a cafeteria on the shown day. `isToday` picks the
/// "today…" phrasing over the date-neutral one (L-11). Null when the menu is
/// open (sections are shown instead).
String? diningStatusText(AppLocalizations l, CafeteriaMenu menu,
    {required bool isToday}) {
  // Unpublished (admin hasn't entered the menu) is NOT the same as an
  // explicit closure — see design doc §7 D1.
  return switch (menu.status) {
    DiningAvailability.unavailable => l.dining_unavailable,
    DiningAvailability.unpublished =>
      isToday ? l.dining_unpublished : l.dining_unpublished_date,
    DiningAvailability.closed =>
      isToday ? l.dining_closed : l.dining_closed_date,
    DiningAvailability.open => null,
  };
}
