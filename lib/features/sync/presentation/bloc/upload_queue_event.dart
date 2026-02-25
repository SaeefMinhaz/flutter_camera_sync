import 'package:equatable/equatable.dart';

abstract class UploadQueueEvent extends Equatable {
  const UploadQueueEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class UploadQueueStarted extends UploadQueueEvent {
  const UploadQueueStarted();
}

class UploadQueueRefreshed extends UploadQueueEvent {
  const UploadQueueRefreshed();
}

class UploadQueueBatchDeleted extends UploadQueueEvent {
  final String batchId;

  const UploadQueueBatchDeleted(this.batchId);

  @override
  List<Object?> get props => <Object?>[batchId];
}

