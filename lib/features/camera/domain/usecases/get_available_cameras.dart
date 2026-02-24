import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';

import '../entities/camera_device.dart';
import '../repositories/camera_repository.dart';

class GetAvailableCameras extends UseCase<List<CameraDevice>, NoParams> {
  final CameraRepository _repository;

  GetAvailableCameras(this._repository);

  @override
  Future<Result<List<CameraDevice>>> call(NoParams params) {
    return _repository.getAvailableCameras();
  }
}

