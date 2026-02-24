import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'package:flutter_camera_sync/core/db/app_database.dart';
import 'package:flutter_camera_sync/core/network/dio_client.dart';
import 'package:flutter_camera_sync/core/network/imgbb/imgbb_api.dart';
import 'package:flutter_camera_sync/core/network/imgbb/imgbb_config.dart';
import 'package:flutter_camera_sync/core/services/connectivity_service.dart';
import 'package:flutter_camera_sync/core/usecase/use_case.dart';
import 'package:flutter_camera_sync/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:flutter_camera_sync/features/sync/domain/usecases/sync_pending_batches.dart';

const String syncTaskName = 'syncPendingTask';

/// Entry point used by Workmanager on a background isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    final connectivity = ConnectivityService();
    final hasConnection = await connectivity.hasNetworkConnection();

    if (!hasConnection) {
      // No network available, keep the queue as-is and let Workmanager
      // schedule another attempt later.
      return Future.value(true);
    }

    final db = AppDatabase();
    final dioClient = DioClient();
    final imgBbApi = ImgBbApi(
      dio: dioClient.dio,
      apiKey: kImgBbApiKey,
    );
    final repository = SyncRepositoryImpl(db, imgBbApi);
    final syncUseCase = SyncPendingBatches(repository);

    await syncUseCase(const NoParams());

    // We always report success here because individual upload failures
    // are tracked via local status flags rather than by failing the task.
    return Future.value(true);
  });
}

