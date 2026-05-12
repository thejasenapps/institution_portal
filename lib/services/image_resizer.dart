import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Typed exception thrown by [ImageResizer] when the provided bytes cannot be
/// decoded as a valid image.
class InvalidImageException implements Exception {
  /// A human-readable description of why the image could not be decoded.
  final String message;

  const InvalidImageException(this.message);

  @override
  String toString() => 'InvalidImageException: $message';
}

/// Utility that resizes an image to a maximum width of 500 px and encodes it
/// as JPEG before upload.
class ImageResizer {
  /// The maximum width (in pixels) that the output image may have.
  static const int _maxWidth = 500;

  /// The JPEG quality used when encoding the output image.
  static const int _jpegQuality = 85;

  /// Decodes [bytes] as an image, resizes it to [_maxWidth] px width if its
  /// current width exceeds [_maxWidth] (preserving aspect ratio), and encodes
  /// the result as JPEG at quality [_jpegQuality].
  ///
  /// Throws [InvalidImageException] if [bytes] cannot be decoded as a valid
  /// image.
  Future<Uint8List> resizeAndEncode(Uint8List bytes) async {
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw const InvalidImageException(
        'The provided bytes could not be decoded as a valid image.',
      );
    }

    final img.Image output;

    if (image.width > _maxWidth) {
      output = img.copyResize(
        image,
        width: _maxWidth,
        interpolation: img.Interpolation.linear,
      );
    } else {
      output = image;
    }

    final encoded = img.encodeJpg(output, quality: _jpegQuality);
    return Uint8List.fromList(encoded);
  }
}
