import 'package:flutter_camera_sync/core/error/failure.dart';
import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/capture_batch.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/upload_status.dart';

import '../../../../core/db/app_database.dart';

UploadStatus _statusFromString(String raw) {
  switch (raw) {
    case 'pending':
      return UploadStatus.pending;
    case 'uploading':
      return UploadStatus.uploading;
    case 'uploaded':
      return UploadStatus.uploaded;
    case 'failed':
      return UploadStatus.failed;
    default:
      return UploadStatus.pending;
  }
}

String _statusToString(UploadStatus status) {
  return status.name;
}

CaptureBatch batchFromRow(Batch row) {
  return CaptureBatch(
    id: row.id,
    createdAt: row.createdAt,
    label: row.label,
    status: _statusFromString(row.status),
  );
}

Result<T> mapDriftError<T>(Object error) {
  return Result.failure(StorageFailure('Problem talking to local database', cause: error));
}

String uploadStatusToDb(UploadStatus status) => _statusToString(status);

