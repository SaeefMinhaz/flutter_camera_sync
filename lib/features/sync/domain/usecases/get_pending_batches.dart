import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';

import '../../../camera/domain/entities/capture_batch.dart';
import '../repositories/batch_repository.dart';

class GetPendingBatches extends UseCase<List<CaptureBatch>, NoParams> {
  final BatchRepository _repository;

  GetPendingBatches(this._repository);

  @override
  Future<Result<List<CaptureBatch>>> call(NoParams params) {
    return _repository.getPendingBatches();
  }
}

