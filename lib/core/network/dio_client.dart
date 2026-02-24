import 'package:dio/dio.dart';

/// Reusable Dio-based HTTP client for all API calls.
///
/// Use [dio] for low-level requests, or add convenience methods here.
/// Configure [baseUrl] when all calls target the same host; otherwise
/// use full URLs in requests.
class DioClient {
  DioClient({
    Dio? dio,
    String baseUrl = '',
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: connectTimeout ?? const Duration(seconds: 30),
                receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
              ),
            );

  final Dio _dio;

  /// Exposes the underlying [Dio] instance so API layers (e.g. ImgBB, other
  /// backends) can perform requests with full control over URL, headers, and body.
  Dio get dio => _dio;
}
