import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_camera_sync/background/sync_worker.dart';
import 'package:flutter_camera_sync/core/db/app_database.dart';
import 'package:flutter_camera_sync/core/services/permission_service.dart';
import 'package:flutter_camera_sync/core/storage/local_file_storage.dart';
import 'package:flutter_camera_sync/core/network/dio_client.dart';
import 'package:flutter_camera_sync/core/network/imgbb/imgbb_api.dart';
import 'package:flutter_camera_sync/core/network/imgbb/imgbb_config.dart';
import 'package:flutter_camera_sync/features/camera/data/data.dart';
import 'package:flutter_camera_sync/features/camera/domain/domain.dart';
import 'package:flutter_camera_sync/features/camera/presentation/presentation.dart';
import 'package:flutter_camera_sync/features/sync/data/data.dart';
import 'package:flutter_camera_sync/features/sync/domain/domain.dart';
import 'package:flutter_camera_sync/features/sync/presentation/presentation.dart';
import 'package:flutter_camera_sync/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Background sync worker: register a periodic task that will try to
  // upload pending images whenever the device has a network connection.
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  await Workmanager().registerPeriodicTask(
    'sync-pending-task',
    syncTaskName,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  final permissionService = PermissionService();
  final cameraDataSource = CameraDataSource();
  final cameraRepository = CameraRepositoryImpl(cameraDataSource);
  final fileStorage = LocalFileStorage();

  final db = AppDatabase();
  final batchRepository = BatchRepositoryImpl(db);
  final dioClient = DioClient();
  final imgBbApi = ImgBbApi(
    dio: dioClient.dio,
    apiKey: kImgBbApiKey,
  );
  final syncRepository = SyncRepositoryImpl(db, imgBbApi);

  final getAvailableCameras = GetAvailableCameras(cameraRepository);
  final initializeCamera = InitializeCamera(cameraRepository);
  final disposeCamera = DisposeCamera(cameraRepository);
  final captureImage = CaptureImage(cameraRepository);
  final changeZoom = ChangeZoom(cameraRepository);
  final setFocusPoint = SetFocusPoint(cameraRepository);
  final createBatch = CreateBatch(batchRepository);
  final addImageToBatch = AddImageToBatch(batchRepository);
  final getAllBatchesWithImages =
      GetAllBatchesWithImages(batchRepository);
  final deleteBatch = DeleteBatch(batchRepository);
  final syncPendingBatches = SyncPendingBatches(syncRepository);

  runApp(
    MyApp(
      permissionService: permissionService,
      getAvailableCameras: getAvailableCameras,
      initializeCamera: initializeCamera,
      disposeCamera: disposeCamera,
      captureImage: captureImage,
      changeZoom: changeZoom,
      setFocusPoint: setFocusPoint,
      createBatch: createBatch,
      addImageToBatch: addImageToBatch,
      getAllBatchesWithImages: getAllBatchesWithImages,
      deleteBatch: deleteBatch,
      fileStorage: fileStorage,
      syncPendingBatches: syncPendingBatches,
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
    required this.changeZoom,
    required this.setFocusPoint,
    required this.createBatch,
    required this.addImageToBatch,
    required this.getAllBatchesWithImages,
    required this.deleteBatch,
    required this.fileStorage,
    required this.syncPendingBatches,
  });

  final PermissionService permissionService;
  final GetAvailableCameras getAvailableCameras;
  final InitializeCamera initializeCamera;
  final DisposeCamera disposeCamera;
  final CaptureImage captureImage;
  final ChangeZoom changeZoom;
  final SetFocusPoint setFocusPoint;
  final CreateBatch createBatch;
  final AddImageToBatch addImageToBatch;
  final GetAllBatchesWithImages getAllBatchesWithImages;
  final DeleteBatch deleteBatch;
  final LocalFileStorage fileStorage;
  final SyncPendingBatches syncPendingBatches;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<CameraBloc>(
          create: (BuildContext context) => CameraBloc(
            permissionService: permissionService,
            getAvailableCameras: getAvailableCameras,
            initializeCamera: initializeCamera,
            disposeCamera: disposeCamera,
            captureImage: captureImage,
            changeZoom: changeZoom,
            setFocusPoint: setFocusPoint,
            createBatch: createBatch,
            addImageToBatch: addImageToBatch,
            fileStorage: fileStorage,
            syncPendingBatches: syncPendingBatches,
          ),
        ),
        BlocProvider<UploadQueueBloc>(
          create: (BuildContext context) => UploadQueueBloc(
            getAllBatchesWithImages: getAllBatchesWithImages,
            deleteBatch: deleteBatch,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Camera & Uploads',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const RootShell(),
      ),
    );
  }
}

