import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Side of the square profile photo we upload (the server accepts 64-1024 px).
const profilePhotoSize = 512;

/// Smaller photos than this are rejected (the server's minimum side).
const profilePhotoMinSide = 64;

/// JPEG quality of the uploaded photo (about 40 KB at 512 px).
const profilePhotoQuality = 85;

/// The photo can't be used; [message] is safe to show to the member.
class ProfilePhotoException implements Exception {
  const ProfilePhotoException(this.message);

  final String message;

  @override
  String toString() => 'ProfilePhotoException($message)';
}

/// Turns whatever the picker returned into the JPEG we upload (D60): decodes it,
/// applies the EXIF rotation (so a portrait phone photo is upright), centre-crops
/// to a square, resizes to [profilePhotoSize] px and re-encodes as JPEG. Encoding
/// writes no EXIF block, so camera model and **location data are stripped**.
///
/// Throws [ProfilePhotoException] for something that is not a decodable image or
/// is smaller than [profilePhotoMinSide] px on its shorter side. Photos between
/// 64 and 512 px are upscaled (they stay blurry but valid), so the output is
/// always exactly 512 x 512.
///
/// Pure Dart and CPU heavy for a 12 MP photo: call it through `compute` (a
/// background isolate, like a Web Worker) from UI code.
Uint8List processProfilePhoto(Uint8List input) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(input);
  } on Object {
    throw const ProfilePhotoException(
      "That file couldn't be read as a photo. Try a JPEG or PNG.",
    );
  }
  if (decoded == null) {
    throw const ProfilePhotoException(
      "That file couldn't be read as a photo. Try a JPEG or PNG.",
    );
  }
  final upright = img.bakeOrientation(decoded);
  if (math.min(upright.width, upright.height) < profilePhotoMinSide) {
    throw const ProfilePhotoException(
      'That photo is too small. Pick one at least 64 pixels wide and tall.',
    );
  }
  final square = img.copyResizeCropSquare(
    upright,
    size: profilePhotoSize,
    interpolation: math.min(upright.width, upright.height) >= profilePhotoSize
        ? img.Interpolation.average
        : img.Interpolation.cubic,
  );
  return Uint8List.fromList(
    img.encodeJpg(square, quality: profilePhotoQuality),
  );
}
