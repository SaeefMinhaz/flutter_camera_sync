import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraBloc>().add(const CameraStarted());
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    context.read<CameraBloc>().add(const CameraStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<CameraBloc, CameraState>(
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
    );
  }
}

class _CameraReadyView extends StatefulWidget {
  const _CameraReadyView({
    required this.state,
  });

  final CameraReady state;

  @override
  State<_CameraReadyView> createState() => _CameraReadyViewState();
}

class _CameraReadyViewState extends State<_CameraReadyView> {
  double _baseZoom = 1.0;

  @override
  void didUpdateWidget(covariant _CameraReadyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentZoom != widget.state.currentZoom) {
      _baseZoom = widget.state.currentZoom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = state.controller;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        Widget preview;
        if (controller.value.isInitialized) {
          final previewSize = controller.value.previewSize;
          final double previewWidth =
              previewSize != null ? previewSize.height : width;
          final double previewHeight =
              previewSize != null ? previewSize.width : height;

          preview = FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: previewWidth,
              height: previewHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (ScaleStartDetails details) {
                  _baseZoom = state.currentZoom;
                },
                onScaleUpdate: (ScaleUpdateDetails details) {
                  if (!state.isZoomSupported) {
                    return;
                  }
                  final double targetZoom =
                      (_baseZoom * details.scale).clamp(
                    state.minZoom,
                    state.maxZoom,
                  );
                  context
                      .read<CameraBloc>()
                      .add(CameraZoomChanged(targetZoom));
                },
                onTapDown: (TapDownDetails details) {
                  if (!state.isFocusSupported) {
                    return;
                  }
                  final RenderBox? box =
                      context.findRenderObject() as RenderBox?;
                  if (box == null) {
                    return;
                  }
                  final localPosition =
                      box.globalToLocal(details.globalPosition);
                  final double normalizedX =
                      (localPosition.dx / box.size.width).clamp(0.0, 1.0);
                  final double normalizedY =
                      (localPosition.dy / box.size.height).clamp(0.0, 1.0);
                  context.read<CameraBloc>().add(
                        CameraFocusRequested(
                          x: normalizedX,
                          y: normalizedY,
                        ),
                      );
                },
                child: CameraPreview(controller),
              ),
            ),
          );
        } else {
          preview = const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            preview,
            if (state.focusPoint != null)
              Positioned(
                left: state.focusPoint!.dx * width - 24,
                top: state.focusPoint!.dy * height - 24,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.9),
                      width: 2,
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (state.isZoomSupported &&
                          (state.maxZoom - state.minZoom) > 0.1)
                        Column(
                          children: <Widget>[
                            Slider(
                              value: state.currentZoom.clamp(
                                state.minZoom,
                                state.maxZoom,
                              ),
                              min: state.minZoom,
                              max: state.maxZoom,
                              onChanged: (double value) {
                                context
                                    .read<CameraBloc>()
                                    .add(CameraZoomChanged(value));
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _buildZoomPresets(state, context),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      if (state.lastCapturedImagePath != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildZoomPresets(
    CameraReady state,
    BuildContext context,
  ) {
    final List<double> presets = <double>[
      0.5,
      1.0,
      2.0,
      3.0,
    ].where((double value) => value >= state.minZoom && value <= state.maxZoom)
        .toList();

    return presets
        .map(
          (double value) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: state.currentZoom == value
                    ? Colors.white
                    : Colors.white.withOpacity(0.15),
                foregroundColor:
                    state.currentZoom == value ? Colors.black : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () {
                context.read<CameraBloc>().add(CameraZoomChanged(value));
              },
              child: Text('${value.toStringAsFixed(1)}x'),
            ),
          ),
        )
        .toList();
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

