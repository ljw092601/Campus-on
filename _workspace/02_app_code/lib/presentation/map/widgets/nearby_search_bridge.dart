import 'dart:async';
import 'dart:convert';

import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao;

import '../../../domain/entities/nearby_place.dart';

/// Request-scoped alternative to 0.3.x's shared keyword-search completer.
/// Late responses (including after timeout) can only complete their own request.
class NearbySearchBridge {
  NearbySearchBridge(this._controller);

  // Reuse a channel the plugin registers BEFORE loading the page. Android
  // cannot expose a newly added JavaScript interface until the next page load.
  // The wrapper reserves this prefix; ordinary overlay taps are ignored.
  static const _prefix = 'campus-nearby:';
  final kakao.KakaoMapController _controller;
  final _pending = <int, Completer<List<NearbyPlace>>>{};
  int _nextId = 0;
  bool _disposed = false;

  Future<List<NearbyPlace>> search(String keyword,
      {required double lat, required double lng}) async {
    if (_disposed) return const [];
    final id = ++_nextId;
    final completer = Completer<List<NearbyPlace>>();
    _pending[id] = completer;
    final request = jsonEncode({
      'id': id,
      'keyword': keyword,
      'options': {
        'x': lng,
        'y': lat,
        'radius': 5000,
        'size': 15,
        'sort': 'distance'
      },
    });
    // Attach the timeout/error listener before JS can respond or disposal runs.
    final response = completer.future.timeout(const Duration(seconds: 10));
    unawaited(_controller.webViewController.runJavaScript('''
      (function() {
        const request = $request;
        const reply = (status, rows) => onCustomOverlayTap.postMessage(JSON.stringify({
          customOverlayId: '$_prefix' + JSON.stringify({
            id: request.id, status: status, rows: rows
          }), latitude: 0.1, longitude: 0.1
        }));
        try {
          new kakao.maps.services.Places().keywordSearch(request.keyword,
            function(rows, status) { reply(status, rows); }, request.options);
        } catch (_) { reply('ERROR', []); }
      })();
    ''').catchError((Object error) {
      if (!completer.isCompleted) completer.completeError(error);
    }));
    try {
      return await response;
    } finally {
      _pending.remove(id);
    }
  }

  void receiveOverlayMessage(String message) {
    if (!message.startsWith(_prefix) || _disposed) return;
    final data =
        jsonDecode(message.substring(_prefix.length)) as Map<String, dynamic>;
    final completer = _pending[data['id']];
    if (completer == null || completer.isCompleted) return;
    if (data['status'] == 'ZERO_RESULT') {
      completer.complete(const []);
    } else if (data['status'] != 'OK') {
      completer.completeError(StateError('Nearby search failed'));
    } else {
      final places = <NearbyPlace>[];
      for (final row in data['rows'] as List) {
        final place = _parse(row as Map<String, dynamic>);
        if (place != null) places.add(place);
      }
      completer.complete(places);
    }
  }

  NearbyPlace? _parse(Map<String, dynamic> row) {
    final lat = double.tryParse('${row['y']}');
    final lng = double.tryParse('${row['x']}');
    final id = row['id']?.toString();
    if (lat == null ||
        lng == null ||
        !lat.isFinite ||
        !lng.isFinite ||
        id == null ||
        id.isEmpty) {
      return null;
    }
    return NearbyPlace(
      id: id,
      name: (row['place_name'] as String? ?? '').trim(),
      lat: lat,
      lng: lng,
      address: row['address_name'] as String?,
      roadAddress: row['road_address_name'] as String?,
      phone: row['phone'] as String?,
      placeUrl: row['place_url'] as String?,
      distanceMeters: double.tryParse('${row['distance']}')?.round(),
    );
  }

  void dispose() {
    _disposed = true;
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.complete(const []);
    }
    _pending.clear();
  }
}
