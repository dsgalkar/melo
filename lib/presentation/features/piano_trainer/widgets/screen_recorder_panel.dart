import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ScreenRecorderPanel extends StatelessWidget {
  final bool isRecording;
  final int notesCount;
  final int elapsedMs;
  final VoidCallback onStopRecording;

  const ScreenRecorderPanel({
    super.key,
    required this.isRecording,
    required this.notesCount,
    required this.elapsedMs,
    required this.onStopRecording,
  });

  String _formatTime(int ms) {
    final seconds = (ms / 1000).floor();
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (!isRecording) return const SizedBox.shrink();

    return Positioned(
      top: 14,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Blinking Red Recording Dot
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(elapsedMs),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$notesCount notes',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: onStopRecording,
              child: const Text('Stop & Analyze', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
