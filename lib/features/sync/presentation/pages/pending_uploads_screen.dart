import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/capture_batch.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/upload_status.dart';
import 'package:flutter_camera_sync/features/sync/presentation/bloc/upload_queue_bloc.dart';
import 'package:flutter_camera_sync/features/sync/presentation/bloc/upload_queue_event.dart';
import 'package:flutter_camera_sync/features/sync/presentation/bloc/upload_queue_state.dart';

class PendingUploadsScreen extends StatefulWidget {
  const PendingUploadsScreen({super.key});

  @override
  State<PendingUploadsScreen> createState() => _PendingUploadsScreenState();
}

class _PendingUploadsScreenState extends State<PendingUploadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UploadQueueBloc>().add(const UploadQueueStarted());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Uploads'),
      ),
      body: BlocBuilder<UploadQueueBloc, UploadQueueState>(
        builder: (BuildContext context, UploadQueueState state) {
          if (state is UploadQueueLoading || state is UploadQueueInitial) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is UploadQueueFailureState) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                context
                    .read<UploadQueueBloc>()
                    .add(const UploadQueueRefreshed());
              },
            );
          }

          if (state is UploadQueueEmpty) {
            return const _EmptyView();
          }

          if (state is UploadQueueLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<UploadQueueBloc>()
                    .add(const UploadQueueRefreshed());
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.batches.length,
                itemBuilder: (BuildContext context, int index) {
                  final batch = state.batches[index];
                  return _BatchTile(batch: batch);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  const _BatchTile({
    required this.batch,
  });

  final CaptureBatch batch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = batch.createdAt;
    final createdText =
        '${createdAt.year.toString().padLeft(4, '0')}-'
        '${createdAt.month.toString().padLeft(2, '0')}-'
        '${createdAt.day.toString().padLeft(2, '0')} '
        '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';

    final title = batch.label?.isNotEmpty == true
        ? batch.label!
        : 'Batch ${batch.id.substring(batch.id.length - 4)}';

    return ListTile(
      leading: const Icon(Icons.photo_library_outlined),
      title: Text(title),
      subtitle: Text('Created $createdText'),
      trailing: Text(
        _statusLabel(batch.status),
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  String _statusLabel(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return 'Waiting for upload';
      case UploadStatus.uploading:
        return 'Uploading';
      case UploadStatus.uploaded:
        return 'Uploaded';
      case UploadStatus.failed:
        return 'Upload failed';
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No pending uploads yet.\n'
          'Photos you take will appear here until they are uploaded.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

