import 'package:equatable/equatable.dart';

import 'upload_status.dart';

/// Single photo captured by the user.
///
/// The [batchId] is optional here. The camera flow can create images
/// first and the batching logic can attach them to a batch afterwards.
class CapturedImage extends Equatable {
  final String id;
  final String filePath;
  final DateTime capturedAt;

  final String? batchId;
  final String? thumbnailPath;
  final int? width;
  final int? height;
  final String? deviceName;
  final UploadStatus uploadStatus;

  const CapturedImage({
    required this.id,
    required this.filePath,
    required this.capturedAt,
    this.batchId,
    this.thumbnailPath,
    this.width,
    this.height,
    this.deviceName,
    this.uploadStatus = UploadStatus.pending,
  });

  CapturedImage copyWith({
    String? id,
    String? filePath,
    DateTime? capturedAt,
    String? batchId,
    String? thumbnailPath,
    int? width,
    int? height,
    String? deviceName,
    UploadStatus? uploadStatus,
  }) {
    return CapturedImage(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      capturedAt: capturedAt ?? this.capturedAt,
      batchId: batchId ?? this.batchId,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      width: width ?? this.width,
      height: height ?? this.height,
      deviceName: deviceName ?? this.deviceName,
      uploadStatus: uploadStatus ?? this.uploadStatus,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        filePath,
        capturedAt,
        batchId,
        thumbnailPath,
        width,
        height,
        deviceName,
        uploadStatus,
      ];
}

