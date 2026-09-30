import 'dart:ui';

import 'package:flutter/material.dart';

import 'bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Flutter already reports framework errors. Also report uncaught platform /
  // asynchronous errors; startup failures are handled by AppBootstrap itself.
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack));
    return true;
  };
  final initializer = AppInitializer();
  runApp(AppBootstrap(initialize: initializer.initialize));
}
