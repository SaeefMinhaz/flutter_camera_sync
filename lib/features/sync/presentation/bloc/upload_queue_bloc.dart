import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_camera_sync/core/error/failure.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';
import 'package:flutter_camera_sync/features/sync/domain/domain.dart';

import 'upload_queue_event.dart';
import 'upload_queue_state.dart';

class UploadQueueBloc extends Bloc<UploadQueueEvent, UploadQueueState> {
  final GetPendingBatchesWithImages _getPendingBatchesWithImages;

  UploadQueueBloc({
    required GetPendingBatchesWithImages getPendingBatchesWithImages,
  })  : _getPendingBatchesWithImages = getPendingBatchesWithImages,
        super(const UploadQueueInitial()) {
    on<UploadQueueStarted>(_onLoad);
    on<UploadQueueRefreshed>(_onLoad);
  }

  Future<void> _onLoad(
    UploadQueueEvent event,
    Emitter<UploadQueueState> emit,
  ) async {
    emit(const UploadQueueLoading());

    final result = await _getPendingBatchesWithImages(const NoParams());
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

