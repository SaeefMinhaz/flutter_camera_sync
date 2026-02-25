import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';
import 'package:flutter_camera_sync/features/sync/domain/entities/batch_with_images.dart';

import '../repositories/batch_repository.dart';

/// Returns all batches (any status) together with their images.
class GetAllBatchesWithImages
    extends UseCase<List<BatchWithImages>, NoParams> {
  GetAllBatchesWithImages(this._repository);

  final BatchRepository _repository;

  @override
  Future<Result<List<BatchWithImages>>> call(NoParams params) {
    return _repository.getAllBatchesWithImages();
  }
}

