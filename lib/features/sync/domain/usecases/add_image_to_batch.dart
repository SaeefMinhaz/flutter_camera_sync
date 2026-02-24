import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';

import '../../../camera/domain/entities/captured_image.dart';
import '../repositories/batch_repository.dart';

class AddImageToBatchParams {
  final String batchId;
  final CapturedImage image;

  const AddImageToBatchParams({
    required this.batchId,
    required this.image,
  });
}

class AddImageToBatch extends UseCase<void, AddImageToBatchParams> {
  final BatchRepository _repository;

  AddImageToBatch(this._repository);

  @override
  Future<Result<void>> call(AddImageToBatchParams params) {
    return _repository.addImageToBatch(
      batchId: params.batchId,
      image: params.image,
    );
  }
}

