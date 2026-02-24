import 'package:connectivity_plus/connectivity_plus.dart';

/// Simple wrapper around `connectivity_plus` so that the rest of the
/// app does not depend on the plugin directly.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Returns true when there is any active network connection.
  Future<bool> hasNetworkConnection() async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    return results.any((ConnectivityResult r) => r != ConnectivityResult.none);
  }
}

