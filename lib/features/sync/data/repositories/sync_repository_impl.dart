import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_camera_sync/core/error/failure.dart';
import 'package:flutter_camera_sync/core/network/dio_client.dart';
import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/upload_status.dart';
import 'package:flutter_camera_sync/features/sync/domain/repositories/sync_repository.dart';

import '../../../../core/db/app_database.dart';
import '../mappers/image_mappers.dart';

/// Sync repository that reads pending images from Drift and uploads them
/// using Dio. Items always remain in the local queue; we only change
/// their status flags.
class SyncRepositoryImpl implements SyncRepository {
  final AppDatabase _db;
  final DioClient _client;

  SyncRepositoryImpl(this._db, this._client);

  @override
  Future<Result<void>> syncPending() async {
    try {
      final List<Image> pendingRows = await (_db.select(_db.images)
            ..where(
              (tbl) => tbl.uploadStatus.equals(UploadStatus.pending.name),
            ))
          .get();

      if (pendingRows.isEmpty) {
        return Result.success(null);
      }

      for (final Image row in pendingRows) {
        final image = imageFromRow(row);

        // Mark as uploading before we hit the network.
        await (_db.update(_db.images)..where((tbl) => tbl.id.equals(row.id)))
            .write(
          ImagesCompanion(
            uploadStatus: Value(UploadStatus.uploading.name),
          ),
        );

        try {
          await _client.uploadImage(
            filePath: image.filePath,
            batchId: image.batchId ?? image.id,
          );

          // Mark as uploaded on success.
          await (_db.update(_db.images)..where((tbl) => tbl.id.equals(row.id)))
              .write(
            ImagesCompanion(
              uploadStatus: Value(UploadStatus.uploaded.name),
            ),
          );
        } on DioException catch (e) {
          // Treat timeouts and connection problems as connectivity issues.
          if (_isConnectivityIssue(e)) {
            await (_db.update(_db.images)
                  ..where((tbl) => tbl.id.equals(row.id)))
                .write(
              ImagesCompanion(
                uploadStatus: Value(UploadStatus.pending.name),
              ),
            );

            return Result.failure(
              NetworkFailure(
                'Network problem while uploading images. They will be retried later.',
                cause: e,
              ),
            );
          }

          // Server or other unexpected HTTP errors.
          await (_db.update(_db.images)
                ..where((tbl) => tbl.id.equals(row.id)))
              .write(
            ImagesCompanion(
              uploadStatus: Value(UploadStatus.failed.name),
            ),
          );
        } catch (e) {
          await (_db.update(_db.images)
                ..where((tbl) => tbl.id.equals(row.id)))
              .write(
            ImagesCompanion(
              uploadStatus: Value(UploadStatus.failed.name),
            ),
          );
        }
      }

      // Update batch statuses: any batch with only uploaded images
      // and a pending status can move to uploaded.
      final List<Batch> pendingBatches = await (_db.select(_db.batches)
            ..where(
              (tbl) => tbl.status.equals(UploadStatus.pending.name),
            ))
          .get();

      for (final Batch batch in pendingBatches) {
        final List<Image> imagesForBatch = await (_db.select(_db.images)
              ..where((tbl) => tbl.batchId.equals(batch.id)))
            .get();

        if (imagesForBatch.isEmpty) {
          continue;
        }

        final bool allUploaded = imagesForBatch
            .every((img) => img.uploadStatus == UploadStatus.uploaded.name);

        if (allUploaded) {
          await (_db.update(_db.batches)
                ..where((tbl) => tbl.id.equals(batch.id)))
              .write(
            BatchesCompanion(
              status: Value(UploadStatus.uploaded.name),
            ),
          );
        }
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        StorageFailure(
          'Failed to read or update pending images in local database',
          cause: e,
        ),
      );
    }
  }

  bool _isConnectivityIssue(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }
}


