import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class FilePickerPlatformImpl {
  static Future<({String name, Uint8List bytes})?> pickFile({
    required List<String> allowedExtensions,
  }) async {
    try {
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (files.isEmpty) return null;

      final file = files.first;
      final path = file.path;
      if (path == null) return null;

      final bytes = await File(path).readAsBytes();
      return (name: file.name, bytes: bytes);
    } catch (e) {
      debugPrint('FilePickerIO error: $e');
      return null;
    }
  }
}
