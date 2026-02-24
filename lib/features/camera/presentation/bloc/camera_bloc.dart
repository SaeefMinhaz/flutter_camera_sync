import 'dart:async';
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_camera_sync/core/error/failure.dart';
import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/core/services/permission_service.dart';
import 'package:flutter_camera_sync/core/storage/local_file_storage.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';
import 'package:flutter_camera_sync/features/camera/domain/domain.dart';
import 'package:flutter_camera_sync/features/sync/domain/domain.dart';
import 'package:path/path.dart' as p;

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
  final CreateBatch _createBatch;
  final AddImageToBatch _addImageToBatch;
  final LocalFileStorage _fileStorage;
  final SyncPendingBatches _syncPendingBatches;

  CameraBloc({
    required PermissionService permissionService,
    required GetAvailableCameras getAvailableCameras,
    required InitializeCamera initializeCamera,
    required DisposeCamera disposeCamera,
    required CaptureImage captureImage,
    required ChangeZoom changeZoom,
    required SetFocusPoint setFocusPoint,
    required CreateBatch createBatch,
    required AddImageToBatch addImageToBatch,
    required LocalFileStorage fileStorage,
    required SyncPendingBatches syncPendingBatches,
  })  : _permissionService = permissionService,
        _getAvailableCameras = getAvailableCameras,
        _initializeCamera = initializeCamera,
        _disposeCamera = disposeCamera,
        _captureImage = captureImage,
        _changeZoom = changeZoom,
        _setFocusPoint = setFocusPoint,
        _createBatch = createBatch,
        _addImageToBatch = addImageToBatch,
        _fileStorage = fileStorage,
        _syncPendingBatches = syncPendingBatches,
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

    final bool hasPermission = await _permissionService.ensureCameraPermission();
    if (!hasPermission) {
      final bool permanentlyDenied =
          await _permissionService.isCameraPermanentlyDenied();
      if (permanentlyDenied) {
        emit(
          const CameraFailureState(
            'Camera permission has been permanently denied.\n'
            'Please enable it in system settings to take photos.',
          ),
        );
      } else {
        emit(
          const CameraFailureState(
            'Camera permission is required to take photos.\n'
            'Please grant it when asked.',
          ),
        );
      }
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

    // Ensure we have a batch for this capture session.
    CaptureBatch? batch = currentState.currentBatch;
    if (batch == null) {
      final batchResult = await _createBatch(const CreateBatchParams());
      if (batchResult.isFailure || batchResult.value == null) {
        final failure = batchResult.failure;
        emit(
          CameraFailureState(
            _friendlyMessage(
              failure,
              fallback: 'Could not start a new batch for this capture.',
            ),
          ),
        );
        emit(currentState.copyWith(isCapturing: false));
        return;
      }
      batch = batchResult.value!;
    }

    final captureResult = await _captureImage(const NoParams());
    if (captureResult.isFailure || captureResult.value == null) {
      final failure = captureResult.failure;
      emit(
        CameraFailureState(
          _friendlyMessage(
            failure,
            fallback: 'Something went wrong while taking the photo.',
          ),
        ),
      );
      emit(currentState.copyWith(isCapturing: false));
      return;
    }

    final captured = captureResult.value!;

    // Copy the image into our own storage area and attach it to the batch.
    String storedPath;
    try {
      final fileName = p.basename(captured.filePath);
      storedPath = await _fileStorage.copyImageIntoStorage(
        sourcePath: captured.filePath,
        batchId: batch.id,
        fileName: fileName,
      );
    } catch (e) {
      emit(
        CameraFailureState(
          'Photo was taken but could not be moved into local storage.',
        ),
      );
      emit(currentState.copyWith(isCapturing: false));
      return;
    }

    final storedImage = captured.copyWith(
      filePath: storedPath,
      batchId: batch.id,
    );

    final addResult = await _addImageToBatch(
      AddImageToBatchParams(
        batchId: batch.id,
        image: storedImage,
      ),
    );

    if (addResult.isFailure) {
      final failure = addResult.failure;
      emit(
        CameraFailureState(
          _friendlyMessage(
            failure,
            fallback: 'Photo was taken but could not be queued for upload.',
          ),
        ),
      );
      emit(currentState.copyWith(isCapturing: false));
      return;
    }

    emit(
      currentState.copyWith(
        isCapturing: false,
        lastCapturedImagePath: storedImage.filePath,
        currentBatch: batch,
      ),
    );

    // Hybrid upload: try sync immediately in background; Workmanager will retry later if needed.
    unawaited(
      _syncPendingBatches(const NoParams()).catchError(
        (Object _) => Result.failure(const UnexpectedFailure('Background sync failed')),
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

