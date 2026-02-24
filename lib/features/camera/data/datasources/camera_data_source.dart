import 'package:camera/camera.dart';

/// Thin wrapper around the `camera` plugin.
///
/// This class keeps direct plugin calls in one place so that the
/// repository and higher layers stay easier to read.
class CameraDataSource {
  CameraController? _controller;

  CameraController? get controller => _controller;

  Future<List<CameraDescription>> loadAvailableCameras() {
    return availableCameras();
  }

  Future<CameraController> initialize(CameraDescription description) async {
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    _controller = controller;
    return controller;
  }

  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<XFile> takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('Camera is not ready');
    }
    return controller.takePicture();
  }
}

