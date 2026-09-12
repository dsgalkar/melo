import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/camera_desk_service.dart';

class DeskCameraOverlay extends StatefulWidget {
  final Widget child; // The piano & waterfall widget
  final bool isCameraActive;
  final double tiltAngle; // in radians
  final double opacity;
  final bool showDeskGuide;
  final VoidCallback? onSwitchCamera;

  const DeskCameraOverlay({
    super.key,
    required this.child,
    required this.isCameraActive,
    this.tiltAngle = 0.25,
    this.opacity = 0.90,
    this.showDeskGuide = true,
    this.onSwitchCamera,
  });

  @override
  State<DeskCameraOverlay> createState() => _DeskCameraOverlayState();
}

class _DeskCameraOverlayState extends State<DeskCameraOverlay> {
  final CameraDeskService _cameraService = CameraDeskService();
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.isCameraActive) {
      _initCamera();
    }
  }

  @override
  void didUpdateWidget(covariant DeskCameraOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCameraActive != oldWidget.isCameraActive) {
      if (widget.isCameraActive) {
        _initCamera();
      } else {
        _cameraService.dispose();
        setState(() => _cameraReady = false);
      }
    }
  }

  Future<void> _initCamera() async {
    final success = await _cameraService.initCamera();
    if (mounted) {
      setState(() => _cameraReady = success);
    }
  }

  Future<void> _switchCamera() async {
    await _cameraService.switchCamera();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isCameraActive) {
      return widget.child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Camera Feed or Desk Simulator Background
        if (_cameraReady && _cameraService.controller != null)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _cameraService.controller!.value.previewSize?.height ?? 1280,
                height: _cameraService.controller!.value.previewSize?.width ?? 720,
                child: CameraPreview(_cameraService.controller!),
              ),
            ),
          )
        else
          // High quality simulated desk surface with depth perspective
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, 0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFF2B2620), // Rich dark walnut desk wood
                    Color(0xFF161412),
                    Color(0xFF0D0B0A),
                  ],
                ),
              ),
              child: CustomPaint(
                painter: _DeskPerspectiveGridPainter(),
              ),
            ),
          ),

        // 2. Desk Placement Alignment Reticle & Grid
        if (widget.showDeskGuide)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DeskGuidePainter(),
              ),
            ),
          ),

        // 3. 3D Perspective-Transformed Piano on Desk
        Positioned.fill(
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015) // Perspective vanishing point
              ..rotateX(widget.tiltAngle), // Desk slant
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: widget.opacity.clamp(0.2, 1.0),
              child: widget.child,
            ),
          ),
        ),

        // 4. Camera HUD Badge / Controls
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam, color: AppColors.primaryGold, size: 16),
                const SizedBox(width: 6),
                Text(
                  _cameraReady ? 'Desk AR Mode' : 'Desk Simulator Mode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_cameraReady && _cameraService.cameras.length > 1) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _switchCamera,
                    child: const Icon(Icons.flip_camera_ios, color: Colors.white70, size: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeskGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryGold.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Corner brackets framing the desk placement zone
    const margin = 24.0;
    const cornerLength = 32.0;
    final top = size.height * 0.40;
    final bottom = size.height - margin;
    final left = margin;
    final right = size.width - margin;

    // Top-Left corner
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), paint);

    // Top-Right corner
    canvas.drawLine(Offset(right, top), Offset(right - cornerLength, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), paint);

    // Bottom-Left corner
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left, bottom - cornerLength), paint);

    // Bottom-Right corner
    canvas.drawLine(Offset(right, bottom), Offset(right - cornerLength, bottom), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DeskPerspectiveGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    final vanishingPoint = Offset(size.width / 2, size.height * 0.15);

    // Perspective depth lines
    for (double i = 0; i <= size.width; i += size.width / 12) {
      canvas.drawLine(vanishingPoint, Offset(i, size.height), paint);
    }

    // Horizontal perspective lines
    for (double y = size.height * 0.35; y <= size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
