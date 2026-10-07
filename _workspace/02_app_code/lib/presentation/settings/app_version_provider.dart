import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// App version/build as reported by the platform bundle (audit L-31: the
/// Settings screen used to show a version string hardcoded in the ARB files,
/// which drifted from `pubspec.yaml`). Resolved once per app run; tests
/// override it instead of mocking the platform channel.
final appVersionProvider =
    FutureProvider<PackageInfo>((_) => PackageInfo.fromPlatform());
