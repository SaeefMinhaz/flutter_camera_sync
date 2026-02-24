import 'package:permission_handler/permission_handler.dart';

/// Central place for runtime permission checks.
///
/// For now we only deal with camera permission. More cases can be
/// added later without changing the UI or BLoC code.
class PermissionService {
  Future<bool> ensureCameraPermission() async {
    final PermissionStatus status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    }

    final PermissionStatus result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Returns true when the user has permanently denied camera access.
  ///
  /// In that case the only way to recover is by opening system settings.
  Future<bool> isCameraPermanentlyDenied() async {
    final PermissionStatus status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }
}

