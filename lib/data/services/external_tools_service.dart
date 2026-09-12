import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalToolsService {
  static const String basicPitchUrl = 'https://basicpitch.spotify.com/';

  /// Shows confirmation dialog before opening Spotify Basic Pitch in browser
  static Future<bool> showBasicPitchRedirectDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161A20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2E3544)),
        ),
        title: const Row(
          children: [
            Icon(Icons.open_in_browser, color: Color(0xFFFFC837)),
            SizedBox(width: 10),
            Text(
              'Convert MP3 to MIDI',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Convert your MP3 to MIDI using this free tool, download the MIDI file, and upload it here.',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'Powered by Spotify Basic Pitch neural audio-to-MIDI model.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC837),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Open Basic Pitch', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true) {
      await openBasicPitch();
      return true;
    }
    return false;
  }

  /// Launch Spotify Basic Pitch URL in external browser
  static Future<void> openBasicPitch() async {
    final uri = Uri.parse(basicPitchUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
