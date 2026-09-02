import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:screen_protector/screen_protector.dart';

/// Blocks screenshots / screen recording while this [State] is mounted (Android
/// FLAG_SECURE, iOS capture shield). No-op on web and desktop — the
/// `screen_protector` plugin only registers a method channel on mobile.
mixin GameScreenCaptureGuard<T extends StatefulWidget> on State<T> {
  static bool get _supportsNativeScreenProtector {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    _applyScreenshotBlock(true);
  }

  @override
  void dispose() {
    _applyScreenshotBlock(false);
    super.dispose();
  }

  void _applyScreenshotBlock(bool on) {
    if (!_supportsNativeScreenProtector) return;
    final Future<void> f = on
        ? ScreenProtector.preventScreenshotOn()
        : ScreenProtector.preventScreenshotOff();
    // MissingPluginException is async; synchronous try/catch does not catch it.
    f.catchError((Object _, StackTrace __) {});
  }
}
