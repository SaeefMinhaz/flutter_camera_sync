import 'package:equatable/equatable.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class CameraStarted extends CameraEvent {
  const CameraStarted();
}

class CameraStopped extends CameraEvent {
  const CameraStopped();
}

class CameraCapturePressed extends CameraEvent {
  const CameraCapturePressed();
}

class CameraZoomChanged extends CameraEvent {
  final double zoom;

  const CameraZoomChanged(this.zoom);

  @override
  List<Object?> get props => <Object?>[zoom];
}

class CameraFocusRequested extends CameraEvent {
  /// Normalized tap position within the preview (0.0–1.0).
  final double x;
  final double y;

  const CameraFocusRequested({
    required this.x,
    required this.y,
  });

  @override
  List<Object?> get props => <Object?>[x, y];
}

