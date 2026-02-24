import 'package:camera/camera.dart';
import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';

import '../entities/camera_device.dart';
import '../repositories/camera_repository.dart';

class InitializeCamera extends UseCase<CameraController, CameraDevice> {
  final CameraRepository _repository;

  InitializeCamera(this._repository);

  @override
  Future<Result<CameraController>> call(CameraDevice params) {
    return _repository.initialize(params);
  }
}

