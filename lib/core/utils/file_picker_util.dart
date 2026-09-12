import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FilePickerUtil {
  /// Cross-platform file picker that handles Web blob URLs and Native file paths
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

      Uint8List? bytes;

      if (kIsWeb) {
        if (path != null && path.isNotEmpty) {
          // On Web, file_picker creates a browser Blob URL (e.g. blob:http://...)
          final response = await http.get(Uri.parse(path));
          if (response.statusCode == 200) {
            bytes = response.bodyBytes;
          }
        }
      } else {
        if (path != null && path.isNotEmpty) {
          bytes = await File(path).readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        debugPrint('FilePickerUtil: Could not retrieve bytes for ${file.name}');
        return null;
      }

      return (name: file.name, bytes: bytes);
    } catch (e) {
      debugPrint('FilePickerUtil error: $e');
      return null;
    }
  }
}
