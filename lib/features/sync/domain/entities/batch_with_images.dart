import 'package:equatable/equatable.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/capture_batch.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/captured_image.dart';

/// Aggregates a capture batch with all of its images.
class BatchWithImages extends Equatable {
  const BatchWithImages({
    required this.batch,
    required this.images,
  });

  final CaptureBatch batch;
  final List<CapturedImage> images;

  @override
  List<Object?> get props => <Object?>[batch, images];
}

