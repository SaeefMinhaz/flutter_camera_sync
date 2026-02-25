import 'package:flutter_camera_sync/core/result/result.dart';

import '../../../camera/domain/entities/capture_batch.dart';
import '../../../camera/domain/entities/captured_image.dart';
import '../../../camera/domain/entities/upload_status.dart';
import '../entities/batch_with_images.dart';

/// Handles creation and persistence of batches and their images.
abstract class BatchRepository {
  Future<Result<CaptureBatch>> createBatch({String? label});

  Future<Result<void>> addImageToBatch({
    required String batchId,
    required CapturedImage image,
  });

  Future<Result<List<CaptureBatch>>> getPendingBatches();

  /// Returns all pending batches together with their images.
  Future<Result<List<BatchWithImages>>> getPendingBatchesWithImages();

  /// Returns all batches (any status) together with their images.
  Future<Result<List<BatchWithImages>>> getAllBatchesWithImages();

  Future<Result<CaptureBatch?>> getBatchById(String id);

  Future<Result<void>> updateBatchStatus(
    String batchId,
    UploadStatus status,
  );

  Future<Result<void>> removeBatch(String batchId);
}

