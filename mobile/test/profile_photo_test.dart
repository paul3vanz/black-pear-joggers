import 'dart:typed_data';

import 'package:bpj/features/members/logic/profile_photo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A [w] x [h] JPEG whose top half is red and bottom half blue. [orientation]
/// is written as the EXIF orientation tag (1 = upright).
Uint8List _jpeg(int w, int h, {int? orientation}) {
  final image = img.Image(width: w, height: h);
  for (final p in image) {
    p
      ..r = p.y < h / 2 ? 255 : 0
      ..g = 0
      ..b = p.y < h / 2 ? 0 : 255;
  }
  if (orientation != null) image.exif.imageIfd.orientation = orientation;
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

img.Image _decode(Uint8List bytes) => img.decodeJpg(bytes)!;

/// Whether the JPEG contains an EXIF (APP1 "Exif") segment.
bool _hasExif(Uint8List bytes) => String.fromCharCodes(bytes).contains('Exif');

bool _isReddish(img.Pixel p) => p.r > 180 && p.b < 90;
bool _isBluish(img.Pixel p) => p.b > 180 && p.r < 90;

void main() {
  test('a landscape photo becomes a 512 px square JPEG', () {
    final out = processProfilePhoto(_jpeg(800, 400));
    // JPEG magic bytes.
    expect(out.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
    final result = _decode(out);
    expect(result.width, 512);
    expect(result.height, 512);
    // Centre crop keeps the top (red) and bottom (blue) halves.
    expect(_isReddish(result.getPixel(256, 100)), isTrue);
    expect(_isBluish(result.getPixel(256, 400)), isTrue);
  });

  test('a portrait photo becomes a 512 px square JPEG', () {
    final out = processProfilePhoto(_jpeg(400, 900));
    final result = _decode(out);
    expect([result.width, result.height], [512, 512]);
    expect(_isReddish(result.getPixel(256, 100)), isTrue);
    expect(_isBluish(result.getPixel(256, 400)), isTrue);
  });

  test('EXIF orientation is applied before cropping', () {
    // Orientation 6 = rotate 90 degrees clockwise to display: the red top of
    // the stored pixels ends up on the RIGHT, the blue bottom on the LEFT.
    final out = processProfilePhoto(_jpeg(400, 200, orientation: 6));
    final result = _decode(out);
    expect([result.width, result.height], [512, 512]);
    expect(_isReddish(result.getPixel(450, 256)), isTrue);
    expect(_isBluish(result.getPixel(60, 256)), isTrue);
  });

  test('the output carries no EXIF block (location data is stripped)', () {
    final input = _jpeg(300, 300, orientation: 6);
    expect(_hasExif(input), isTrue);
    final out = processProfilePhoto(input);
    expect(_hasExif(out), isFalse);
  });

  test('a small photo is upscaled to 512 px', () {
    final out = processProfilePhoto(_jpeg(100, 80));
    final result = _decode(out);
    expect([result.width, result.height], [512, 512]);
  });

  test('a photo under 64 px is rejected with a readable message', () {
    expect(
      () => processProfilePhoto(_jpeg(50, 200)),
      throwsA(
        isA<ProfilePhotoException>().having(
          (e) => e.message,
          'message',
          contains('too small'),
        ),
      ),
    );
  });

  test('something that is not an image is rejected', () {
    expect(
      () => processProfilePhoto(Uint8List.fromList([1, 2, 3, 4, 5])),
      throwsA(isA<ProfilePhotoException>()),
    );
    expect(
      () => processProfilePhoto(Uint8List(0)),
      throwsA(isA<ProfilePhotoException>()),
    );
  });

  test('a PNG input is accepted and comes out as JPEG', () {
    final png = Uint8List.fromList(
      img.encodePng(img.Image(width: 300, height: 300)),
    );
    final out = processProfilePhoto(png);
    expect(out.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
  });
}
