import 'dart:typed_data';
import 'file_picker_io.dart'
    if (dart.library.html) 'file_picker_web.dart';

class FilePickerUtil {
  /// Pick a file cross-platform (Web HTML5 File API & Native Desktop/Mobile)
  static Future<({String name, Uint8List bytes})?> pickFile({
    required List<String> allowedExtensions,
  }) {
    return FilePickerPlatformImpl.pickFile(
      allowedExtensions: allowedExtensions,
    );
  }
}
