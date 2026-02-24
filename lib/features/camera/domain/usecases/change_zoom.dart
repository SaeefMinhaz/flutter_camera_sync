import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';

import '../repositories/camera_repository.dart';

class ChangeZoom extends UseCase<void, double> {
  final CameraRepository _repository;

  ChangeZoom(this._repository);

  @override
  Future<Result<void>> call(double params) {
    return _repository.setZoom(params);
  }
}

