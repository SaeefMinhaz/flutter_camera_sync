import 'dart:ui';

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
  final double minZoom;
  final double maxZoom;
  final double currentZoom;
  final bool isZoomSupported;
  final bool isFocusSupported;
  final Offset? focusPoint;

  const CameraReady({
    required this.controller,
    this.isCapturing = false,
    this.lastCapturedImagePath,
    this.minZoom = 1.0,
    this.maxZoom = 1.0,
    this.currentZoom = 1.0,
    this.isZoomSupported = false,
    this.isFocusSupported = false,
    this.focusPoint,
  });

  CameraReady copyWith({
    CameraController? controller,
    bool? isCapturing,
    String? lastCapturedImagePath,
    double? minZoom,
    double? maxZoom,
    double? currentZoom,
    bool? isZoomSupported,
    bool? isFocusSupported,
    Offset? focusPoint,
  }) {
    return CameraReady(
      controller: controller ?? this.controller,
      isCapturing: isCapturing ?? this.isCapturing,
      lastCapturedImagePath:
          lastCapturedImagePath ?? this.lastCapturedImagePath,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      currentZoom: currentZoom ?? this.currentZoom,
      isZoomSupported: isZoomSupported ?? this.isZoomSupported,
      isFocusSupported: isFocusSupported ?? this.isFocusSupported,
      focusPoint: focusPoint ?? this.focusPoint,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        controller,
        isCapturing,
        lastCapturedImagePath,
        minZoom,
        maxZoom,
        currentZoom,
        isZoomSupported,
        isFocusSupported,
        focusPoint,
      ];
}

