import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:institution_portal/services/file_uploader.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mock classes
// ---------------------------------------------------------------------------

class MockDio extends Mock implements Dio {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a fake [Response] with the given status code and data.
Response<dynamic> _fakeResponse({
  required int statusCode,
  dynamic data,
  RequestOptions? requestOptions,
}) {
  return Response(
    requestOptions: requestOptions ?? RequestOptions(path: ''),
    statusCode: statusCode,
    data: data,
  );
}

/// Builds a [DioException] that carries a response with the given status code.
DioException _dioException({
  required int statusCode,
  String body = 'error body',
}) {
  final requestOptions = RequestOptions(path: '');
  return DioException(
    requestOptions: requestOptions,
    response: Response(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: body,
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  late MockDio mockDio;
  late FileUploader uploader;

  // Dummy bytes used across tests
  final dummyBytes = Uint8List.fromList([1, 2, 3, 4]);

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(FormData());
    registerFallbackValue(Options());
  });

  setUp(() {
    mockDio = MockDio();
    uploader = FileUploader(mockDio);
  });

  // -------------------------------------------------------------------------
  // uploadFile
  // -------------------------------------------------------------------------
  group('FileUploader.uploadFile', () {
    test('returns response map on 200 response', () async {
      final responseData = {'url': 'https://cdn.example.com/img.jpg', 'public_id': 'abc123'};

      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => _fakeResponse(
            statusCode: 200,
            data: responseData,
          ));

      final result = await uploader.uploadFile(dummyBytes, 'test.jpg');

      expect(result['url'], equals('https://cdn.example.com/img.jpg'));
      expect(result['public_id'], equals('abc123'));
    });

    test('throws CloudinaryException on 500 response via DioException', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(_dioException(statusCode: 500, body: 'Internal Server Error'));

      expect(
        () => uploader.uploadFile(dummyBytes, 'test.jpg'),
        throwsA(
          isA<CloudinaryException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.responseBody, 'responseBody', 'Internal Server Error'),
        ),
      );
    });

    test('throws CloudinaryException on non-2xx status in response body', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => _fakeResponse(
            statusCode: 400,
            data: 'Bad Request',
          ));

      expect(
        () => uploader.uploadFile(dummyBytes, 'test.jpg'),
        throwsA(
          isA<CloudinaryException>()
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });
  });

  // -------------------------------------------------------------------------
  // updateFile
  // -------------------------------------------------------------------------
  group('FileUploader.updateFile', () {
    test('returns response map on success (200)', () async {
      final responseData = {'url': 'https://cdn.example.com/updated.jpg', 'public_id': 'pub-456'};

      when(() => mockDio.put(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => _fakeResponse(
            statusCode: 200,
            data: responseData,
          ));

      final result = await uploader.updateFile(dummyBytes, 'pub-456', 'image', 'updated.jpg');

      expect(result['url'], equals('https://cdn.example.com/updated.jpg'));
      expect(result['public_id'], equals('pub-456'));
    });

    test('throws CloudinaryException on non-2xx via DioException', () async {
      when(() => mockDio.put(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(_dioException(statusCode: 422, body: 'Unprocessable Entity'));

      expect(
        () => uploader.updateFile(dummyBytes, 'pub-456', 'image', 'updated.jpg'),
        throwsA(
          isA<CloudinaryException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.responseBody, 'responseBody', 'Unprocessable Entity'),
        ),
      );
    });

    test('throws CloudinaryException on non-2xx status in response', () async {
      when(() => mockDio.put(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => _fakeResponse(
            statusCode: 403,
            data: 'Forbidden',
          ));

      expect(
        () => uploader.updateFile(dummyBytes, 'pub-456', 'image', 'updated.jpg'),
        throwsA(isA<CloudinaryException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // deleteFile
  // -------------------------------------------------------------------------
  group('FileUploader.deleteFile', () {
    test('returns true on 200 success', () async {
      when(() => mockDio.delete(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => _fakeResponse(
            statusCode: 200,
            data: {'result': 'ok'},
          ));

      final result = await uploader.deleteFile('pub-789', 'image');

      expect(result, isTrue);
    });

    test('throws CloudinaryException on non-2xx via DioException', () async {
      when(() => mockDio.delete(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(_dioException(statusCode: 404, body: 'Not Found'));

      expect(
        () => uploader.deleteFile('pub-789', 'image'),
        throwsA(
          isA<CloudinaryException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.responseBody, 'responseBody', 'Not Found'),
        ),
      );
    });

    test('throws CloudinaryException on non-2xx status in response', () async {
      when(() => mockDio.delete(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => _fakeResponse(
            statusCode: 500,
            data: 'Server Error',
          ));

      expect(
        () => uploader.deleteFile('pub-789', 'image'),
        throwsA(isA<CloudinaryException>()),
      );
    });
  });
}
