import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';

import '../repositories/sync_repository.dart';

/// High-level entry point used by foreground UI or background workers
/// to run the upload logic.
class SyncPendingBatches extends UseCase<void, NoParams> {
  final SyncRepository _repository;

  SyncPendingBatches(this._repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.syncPending();
  }
}

