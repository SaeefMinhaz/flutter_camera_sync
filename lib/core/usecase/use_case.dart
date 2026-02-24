import 'package:flutter_camera_sync/core/result/result.dart';

/// Base class for all use cases.
///
/// Use cases sit in the domain layer and express one meaningful action,
/// such as "initialize camera" or "sync pending batches".
abstract class UseCase<T, P> {
  Future<Result<T>> call(P params);
}

/// Marker type for use cases that do not need input parameters.
class NoParams {
  const NoParams();
}

