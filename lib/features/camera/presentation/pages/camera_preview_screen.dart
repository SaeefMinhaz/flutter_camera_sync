import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_camera_sync/features/camera/presentation/bloc/camera_bloc.dart';
import 'package:flutter_camera_sync/features/camera/presentation/bloc/camera_event.dart';
import 'package:flutter_camera_sync/features/camera/presentation/bloc/camera_state.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off camera initialization once the widget is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraBloc>().add(const CameraStarted());
    });
  }

  @override
  void dispose() {
    context.read<CameraBloc>().add(const CameraStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BlocBuilder<CameraBloc, CameraState>(
          builder: (BuildContext context, CameraState state) {
            if (state is CameraLoading || state is CameraInitial) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is CameraFailureState) {
              return _ErrorView(
                message: state.message,
                onRetry: () {
                  context.read<CameraBloc>().add(const CameraStarted());
                },
              );
            }

            if (state is CameraReady) {
              return _CameraReadyView(state: state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _CameraReadyView extends StatelessWidget {
  const _CameraReadyView({
    required this.state,
  });

  final CameraReady state;

  @override
  Widget build(BuildContext context) {
    final CameraController controller = state.controller;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (controller.value.isInitialized)
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          )
        else
          const Center(
            child: CircularProgressIndicator(),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (state.lastCapturedImagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Saved: ${state.lastCapturedImagePath}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                _CaptureButton(
                  isCapturing: state.isCapturing,
                  onPressed: () {
                    context
                        .read<CameraBloc>()
                        .add(const CameraCapturePressed());
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.isCapturing,
    required this.onPressed,
  });

  final bool isCapturing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color outerColor = Colors.white.withOpacity(0.8);
    final Color innerColor =
        isCapturing ? Colors.redAccent : Colors.white.withOpacity(0.95);

    return GestureDetector(
      onTap: isCapturing ? null : onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: outerColor, width: 4),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: isCapturing ? 44 : 56,
            height: isCapturing ? 44 : 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: innerColor,
            ),
          ),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
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

