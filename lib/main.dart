import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_camera_sync/core/services/permission_service.dart';
import 'package:flutter_camera_sync/features/camera/data/data.dart';
import 'package:flutter_camera_sync/features/camera/domain/domain.dart';
import 'package:flutter_camera_sync/features/camera/presentation/presentation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final permissionService = PermissionService();
  final cameraDataSource = CameraDataSource();
  final cameraRepository = CameraRepositoryImpl(cameraDataSource);

  final getAvailableCameras = GetAvailableCameras(cameraRepository);
  final initializeCamera = InitializeCamera(cameraRepository);
  final disposeCamera = DisposeCamera(cameraRepository);
  final captureImage = CaptureImage(cameraRepository);

  runApp(
    MyApp(
      permissionService: permissionService,
      getAvailableCameras: getAvailableCameras,
      initializeCamera: initializeCamera,
      disposeCamera: disposeCamera,
      captureImage: captureImage,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.permissionService,
    required this.getAvailableCameras,
    required this.initializeCamera,
    required this.disposeCamera,
    required this.captureImage,
  });

  final PermissionService permissionService;
  final GetAvailableCameras getAvailableCameras;
  final InitializeCamera initializeCamera;
  final DisposeCamera disposeCamera;
  final CaptureImage captureImage;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => CameraBloc(
        permissionService: permissionService,
        getAvailableCameras: getAvailableCameras,
        initializeCamera: initializeCamera,
        disposeCamera: disposeCamera,
        captureImage: captureImage,
      ),
      child: MaterialApp(
        title: 'Camera Preview',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const CameraPreviewScreen(),
      ),
    );
  }
}

