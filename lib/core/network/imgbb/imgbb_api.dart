import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'imgbb_models.dart';

/// Base URL for imgBB API (v1).
const String imgBbBaseUrl = 'https://api.imgbb.com/1';

/// imgBB API client: upload images via multipart/form-data using Dio.
///
/// Use the shared [DioClient.dio] so the same Dio instance can be used
/// for other API calls (logging, interceptors, timeouts applied globally).
class ImgBbApi {
  ImgBbApi({
    required Dio dio,
    required String apiKey,
    String baseUrl = imgBbBaseUrl,
  })  : _dio = dio,
        _apiKey = apiKey,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String _apiKey;
  final String _baseUrl;

  /// Uploads a single image file to imgBB using multipart/form-data.
  ///
  /// [filePath] must be a valid path to an image file on disk.
  /// Returns [ImgBbUploadResponse] on success; throws [DioException] on failure.
  Future<ImgBbUploadResponse> uploadImage(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw DioException(
        requestOptions: RequestOptions(path: filePath),
        type: DioExceptionType.badResponse,
        error: 'File not found: $filePath',
      );
    }

    final String fileName = p.basename(filePath);

    final FormData formData = FormData.fromMap(<String, dynamic>{
      'image': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
      if (fileName.isNotEmpty) 'name': fileName,
    });

    final String url = '$_baseUrl/upload';
    final Response<Map<String, dynamic>> response = await _dio.post<Map<String, dynamic>>(
      url,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        validateStatus: (int? status) => status != null && status < 500,
      ),
      queryParameters: <String, String>{
        'key': _apiKey,
      },
    );

    if (response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Empty response from imgBB',
      );
    }

    final ImgBbUploadResponse result = ImgBbUploadResponse.fromJson(response.data!);

    if (!result.success || response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'imgBB upload failed: ${response.statusCode}',
      );
    }

    return result;
  }
}
