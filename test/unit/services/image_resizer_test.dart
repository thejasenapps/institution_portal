// test/unit/services/image_resizer_test.dart
//
// Unit tests for ImageResizer.
// Tests: image > 500px resized to 500px, image <= 500px unchanged,
//        invalid bytes throw InvalidImageException.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:institution_portal/services/image_resizer.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a minimal valid JPEG [Uint8List] with the given [width] and [height].
/// Uses the `image` package to generate a real image in memory.
Uint8List _createTestImage(int width, int height) {
  final image = img.Image(width: width, height: height);
  // Fill with a solid colour so the image is non-trivial
  img.fill(image, color: img.ColorRgb8(100, 150, 200));
  return Uint8List.fromList(img.encodeJpg(image));
}

void main() {
  late ImageResizer resizer;

  setUp(() {
    resizer = ImageResizer();
  });

  // -------------------------------------------------------------------------
  // Width > 500px → output width is 500px
  // -------------------------------------------------------------------------

  group('ImageResizer — image wider than 500px', () {
    test('800x600 image is resized to width 500', () async {
      final bytes = _createTestImage(800, 600);
      final result = await resizer.resizeAndEncode(bytes);

      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(500));
    });

    test('1920x1080 image is resized to width 500', () async {
      final bytes = _createTestImage(1920, 1080);
      final result = await resizer.resizeAndEncode(bytes);

      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(500));
    });

    test('501x400 image is resized to width 500', () async {
      final bytes = _createTestImage(501, 400);
      final result = await resizer.resizeAndEncode(bytes);

      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(500));
    });

    test('aspect ratio is preserved when resizing', () async {
      // 1000x500 → should become 500x250
      final bytes = _createTestImage(1000, 500);
      final result = await resizer.resizeAndEncode(bytes);

      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(500));
      // Height should be approximately 250 (aspect ratio preserved)
      expect(decoded.height, closeTo(250, 5));
    });
  });

  // -------------------------------------------------------------------------
  // Width <= 500px → output width unchanged
  // -------------------------------------------------------------------------

  group('ImageResizer — image 500px or narrower', () {
    test('exactly 500px wide image keeps width 500', () async {
      final bytes = _createTestImage(500, 300);
      final result = await resizer.resizeAndEncode(bytes);

      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(500));
    });

    test('400x300 image keeps width 400', () async {
      final bytes = _createTestImage(400, 300);
      final result = await resizer.resizeAndEncode(bytes);

      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(400));
    });

    test('100x100 image keeps width 100', () async {
      final bytes = _createTestImage(100, 100);
      final result = await resizer.resizeAndEncode(bytes);

      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(100));
    });

    test('1x1 image keeps width 1', () async {
      final bytes = _createTestImage(1, 1);
      final result = await resizer.resizeAndEncode(bytes);

      final decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(1));
    });
  });

  // -------------------------------------------------------------------------
  // Invalid bytes → throws InvalidImageException
  // -------------------------------------------------------------------------

  group('ImageResizer — invalid bytes', () {
    test('random non-image bytes throw InvalidImageException', () async {
      final invalidBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);

      expect(
        () => resizer.resizeAndEncode(invalidBytes),
        throwsA(isA<InvalidImageException>()),
      );
    });

    test('empty bytes throw InvalidImageException', () async {
      final emptyBytes = Uint8List(0);

      expect(
        () => resizer.resizeAndEncode(emptyBytes),
        throwsA(isA<InvalidImageException>()),
      );
    });

    test('truncated JPEG bytes throw InvalidImageException', () async {
      // Start of a JPEG header but truncated
      final truncatedJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

      expect(
        () => resizer.resizeAndEncode(truncatedJpeg),
        throwsA(isA<InvalidImageException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Output is always JPEG
  // -------------------------------------------------------------------------

  group('ImageResizer — output encoding', () {
    test('output bytes start with JPEG magic bytes (0xFF 0xD8)', () async {
      final bytes = _createTestImage(200, 200);
      final result = await resizer.resizeAndEncode(bytes);

      // JPEG files start with FF D8
      expect(result[0], equals(0xFF));
      expect(result[1], equals(0xD8));
    });
  });
}
