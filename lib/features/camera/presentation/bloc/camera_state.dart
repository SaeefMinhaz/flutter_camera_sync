import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';

abstract class CameraState extends Equatable {
  const CameraState();

  @override
  List<Object?> get props => <Object?>[];
}

class CameraInitial extends CameraState {
  const CameraInitial();
}

class CameraLoading extends CameraState {
  const CameraLoading();
}

class CameraFailureState extends CameraState {
  final String message;

  const CameraFailureState(this.message);

  @override
  List<Object?> get props => <Object?>[message];
}

class CameraReady extends CameraState {
  final CameraController controller;
  final bool isCapturing;
  final String? lastCapturedImagePath;

  const CameraReady({
    required this.controller,
    this.isCapturing = false,
    this.lastCapturedImagePath,
  });

  CameraReady copyWith({
    CameraController? controller,
    bool? isCapturing,
    String? lastCapturedImagePath,
  }) {
    return CameraReady(
      controller: controller ?? this.controller,
      isCapturing: isCapturing ?? this.isCapturing,
      lastCapturedImagePath: lastCapturedImagePath ?? this.lastCapturedImagePath,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        controller,
        isCapturing,
        lastCapturedImagePath,
      ];
}

