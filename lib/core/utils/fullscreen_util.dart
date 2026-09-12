import 'fullscreen_io.dart'
    if (dart.library.html) 'fullscreen_web.dart';

class FullscreenUtil {
  static bool isFullscreen() {
    return FullscreenPlatformImpl.isFullscreen();
  }

  static Future<void> toggleFullscreen() {
    return FullscreenPlatformImpl.toggleFullscreen();
  }
}
