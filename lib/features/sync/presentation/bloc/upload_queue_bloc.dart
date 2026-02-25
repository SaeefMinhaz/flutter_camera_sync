import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_camera_sync/core/error/failure.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';
import 'package:flutter_camera_sync/features/sync/domain/domain.dart';

import 'upload_queue_event.dart';
import 'upload_queue_state.dart';

class UploadQueueBloc extends Bloc<UploadQueueEvent, UploadQueueState> {
  final GetAllBatchesWithImages _getAllBatchesWithImages;
  final DeleteBatch _deleteBatch;

  UploadQueueBloc({
    required GetAllBatchesWithImages getAllBatchesWithImages,
    required DeleteBatch deleteBatch,
  })  : _getAllBatchesWithImages = getAllBatchesWithImages,
        _deleteBatch = deleteBatch,
        super(const UploadQueueInitial()) {
    on<UploadQueueStarted>(_onLoad);
    on<UploadQueueRefreshed>(_onLoad);
    on<UploadQueueBatchDeleted>(_onBatchDeleted);
  }

  Future<void> _onLoad(
    UploadQueueEvent event,
    Emitter<UploadQueueState> emit,
  ) async {
    emit(const UploadQueueLoading());

    final result = await _getAllBatchesWithImages(const NoParams());
    if (result.isFailure || result.value == null) {
      final failure = result.failure;
      emit(
        UploadQueueFailureState(
          _friendlyMessage(
            failure,
            fallback: 'Could not load pending uploads.',
          ),
        ),
      );
      return;
    }

    final batches = result.value!;
    if (batches.isEmpty) {
      emit(const UploadQueueEmpty());
    } else {
      emit(UploadQueueLoaded(batches));
    }
  }

  Future<void> _onBatchDeleted(
    UploadQueueBatchDeleted event,
    Emitter<UploadQueueState> emit,
  ) async {
    // Perform delete; we ignore failure here and just reload.
    await _deleteBatch(event.batchId);

    // Reload the list after deletion.
    await _onLoad(const UploadQueueRefreshed(), emit);
  }

  String _friendlyMessage(Failure? failure, {required String fallback}) {
    if (failure == null) {
      return fallback;
    }
    if (failure.message.isEmpty) {
      return fallback;
    }
    return failure.message;
  }
}

