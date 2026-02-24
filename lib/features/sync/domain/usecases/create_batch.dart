import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';

import '../../../camera/domain/entities/capture_batch.dart';
import '../repositories/batch_repository.dart';

class CreateBatchParams {
  final String? label;

  const CreateBatchParams({this.label});
}

class CreateBatch extends UseCase<CaptureBatch, CreateBatchParams> {
  final BatchRepository _repository;

  CreateBatch(this._repository);

  @override
  Future<Result<CaptureBatch>> call(CreateBatchParams params) {
    return _repository.createBatch(label: params.label);
  }
}

