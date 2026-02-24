import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter_camera_sync/core/error/failure.dart';
import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/captured_image.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/camera_device.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/focus_point.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/upload_status.dart';
import 'package:flutter_camera_sync/features/camera/domain/repositories/camera_repository.dart';

import '../datasources/camera_data_source.dart';

class CameraRepositoryImpl implements CameraRepository {
  final CameraDataSource _dataSource;

  CameraRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<CameraDevice>>> getAvailableCameras() async {
    try {
      final cameras = await _dataSource.loadAvailableCameras();
      final devices = cameras
          .map(
            (camera) => CameraDevice(
              id: camera.name,
              name: camera.name,
              isBackCamera: camera.lensDirection == CameraLensDirection.back,
            ),
          )
          .toList();
      return Result.success(devices);
    } catch (e) {
      return Result.failure(
        CameraFailure('Unable to read available cameras', cause: e),
      );
    }
  }

  @override
  Future<Result<CameraController>> initialize(CameraDevice device) async {
    try {
      final cameras = await _dataSource.loadAvailableCameras();
      final description = cameras.firstWhere(
        (c) => c.name == device.id,
        orElse: () => cameras.first,
      );
      final controller = await _dataSource.initialize(description);
      return Result.success(controller);
    } catch (e) {
      return Result.failure(
        CameraFailure('Unable to initialize camera', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> dispose() async {
    try {
      await _dataSource.dispose();
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CameraFailure('Unable to dispose camera', cause: e),
      );
    }
  }

  @override
  Future<Result<bool>> isFocusSupported() async {
    try {
      final controller = _dataSource.controller;
      if (controller == null || !controller.value.isInitialized) {
        return Result.success(false);
      }
      return Result.success(controller.value.focusPointSupported);
    } catch (e) {
      return Result.failure(
        CameraFailure('Unable to check focus support', cause: e),
      );
    }
  }

  @override
  Future<Result<bool>> isZoomSupported() async {
    try {
      final controller = _dataSource.controller;
      if (controller == null || !controller.value.isInitialized) {
        return Result.success(false);
      }
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      return Result.success(maxZoom > minZoom);
    } catch (e) {
      return Result.failure(
        CameraFailure('Unable to check zoom support', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> setZoom(double level) async {
    try {
      final controller = _dataSource.controller;
      if (controller == null || !controller.value.isInitialized) {
        return Result.failure(
          const CameraFailure('Camera is not ready for zoom.'),
        );
      }
      await controller.setZoomLevel(level);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CameraFailure('Unable to change zoom level', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> setFocusPoint(FocusPoint point) async {
    try {
      final controller = _dataSource.controller;
      if (controller == null || !controller.value.isInitialized) {
        return Result.failure(
          const CameraFailure('Camera is not ready for focus.'),
        );
      }

      if (!controller.value.focusPointSupported) {
        return Result.failure(
          const CameraFailure(
            'Tap-to-focus is not supported on this device with this camera.',
          ),
        );
      }

      final offset = Offset(point.x, point.y);
      await controller.setFocusMode(FocusMode.auto);
      await controller.setFocusPoint(offset);
      await controller.setExposurePoint(offset);

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CameraFailure('Unable to set focus point', cause: e),
      );
    }
  }

  @override
  Future<Result<CapturedImage>> captureImage() async {
    try {
      final file = await _dataSource.takePicture();
      final image = CapturedImage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        filePath: file.path,
        capturedAt: DateTime.now(),
        uploadStatus: UploadStatus.pending,
      );
      return Result.success(image);
    } catch (e) {
      return Result.failure(
        CameraFailure('Unable to capture image', cause: e),
      );
    }
  }
}

