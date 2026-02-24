import 'package:flutter_camera_sync/core/result/result.dart';

/// Orchestrates the upload of pending images and batches.
///
/// The implementation will talk to local storage (Drift) and remote
/// APIs (Dio) while keeping the domain API small and easy to test.
abstract class SyncRepository {
  /// Tries to upload all pending work.
  ///
  /// The implementation is responsible for leaving items in the local
  /// queue when the connection is poor or offline.
  Future<Result<void>> syncPending();
}

