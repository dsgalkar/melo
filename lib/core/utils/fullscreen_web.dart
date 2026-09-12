// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class FullscreenPlatformImpl {
  static bool isFullscreen() {
    return html.document.fullscreenElement != null;
  }

  static Future<void> toggleFullscreen() async {
    try {
      if (html.document.fullscreenElement != null) {
        html.document.exitFullscreen();
      } else {
        html.document.documentElement?.requestFullscreen();
      }
    } catch (_) {}
  }
}
