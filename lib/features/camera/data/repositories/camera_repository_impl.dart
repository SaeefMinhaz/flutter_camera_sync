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
    // This will be refined in the advanced controls feature.
    return Result.success(false);
  }

  @override
  Future<Result<bool>> isZoomSupported() async {
    // This will be refined in the advanced controls feature.
    return Result.success(false);
  }

  @override
  Future<Result<void>> setZoom(double level) async {
    // Zoom support is added in the advanced controls feature.
    return Result.success(null);
  }

  @override
  Future<Result<void>> setFocusPoint(FocusPoint point) async {
    // Manual focus support is added in the advanced controls feature.
    return Result.success(null);
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

