import 'package:permission_handler/permission_handler.dart';

/// Central place for runtime permission checks.
///
/// For now we only deal with camera permission. More cases can be
/// added later without changing the UI or BLoC code.
class PermissionService {
  Future<bool> ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.camera.request();
    return result.isGranted;
  }
}

