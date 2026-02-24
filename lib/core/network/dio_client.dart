import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

/// Very small wrapper around Dio so that the rest of the code
/// does not need to know about headers, base URLs, etc.
///
/// You can change [baseUrl] and the endpoint path later when you
/// integrate with your real backend.
class DioClient {
  DioClient({
    Dio? dio,
    String baseUrl = 'https://example.com/api',
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

  final Dio _dio;

  /// Uploads a single image file.
  ///
  /// The concrete endpoint and form fields are placeholders.
  /// Replace `/uploads/images` and the map keys with whatever your
  /// backend expects once the API is ready.
  Future<Response<dynamic>> uploadImage({
    required String filePath,
    required String batchId,
  }) async {
    final String fileName = p.basename(filePath);

    final FormData formData = FormData.fromMap(<String, dynamic>{
      'batchId': batchId,
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    return _dio.post<dynamic>(
      '/uploads/images',
      data: formData,
    );
  }
}

