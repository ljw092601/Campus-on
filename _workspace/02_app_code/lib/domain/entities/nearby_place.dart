import 'package:flutter/material.dart';

/// An off-campus place found by the map's keyword search (e.g. a carrier
/// store), as opposed to a [Facility], which is curated campus data.
///
/// Deliberately plugin-agnostic: the Kakao result model is converted in
/// `campus_map_view.dart` (the one file allowed to know about the plugin), so
/// the map screen and sheets depend only on this shape.
@immutable
class NearbyPlace {
  const NearbyPlace({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.roadAddress,
    this.phone,
    this.placeUrl,
    this.distanceMeters,
  });

  /// Kakao place id — also the marker id (prefixed, see [markerPrefix]).
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String? address;
  final String? roadAddress;
  final String? phone;

  /// Kakao Map place page, opened externally from the peek sheet.
  final String? placeUrl;
  final int? distanceMeters;

  /// Marker ids are a single namespace on the map, so place markers are
  /// prefixed to tell them apart from facility ids on tap.
  static const String markerPrefix = 'place:';

  String get markerId => '$markerPrefix$id';

  static String? idFromMarker(String markerId) =>
      markerId.startsWith(markerPrefix)
          ? markerId.substring(markerPrefix.length)
          : null;

  /// Best available address line for the sheet subtitle.
  String? get displayAddress {
    final road = roadAddress?.trim();
    if (road != null && road.isNotEmpty) return road;
    final jibun = address?.trim();
    return (jibun != null && jibun.isNotEmpty) ? jibun : null;
  }
}
