import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long a network-backed `.family` provider keeps its last value once it
/// has been built (M-25). Within this window a screen that is left and quickly
/// re-entered reuses the cached value instead of hitting the repository
/// again; past it the provider is disposed as soon as nobody watches it, so
/// the next visit fetches fresh data. One constant for every such provider.
const providerCacheTtl = Duration(minutes: 5);

/// TTL used by [ProviderCache.cacheFor]. A `Provider` (not a bare constant)
/// so tests can shorten it with `overrideWithValue`. `Duration.zero` turns
/// the cache off (plain autoDispose, no timer) — use that in `testWidgets`
/// that own a standalone `ProviderContainer`, since flutter_test flags any
/// timer still pending when the widget tree is torn down, before tearDowns.
final providerCacheTtlProvider = Provider<Duration>((_) => providerCacheTtl);

extension ProviderCache on Ref<Object?> {
  /// Keeps this autoDispose provider alive for [providerCacheTtlProvider],
  /// measured from the build that called this. (Only meaningful on an
  /// `autoDispose` provider; a non-autoDispose one never disposes anyway.)
  ///
  /// - No listeners at all (e.g. `ref.read(p.future)`): disposed when the TTL
  ///   elapses.
  /// - Still watched when the TTL elapses: lives on until the last watcher is
  ///   gone, then disposed immediately, so a later visit refetches.
  /// - `ref.invalidate` / `ref.refresh`: the old timer is cancelled via
  ///   [onDispose] and the rebuilt provider starts a fresh TTL.
  /// - TTL <= zero: no-op (plain autoDispose).
  ///
  /// Call once, synchronously, at the top of the provider body (before any
  /// `await`), so the keep-alive link exists before the first dispose check.
  void cacheFor() {
    final ttl = watch(providerCacheTtlProvider);
    if (ttl <= Duration.zero) return;
    final link = keepAlive();
    final timer = Timer(ttl, link.close);
    onDispose(timer.cancel);
  }
}
