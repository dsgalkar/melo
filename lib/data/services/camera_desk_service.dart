import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraDeskService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _hasPermission = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized && _controller != null && _controller!.value.isInitialized;
  bool get hasPermission => _hasPermission;
  List<CameraDescription> get cameras => _cameras;

  Future<bool> initCamera() async {
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }

      if (_cameras.isEmpty) {
        _isInitialized = false;
        return false;
      }

      // Default to back camera (looking down at desk) or first camera
      final camera = _cameras[_selectedCameraIndex];
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
      _hasPermission = true;
      return true;
    } catch (e) {
      debugPrint('CameraDeskService initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    await initCamera();
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
