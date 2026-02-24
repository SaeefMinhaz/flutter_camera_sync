import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';

import '../entities/focus_point.dart';
import '../repositories/camera_repository.dart';

class SetFocusPoint extends UseCase<void, FocusPoint> {
  final CameraRepository _repository;

  SetFocusPoint(this._repository);

  @override
  Future<Result<void>> call(FocusPoint params) {
    return _repository.setFocusPoint(params);
  }
}

