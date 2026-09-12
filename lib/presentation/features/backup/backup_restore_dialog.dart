import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/song_providers.dart';

class BackupRestoreDialog extends ConsumerStatefulWidget {
  const BackupRestoreDialog({super.key});

  @override
  ConsumerState<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends ConsumerState<BackupRestoreDialog> {
  bool _isLoading = false;
  String? _statusMessage;

  void _exportBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Exporting /VirtualPiano/ folder into ZIP archive...';
    });

    final backupService = ref.read(backupRestoreServiceProvider);
    final result = await backupService.exportBackupZip();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = result.message;
      });

      if (result.success && result.backupFilePath != null) {
        // Offer native sharing
        SharePlus.instance.share(
          ShareParams(
            files: [XFile(result.backupFilePath!)],
            text: 'Melo VirtualPiano Backup Archive',
          ),
        );
      }
    }
  }

  void _importBackup() async {
    final files = await FilePickerPlatform.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (files.isEmpty) return;

    final file = files.first;
    final path = file.path;
    if (path == null) {
      setState(() => _statusMessage = 'Could not access selected backup file path.');
      return;
    }

    final bytes = await File(path).readAsBytes();

    setState(() {
      _isLoading = true;
      _statusMessage = 'Restoring songs and attempts from ZIP archive...';
    });

    final backupService = ref.read(backupRestoreServiceProvider);
    final result = await backupService.restoreBackupZip(bytes);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = result.message;
      });

      if (result.success) {
        ref.read(songListProvider.notifier).loadSongs(forceRefresh: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      title: const Row(
        children: [
          Icon(Icons.cloud_sync, color: AppColors.primaryGold),
          SizedBox(width: 10),
          Text(
            'Backup & Restore',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export your entire /VirtualPiano/ library (songs, MIDI files, and recorded attempts) into a ZIP archive, or restore a previous backup.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: AppColors.primaryGold),
              ),
            ),
          if (_statusMessage != null && !_isLoading)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Text(
                _statusMessage!,
                style: const TextStyle(color: AppColors.neonCyan, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _exportBackup,
                  icon: const Icon(Icons.archive, size: 18, color: AppColors.primaryGold),
                  label: const Text('Export ZIP'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _importBackup,
                  icon: const Icon(Icons.unarchive, size: 18),
                  label: const Text('Import ZIP', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}
