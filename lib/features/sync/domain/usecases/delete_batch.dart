import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';

import '../repositories/batch_repository.dart';

/// Deletes a batch and all of its images.
class DeleteBatch extends UseCase<void, String> {
  DeleteBatch(this._repository);

  final BatchRepository _repository;

  @override
  Future<Result<void>> call(String batchId) {
    return _repository.removeBatch(batchId);
  }
}

