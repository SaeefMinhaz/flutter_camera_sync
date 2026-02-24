import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_camera_sync/core/error/failure.dart';
import 'package:flutter_camera_sync/core/services/permission_service.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';
import 'package:flutter_camera_sync/features/camera/domain/domain.dart';

import 'camera_event.dart';
import 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final PermissionService _permissionService;
  final GetAvailableCameras _getAvailableCameras;
  final InitializeCamera _initializeCamera;
  final DisposeCamera _disposeCamera;
  final CaptureImage _captureImage;
  final ChangeZoom _changeZoom;
  final SetFocusPoint _setFocusPoint;

  CameraBloc({
    required PermissionService permissionService,
    required GetAvailableCameras getAvailableCameras,
    required InitializeCamera initializeCamera,
    required DisposeCamera disposeCamera,
    required CaptureImage captureImage,
    required ChangeZoom changeZoom,
    required SetFocusPoint setFocusPoint,
  })  : _permissionService = permissionService,
        _getAvailableCameras = getAvailableCameras,
        _initializeCamera = initializeCamera,
        _disposeCamera = disposeCamera,
        _captureImage = captureImage,
        _changeZoom = changeZoom,
        _setFocusPoint = setFocusPoint,
        super(const CameraInitial()) {
    on<CameraStarted>(_onStarted);
    on<CameraStopped>(_onStopped);
    on<CameraCapturePressed>(_onCapturePressed);
    on<CameraZoomChanged>(_onZoomChanged);
    on<CameraFocusRequested>(_onFocusRequested);
  }

  Future<void> _onStarted(
    CameraStarted event,
    Emitter<CameraState> emit,
  ) async {
    emit(const CameraLoading());

    final hasPermission = await _permissionService.ensureCameraPermission();
    if (!hasPermission) {
      emit(const CameraFailureState(
        'Camera permission is required to take photos. Please grant it in system settings.',
      ));
      return;
    }

    final camerasResult = await _getAvailableCameras(const NoParams());
    if (camerasResult.isFailure || camerasResult.value == null || camerasResult.value!.isEmpty) {
      final failure = camerasResult.failure;
      emit(CameraFailureState(
        _friendlyMessage(
          failure,
          fallback: 'No cameras were found on this device.',
        ),
      ));
      return;
    }

    final devices = camerasResult.value!;
    final CameraDevice selected =
        devices.firstWhere((d) => d.isBackCamera, orElse: () => devices.first);

    final initResult = await _initializeCamera(selected);
    if (initResult.isFailure || initResult.value == null) {
      final failure = initResult.failure;
      emit(CameraFailureState(
        _friendlyMessage(
          failure,
          fallback: 'Could not start the camera.',
        ),
      ));
      return;
    }

    final controller = initResult.value!;

    double minZoom = 1.0;
    double maxZoom = 1.0;
    bool zoomSupported = false;

    try {
      minZoom = await controller.getMinZoomLevel();
      maxZoom = await controller.getMaxZoomLevel();
      zoomSupported = maxZoom > minZoom;
    } catch (_) {
      minZoom = 1.0;
      maxZoom = 1.0;
      zoomSupported = false;
    }

    final focusSupported = controller.value.focusPointSupported;

    emit(
      CameraReady(
        controller: controller,
        minZoom: minZoom,
        maxZoom: maxZoom,
        currentZoom: (1.0).clamp(minZoom, maxZoom),
        isZoomSupported: zoomSupported,
        isFocusSupported: focusSupported,
      ),
    );
  }

  Future<void> _onStopped(
    CameraStopped event,
    Emitter<CameraState> emit,
  ) async {
    await _disposeCamera(const NoParams());
    emit(const CameraInitial());
  }

  Future<void> _onCapturePressed(
    CameraCapturePressed event,
    Emitter<CameraState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CameraReady || currentState.isCapturing) {
      return;
    }

    emit(currentState.copyWith(isCapturing: true));

    final result = await _captureImage(const NoParams());
    if (result.isFailure || result.value == null) {
      final failure = result.failure;
      emit(CameraFailureState(
        _friendlyMessage(
          failure,
          fallback: 'Something went wrong while taking the photo.',
        ),
      ));
      return;
    }

    final image = result.value!;
    emit(
      currentState.copyWith(
        isCapturing: false,
        lastCapturedImagePath: image.filePath,
      ),
    );
  }

  Future<void> _onZoomChanged(
    CameraZoomChanged event,
    Emitter<CameraState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CameraReady || !currentState.isZoomSupported) {
      return;
    }

    final double clampedZoom =
        event.zoom.clamp(currentState.minZoom, currentState.maxZoom);

    if (clampedZoom == currentState.currentZoom) {
      return;
    }

    await _changeZoom(clampedZoom);

    emit(
      currentState.copyWith(
        currentZoom: clampedZoom,
      ),
    );
  }

  Future<void> _onFocusRequested(
    CameraFocusRequested event,
    Emitter<CameraState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CameraReady || !currentState.isFocusSupported) {
      return;
    }

    final normalizedX = event.x.clamp(0.0, 1.0);
    final normalizedY = event.y.clamp(0.0, 1.0);

    await _setFocusPoint(
      FocusPoint(
        x: normalizedX,
        y: normalizedY,
      ),
    );

    emit(
      currentState.copyWith(
        focusPoint: Offset(normalizedX, normalizedY),
      ),
    );
  }

  String _friendlyMessage(Failure? failure, {required String fallback}) {
    if (failure == null) {
      return fallback;
    }
    if (failure.message.isEmpty) {
      return fallback;
    }
    return failure.message;
  }
}

