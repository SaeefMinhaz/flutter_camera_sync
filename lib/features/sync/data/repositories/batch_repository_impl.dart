import 'package:drift/drift.dart' show Value;
import 'package:flutter_camera_sync/core/error/failure.dart';
import 'package:flutter_camera_sync/core/result/result.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/capture_batch.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/captured_image.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/upload_status.dart';
import 'package:flutter_camera_sync/features/sync/domain/repositories/batch_repository.dart';

import '../../../../core/db/app_database.dart';
import '../mappers/batch_mappers.dart';
import '../mappers/image_mappers.dart';

class BatchRepositoryImpl implements BatchRepository {
  final AppDatabase _db;

  BatchRepositoryImpl(this._db);

  @override
  Future<Result<CaptureBatch>> createBatch({String? label}) async {
    try {
      final batchCompanion = BatchesCompanion.insert(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        label: Value(label),
        status: uploadStatusToDb(UploadStatus.pending),
      );

      await _db.into(_db.batches).insert(batchCompanion);

      final created = CaptureBatch(
        id: batchCompanion.id.value,
        createdAt: batchCompanion.createdAt.value,
        label: batchCompanion.label.value,
        status: UploadStatus.pending,
      );

      return Result.success(created);
    } catch (e) {
      return mapDriftError<CaptureBatch>(e);
    }
  }

  @override
  Future<Result<void>> addImageToBatch({
    required String batchId,
    required CapturedImage image,
  }) async {
    try {
      final companion = ImagesCompanion.insert(
        id: image.id,
        filePath: image.filePath,
        capturedAt: image.capturedAt,
        batchId: Value(batchId),
        thumbnailPath: Value(image.thumbnailPath),
        width: Value(image.width),
        height: Value(image.height),
        deviceName: Value(image.deviceName),
        uploadStatus: imageUploadStatusToDb(image.uploadStatus),
      );

      await _db.into(_db.images).insert(companion);
      return Result.success(null);
    } catch (e) {
      return mapDriftError<void>(e);
    }
  }

  @override
  Future<Result<List<CaptureBatch>>> getPendingBatches() async {
    try {
      final rows = await (_db.select(_db.batches)
            ..where(
              (tbl) => tbl.status.equals(uploadStatusToDb(UploadStatus.pending)),
            ))
          .get();
      final batches = rows.map<CaptureBatch>(batchFromRow).toList();
      return Result.success(batches);
    } catch (e) {
      return mapDriftError<List<CaptureBatch>>(e);
    }
  }

  @override
  Future<Result<CaptureBatch?>> getBatchById(String id) async {
    try {
      final row = await (_db.select(_db.batches)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();
      if (row == null) {
        return Result.success(null);
      }
      return Result.success(batchFromRow(row));
    } catch (e) {
      return mapDriftError<CaptureBatch?>(e);
    }
  }

  @override
  Future<Result<void>> updateBatchStatus(
    String batchId,
    UploadStatus status,
  ) async {
    try {
      await (_db.update(_db.batches)..where((tbl) => tbl.id.equals(batchId))).write(
        BatchesCompanion(
          status: Value(uploadStatusToDb(status)),
        ),
      );
      return Result.success(null);
    } catch (e) {
      return mapDriftError<void>(e);
    }
  }

  @override
  Future<Result<void>> removeBatch(String batchId) async {
    try {
      await (_db.delete(_db.images)..where((tbl) => tbl.batchId.equals(batchId))).go();
      await (_db.delete(_db.batches)..where((tbl) => tbl.id.equals(batchId))).go();
      return Result.success(null);
    } catch (e) {
      return mapDriftError<void>(e);
    }
  }
}

