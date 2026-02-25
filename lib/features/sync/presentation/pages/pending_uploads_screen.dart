import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/capture_batch.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/captured_image.dart';
import 'package:flutter_camera_sync/features/camera/domain/entities/upload_status.dart';
import 'package:flutter_camera_sync/features/sync/domain/entities/batch_with_images.dart';
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
        title: const Text('Batches'),
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
                  final batchWithImages = state.batches[index];
                  return _BatchTile(batchWithImages: batchWithImages);
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
    required this.batchWithImages,
  });

  final BatchWithImages batchWithImages;

  @override
  Widget build(BuildContext context) {
    final CaptureBatch batch = batchWithImages.batch;
    final List<CapturedImage> images = batchWithImages.images;
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
      leading: _leadingThumbnail(images),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Created $createdText'),
          if (images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: images
                    .take(3)
                    .map(
                      (CapturedImage image) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _ImageThumbnail(
                          path: image.thumbnailPath ?? image.filePath,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _statusLabel(batch.status),
            style: theme.textTheme.bodySmall,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete batch',
            onPressed: () async {
              final bool? confirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete batch'),
                    content: Text(
                      'Delete this batch and all its images?\n\n$title',
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirmed == true) {
                context
                    .read<UploadQueueBloc>()
                    .add(UploadQueueBatchDeleted(batch.id));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _leadingThumbnail(List<CapturedImage> images) {
    if (images.isEmpty) {
      return const Icon(Icons.photo_library_outlined);
    }
    return _ImageThumbnail(
      path: images.first.thumbnailPath ?? images.first.filePath,
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

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    required this.path,
  });

  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.file(
        File(path),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return Container(
            width: 40,
            height: 40,
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.broken_image_outlined,
              size: 18,
              color: Colors.black45,
            ),
          );
        },
      ),
    );
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

