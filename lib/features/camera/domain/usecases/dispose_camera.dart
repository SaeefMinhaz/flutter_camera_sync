import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';

import '../repositories/camera_repository.dart';

class DisposeCamera extends UseCase<void, NoParams> {
  final CameraRepository _repository;

  DisposeCamera(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.dispose();
  }
}

