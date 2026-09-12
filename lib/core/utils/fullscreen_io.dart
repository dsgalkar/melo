import 'package:flutter/services.dart';

class FullscreenPlatformImpl {
  static bool _isFullscreen = false;

  static bool isFullscreen() => _isFullscreen;

  static Future<void> toggleFullscreen() async {
    _isFullscreen = !_isFullscreen;
    if (_isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}
