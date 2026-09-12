import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/attempt_record.dart';
import '../replay/replay_screen.dart';

class PerformanceAnalysisDialog extends StatelessWidget {
  final AttemptRecord attempt;
  final VoidCallback onTryAgain;

  const PerformanceAnalysisDialog({
    super.key,
    required this.attempt,
    required this.onTryAgain,
  });

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'S':
        return AppColors.primaryGold;
      case 'A':
        return AppColors.neonGreen;
      case 'B':
        return AppColors.neonCyan;
      case 'C':
        return AppColors.previewNoteGlow;
      default:
        return AppColors.error;
    }
  }

  void _shareAttempt(BuildContext context) {
    if (attempt.filePath.isNotEmpty) {
      SharePlus.instance.share(
        ShareParams(
          files: [XFile(attempt.filePath)],
          text: 'My Melo Piano Performance for ${attempt.songTitle}: ${attempt.accuracyPercent}% Accuracy! Grade ${attempt.grade}',
        ),
      );
    } else {
      SharePlus.instance.share(
        ShareParams(
          text: 'Melo Performance: ${attempt.songTitle} - ${attempt.accuracyPercent}% Accuracy, Grade ${attempt.grade}, Score: ${attempt.score}',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradeColor = _getGradeColor(attempt.grade);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: gradeColor.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Grade Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PERFORMANCE REPORT',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      attempt.songTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gradeColor.withValues(alpha: 0.2),
                    border: Border.all(color: gradeColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: gradeColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    attempt.grade,
                    style: TextStyle(
                      color: gradeColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Accuracy % Big Stat
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                children: [
                  Text(
                    '${attempt.accuracyPercent}%',
                    style: TextStyle(
                      color: gradeColor,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Note Hit Accuracy',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Avg Timing Dev',
                    value: '±${attempt.avgTimingDeviationMs}ms',
                    icon: Icons.timer,
                    color: AppColors.neonCyan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Total Score',
                    value: '${attempt.score} pts',
                    icon: Icons.emoji_events,
                    color: AppColors.primaryGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Correct Hits',
                    value: '${attempt.correctNotes} / ${attempt.totalNotes}',
                    icon: Icons.check_circle_outline,
                    color: AppColors.neonGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Missed / Extra',
                    value: '${attempt.missedNotes} / ${attempt.extraNotes}',
                    icon: Icons.error_outline,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.surfaceBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _shareAttempt(context),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => ReplayScreen(attempt: attempt),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow, size: 18, color: AppColors.neonCyan),
                    label: const Text('Replay'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onTryAgain();
                    },
                    child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
