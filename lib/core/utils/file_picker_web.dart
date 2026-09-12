// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class FilePickerPlatformImpl {
  static Future<({String name, Uint8List bytes})?> pickFile({
    required List<String> allowedExtensions,
  }) async {
    final completer = Completer<({String name, Uint8List bytes})?>();

    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = allowedExtensions.map((e) => '.$e').join(',');
    uploadInput.multiple = false;

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      final file = files.first;
      final reader = html.FileReader();

      reader.onLoadEnd.listen((_) {
        if (reader.result != null) {
          final bytes = Uint8List.fromList(reader.result as List<int>);
          if (!completer.isCompleted) {
            completer.complete((name: file.name, bytes: bytes));
          }
        } else {
          if (!completer.isCompleted) completer.complete(null);
        }
      });

      reader.onError.listen((_) {
        if (!completer.isCompleted) completer.complete(null);
      });

      reader.readAsArrayBuffer(file);
    });

    uploadInput.click();
    return completer.future;
  }
}
