import 'package:equatable/equatable.dart';

/// Base class for errors that bubble up to the domain layer.
///
/// The goal is to keep failures simple and human-readable so that
/// UI layers can show friendly messages without exposing low-level details.
abstract class Failure extends Equatable {
  final String message;
  final Object? cause;

  const Failure(this.message, {this.cause});

  @override
  List<Object?> get props => <Object?>[message, cause];
}

class CameraFailure extends Failure {
  const CameraFailure(String message, {Object? cause})
      : super(message, cause: cause);
}

class StorageFailure extends Failure {
  const StorageFailure(String message, {Object? cause})
      : super(message, cause: cause);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message, {Object? cause})
      : super(message, cause: cause);
}

class PermissionFailure extends Failure {
  const PermissionFailure(String message, {Object? cause})
      : super(message, cause: cause);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(String message, {Object? cause})
      : super(message, cause: cause);
}

