import 'package:flutter_camera_sync/features/camera/domain/entities/captured_image.dart';
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

String imageUploadStatusToDb(UploadStatus status) {
  return status.name;
}

CapturedImage imageFromRow(Image row) {
  return CapturedImage(
    id: row.id,
    filePath: row.filePath,
    capturedAt: row.capturedAt,
    batchId: row.batchId,
    thumbnailPath: row.thumbnailPath,
    width: row.width,
    height: row.height,
    deviceName: row.deviceName,
    uploadStatus: _statusFromString(row.uploadStatus),
  );
}

