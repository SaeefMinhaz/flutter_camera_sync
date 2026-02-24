import 'package:equatable/equatable.dart';

import 'upload_status.dart';

/// Group of photos that logically belong together.
///
/// For example, this might represent one inspection, one delivery,
/// or any other real-world session where the user takes multiple photos.
class CaptureBatch extends Equatable {
  final String id;
  final DateTime createdAt;
  final String? label;
  final UploadStatus status;

  const CaptureBatch({
    required this.id,
    required this.createdAt,
    this.label,
    this.status = UploadStatus.pending,
  });

  CaptureBatch copyWith({
    String? id,
    DateTime? createdAt,
    String? label,
    UploadStatus? status,
  }) {
    return CaptureBatch(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      label: label ?? this.label,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, createdAt, label, status];
}

