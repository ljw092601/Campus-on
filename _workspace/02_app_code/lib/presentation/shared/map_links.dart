/// Builders for the map deep links (UX doc §3, `AppRouter._mapScreen`).
///
/// `MapScreen` stays alive inside the tab shell, so a second link to the same
/// building arrives as new widget params rather than a fresh screen. It only
/// re-focuses when `MapScreen._focusKeyOf` changes, and that key includes the
/// `t` query parameter — so every link built here carries a fresh `t` token.
/// Without it, "view on map" from a guide, a cafeteria menu or a facility
/// detail did nothing when the map was already showing that building (M-10).
library;

int _lastToken = 0;

/// A token that is unique per call within this process, even for calls that
/// land on the same millisecond (strictly increasing).
String newMapFocusToken() {
  final now = DateTime.now().millisecondsSinceEpoch;
  _lastToken = now > _lastToken ? now : _lastToken + 1;
  return '$_lastToken';
}

/// `/map?focus=<facilityId>[&floor=..][&room=..][&plan=..]&t=<token>`.
///
/// [facilityId] may be a comma-separated id list (first id = representative
/// marker). [floor] is the `MapScreen.focusFloorCode` ("03", "B1"), [room]
/// the full room code ("0306-1"), [plan] the floor-plan drawing set ("B04A").
/// [path] swaps the route (classroom search uses `/classroom-search/result`).
String mapFocusLink(
  String facilityId, {
  String? floor,
  String? room,
  String? plan,
  String path = '/map',
}) {
  final query = <String, String>{
    'focus': facilityId,
    if (floor != null && floor.isNotEmpty) 'floor': floor,
    if (room != null && room.isNotEmpty) 'room': room,
    if (plan != null && plan.isNotEmpty) 'plan': plan,
    't': newMapFocusToken(),
  };
  // `,` stays literal so multi-id links read like the seeded guide links.
  return Uri(path: path, queryParameters: query)
      .toString()
      .replaceAll('%2C', ',');
}

/// Returns [url] with a fresh `t` token appended when it is a `/map?focus=`
/// link that has none — for links that come from data (seeded guide bodies)
/// rather than from [mapFocusLink]. Any other url is returned untouched.
String withMapFocusToken(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.path != '/map' ||
      !uri.queryParameters.containsKey('focus') ||
      uri.queryParameters.containsKey('t')) {
    return url;
  }
  final sep = uri.hasQuery ? '&' : '?';
  return '$url${sep}t=${newMapFocusToken()}';
}
