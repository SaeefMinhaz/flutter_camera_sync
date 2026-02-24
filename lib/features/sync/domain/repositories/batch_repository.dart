import 'package:flutter_camera_sync/core/result/result.dart';

import '../../../camera/domain/entities/capture_batch.dart';
import '../../../camera/domain/entities/captured_image.dart';
import '../../../camera/domain/entities/upload_status.dart';

/// Handles creation and persistence of batches and their images.
abstract class BatchRepository {
  Future<Result<CaptureBatch>> createBatch({String? label});

  Future<Result<void>> addImageToBatch({
    required String batchId,
    required CapturedImage image,
  });

  Future<Result<List<CaptureBatch>>> getPendingBatches();

  Future<Result<CaptureBatch?>> getBatchById(String id);

  Future<Result<void>> updateBatchStatus(
    String batchId,
    UploadStatus status,
  );

  Future<Result<void>> removeBatch(String batchId);
}

