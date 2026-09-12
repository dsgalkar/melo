import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'file_storage_service.dart';

class BackupRestoreResult {
  final bool success;
  final String message;
  final int filesCount;
  final String? backupFilePath;

  const BackupRestoreResult({
    required this.success,
    required this.message,
    this.filesCount = 0,
    this.backupFilePath,
  });
}

class BackupRestoreService {
  final FileStorageService _storageService;

  BackupRestoreService(this._storageService);

  /// Exports the entire /VirtualPiano/ folder into a .zip archive
  Future<BackupRestoreResult> exportBackupZip() async {
    try {
      final rootDir = await _storageService.getRootDirectory();
      if (!await rootDir.exists()) {
        return const BackupRestoreResult(
          success: false,
          message: 'No VirtualPiano directory found to back up.',
        );
      }

      final archive = Archive();
      int filesCount = 0;

      final entities = await rootDir.list(recursive: true).toList();
      for (final entity in entities) {
        if (entity is File) {
          // Relative path inside zip
          final relPath = entity.path.substring(rootDir.path.length + 1).replaceAll('\\', '/');
          final fileBytes = await entity.readAsBytes();
          archive.addFile(ArchiveFile(relPath, fileBytes.length, fileBytes));
          filesCount++;
        }
      }

      if (filesCount == 0) {
        return const BackupRestoreResult(
          success: false,
          message: 'No songs or attempts found to back up.',
        );
      }

      final encoder = ZipEncoder();
      final zipData = encoder.encode(archive);

      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd_HH-mm').format(now);
      final backupFileName = 'Melo_VirtualPiano_Backup_$dateStr.zip';
      final backupFile = File('${rootDir.parent.path}/$backupFileName');
      await backupFile.writeAsBytes(zipData);

      return BackupRestoreResult(
        success: true,
        message: 'Successfully exported $filesCount files to ${backupFile.path}',
        filesCount: filesCount,
        backupFilePath: backupFile.path,
      );
    } catch (e) {
      debugPrint('Backup export error: $e');
      return BackupRestoreResult(
        success: false,
        message: 'Export failed: $e',
      );
    }
  }

  /// Restores songs and attempts from an imported ZIP byte stream
  Future<BackupRestoreResult> restoreBackupZip(Uint8List zipBytes) async {
    try {
      final decoder = ZipDecoder();
      final archive = decoder.decodeBytes(zipBytes);
      final rootDir = await _storageService.getRootDirectory();

      int restoredCount = 0;

      for (final file in archive) {
        if (file.isFile) {
          final outPath = '${rootDir.path}/${file.name}';
          final outFile = File(outPath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
          restoredCount++;
        }
      }

      return BackupRestoreResult(
        success: true,
        message: 'Successfully restored $restoredCount files from backup archive.',
        filesCount: restoredCount,
      );
    } catch (e) {
      debugPrint('Backup restore error: $e');
      return BackupRestoreResult(
        success: false,
        message: 'Restore failed: $e',
      );
    }
  }
}
