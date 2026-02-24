import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';

import '../entities/captured_image.dart';
import '../repositories/camera_repository.dart';

class CaptureImage extends UseCase<CapturedImage, NoParams> {
  final CameraRepository _repository;

  CaptureImage(this._repository);

  @override
  Future<Result<CapturedImage>> call(NoParams params) {
    return _repository.captureImage();
  }
}

