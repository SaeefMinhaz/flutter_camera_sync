import 'package:camera/camera.dart';
import 'package:flutter_camera_sync/core/result/result.dart';

import '../entities/captured_image.dart';
import '../entities/camera_device.dart';
import '../entities/focus_point.dart';

/// Abstraction over the camera plugin and hardware quirks.
///
/// Implementations live in the data layer and are responsible for
/// talking to the `camera` package and any platform-specific details.
abstract class CameraRepository {
  Future<Result<List<CameraDevice>>> getAvailableCameras();

  /// Initializes the camera and returns a ready-to-use controller
  /// for the preview widget.
  Future<Result<CameraController>> initialize(CameraDevice device);

  Future<Result<void>> dispose();

  Future<Result<bool>> isFocusSupported();

  Future<Result<bool>> isZoomSupported();

  Future<Result<void>> setZoom(double level);

  Future<Result<void>> setFocusPoint(FocusPoint point);

  Future<Result<CapturedImage>> captureImage();
}

