import 'package:flutter_camera_sync/core/error/failure.dart';

/// Simple result wrapper used across repositories and use cases.
///
/// Instead of throwing exceptions, data and domain layers should return
/// a [Result] so that callers can handle success and failure explicitly.
class Result<T> {
  final T? value;
  final Failure? failure;

  const Result._({this.value, this.failure});

  bool get isSuccess => failure == null;

  bool get isFailure => failure != null;

  factory Result.success(T value) => Result<T>._(value: value);

  factory Result.failure(Failure failure) => Result<T>._(failure: failure);
}

