import 'package:equatable/equatable.dart';
import 'package:flutter_camera_sync/features/sync/domain/entities/batch_with_images.dart';

abstract class UploadQueueState extends Equatable {
  const UploadQueueState();

  @override
  List<Object?> get props => <Object?>[];
}

class UploadQueueInitial extends UploadQueueState {
  const UploadQueueInitial();
}

class UploadQueueLoading extends UploadQueueState {
  const UploadQueueLoading();
}

class UploadQueueEmpty extends UploadQueueState {
  const UploadQueueEmpty();
}

class UploadQueueFailureState extends UploadQueueState {
  final String message;

  const UploadQueueFailureState(this.message);

  @override
  List<Object?> get props => <Object?>[message];
}

class UploadQueueLoaded extends UploadQueueState {
  final List<BatchWithImages> batches;

  const UploadQueueLoaded(this.batches);

  @override
  List<Object?> get props => <Object?>[batches];
}

