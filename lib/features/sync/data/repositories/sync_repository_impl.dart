import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/features/sync/domain/repositories/sync_repository.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/db/app_database.dart';

/// Local-only implementation for now.
///
/// This class is focused on making sure we have a clear hook
/// where background workers and UI can call into when it is
/// time to upload images. The actual network work will be
/// added in the sync feature later.
class SyncRepositoryImpl implements SyncRepository {
  final AppDatabase _db;

  SyncRepositoryImpl(this._db);

  @override
  Future<Result<void>> syncPending() async {
    try {
      // At this stage, we only prove out that we can read from the
      // local queue without doing any remote work yet.
      //
      // This method intentionally does not change any records so
      // that later features can plug in Dio-based uploads and
      // status updates cleanly.
      await _db.select(_db.images).get();
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        StorageFailure('Failed to read pending images from local database', cause: e),
      );
    }
  }
}

