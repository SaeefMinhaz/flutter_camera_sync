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

