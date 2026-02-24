/// Response model for imgBB API upload.
/// See https://api.imgbb.com/
class ImgBbUploadResponse {
  const ImgBbUploadResponse({
    required this.success,
    this.data,
    this.status,
  });

  factory ImgBbUploadResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return ImgBbUploadResponse(
      success: json['success'] as bool? ?? false,
      status: json['status'] as int?,
      data: data != null ? ImgBbImageData.fromJson(data) : null,
    );
  }

  final bool success;
  final int? status;
  final ImgBbImageData? data;
}

class ImgBbImageData {
  const ImgBbImageData({
    this.url,
    this.displayUrl,
    this.deleteUrl,
    this.id,
    this.filename,
  });

  factory ImgBbImageData.fromJson(Map<String, dynamic> json) {
    return ImgBbImageData(
      id: json['id'] as String?,
      filename: json['filename'] as String?,
      url: json['url'] as String?,
      displayUrl: json['display_url'] as String?,
      deleteUrl: json['delete_url'] as String?,
    );
  }

  final String? id;
  final String? filename;
  final String? url;
  final String? displayUrl;
  final String? deleteUrl;
}
