import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Typed exception thrown by [FileUploader] when a Cloudinary Proxy request
/// returns a non-2xx HTTP status.
class CloudinaryException implements Exception {
  /// The HTTP status code returned by the Cloudinary Proxy.
  final int statusCode;

  /// The raw response body string returned by the Cloudinary Proxy.
  final String responseBody;

  const CloudinaryException(this.statusCode, this.responseBody);

  @override
  String toString() =>
      'CloudinaryException: HTTP $statusCode — $responseBody';
}

/// Encapsulates all media upload operations via the Cloudinary REST proxy.
///
/// All methods apply a 30-second timeout and throw [CloudinaryException] on
/// non-2xx responses.
class FileUploader {
  /// The base URL of the Cloudinary REST proxy.
  static const String _baseUrl =
      'https://media-upload-cloudinary-eight.vercel.app';

  /// The timeout applied to every HTTP request.
  static const Duration _timeout = Duration(seconds: 30);

  final Dio _dio;

  /// Creates a [FileUploader] backed by the given [Dio] instance.
  FileUploader(this._dio);

  /// Uploads a file to the Cloudinary Proxy via multipart POST to
  /// `/upload-media`.
  ///
  /// Returns a map containing at minimum the keys `url` and `public_id`.
  ///
  /// Throws [CloudinaryException] on non-2xx response.
  Future<Map<String, dynamic>> uploadFile(
      Uint8List bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
        ),
      });

      final response = await _dio
          .post(
            '$_baseUrl/upload-media',
            data: formData,
            options: Options(
              sendTimeout: _timeout,
              receiveTimeout: _timeout,
            ),
          )
          .timeout(_timeout);

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw CloudinaryException(
          response.statusCode ?? 0,
          response.data?.toString() ?? '',
        );
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        throw CloudinaryException(
          e.response!.statusCode ?? 0,
          e.response!.data?.toString() ?? '',
        );
      }
      rethrow;
    }
  }

  /// Updates an existing file on the Cloudinary Proxy via multipart PUT to
  /// `/update-media?public_id=...&type=...`.
  ///
  /// Returns a map containing at minimum the keys `url` and `public_id`.
  ///
  /// Throws [CloudinaryException] on non-2xx response.
  Future<Map<String, dynamic>> updateFile(
    Uint8List bytes,
    String publicId,
    String type,
    String filename,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
        ),
      });

      final response = await _dio
          .put(
            '$_baseUrl/update-media',
            data: formData,
            queryParameters: {
              'public_id': publicId,
              'type': type,
            },
            options: Options(
              sendTimeout: _timeout,
              receiveTimeout: _timeout,
            ),
          )
          .timeout(_timeout);

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw CloudinaryException(
          response.statusCode ?? 0,
          response.data?.toString() ?? '',
        );
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        throw CloudinaryException(
          e.response!.statusCode ?? 0,
          e.response!.data?.toString() ?? '',
        );
      }
      rethrow;
    }
  }

  /// Deletes a file from the Cloudinary Proxy via DELETE to
  /// `/delete-media?public_id=...&type=...`.
  ///
  /// Returns `true` on success.
  ///
  /// Throws [CloudinaryException] on non-2xx response.
  Future<bool> deleteFile(String publicId, String type) async {
    try {
      final response = await _dio
          .delete(
            '$_baseUrl/delete-media',
            queryParameters: {
              'public_id': publicId,
              'type': type,
            },
            options: Options(
              sendTimeout: _timeout,
              receiveTimeout: _timeout,
            ),
          )
          .timeout(_timeout);

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw CloudinaryException(
          response.statusCode ?? 0,
          response.data?.toString() ?? '',
        );
      }

      return true;
    } on DioException catch (e) {
      if (e.response != null) {
        throw CloudinaryException(
          e.response!.statusCode ?? 0,
          e.response!.data?.toString() ?? '',
        );
      }
      rethrow;
    }
  }
}
