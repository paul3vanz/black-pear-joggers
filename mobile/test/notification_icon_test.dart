import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../tool/make_notification_icon.dart';

/// A w x h mask with the given filled rectangles (x0, y0, x1, y1 inclusive).
Uint8List maskWith(int w, int h, List<(int, int, int, int)> rects) {
  final m = Uint8List(w * h);
  for (final (x0, y0, x1, y1) in rects) {
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        m[y * w + x] = 255;
      }
    }
  }
  return m;
}

void main() {
  group('labelComponents', () {
    test('finds separate blobs with sizes and boxes', () {
      final m = maskWith(20, 20, [(1, 1, 3, 2), (10, 10, 14, 14)]);
      final l = labelComponents(m, 20, 20);
      expect(l.blobs, hasLength(2));
      expect([for (final b in l.blobs) b.size], [6, 25]);
      final big = l.blobs[1];
      expect([big.minX, big.minY, big.maxX, big.maxY], [10, 10, 14, 14]);
      expect(l.labels[1 * 20 + 1], 1);
      expect(l.labels[0], 0);
    });

    test('a diagonal line is one blob (8-connected)', () {
      final m = Uint8List(100);
      for (var i = 0; i < 10; i++) {
        m[i * 10 + i] = 255;
      }
      expect(labelComponents(m, 10, 10).blobs, hasLength(1));
    });

    test('an empty mask has no blobs', () {
      expect(labelComponents(Uint8List(16), 4, 4).blobs, isEmpty);
    });

    test('a long snaking blob does not overflow the stack', () {
      final m = Uint8List(1000 * 1000)..fillRange(0, 1000 * 1000, 255);
      final l = labelComponents(m, 1000, 1000);
      expect(l.blobs.single.size, 1000 * 1000);
    });
  });

  group('pickOutline', () {
    // 100 x 100: the "square background" touches the corners, a ring-like
    // blob has its box out to the edges, a big shape is near the centre and
    // a small speck is near the centre too.
    test('is the biggest blob inside the radius', () {
      final m = maskWith(100, 100, [
        (0, 0, 99, 2), // background strip: box reaches the corners
        (46, 46, 49, 49), // speck
        (30, 30, 60, 60), // the pear stand-in
      ]);
      final l = labelComponents(m, 100, 100);
      final pick = pickOutline(l.blobs, 100, 100, maxRadius: 50)!;
      expect([pick.minX, pick.maxX], [30, 60]);
    });

    test('ignores a bigger blob that reaches beyond the radius', () {
      final m = maskWith(100, 100, [
        (0, 0, 99, 20), // huge, but its corners are ~70 px out
        (45, 45, 55, 55),
      ]);
      final l = labelComponents(m, 100, 100);
      final pick = pickOutline(l.blobs, 100, 100, maxRadius: 50)!;
      expect(pick.size, 121);
    });

    test('null when nothing qualifies', () {
      final m = maskWith(100, 100, [(0, 0, 99, 99)]);
      final l = labelComponents(m, 100, 100);
      expect(pickOutline(l.blobs, 100, 100, maxRadius: 50), isNull);
    });
  });

  group('dilate', () {
    test('one pixel becomes a disc of the radius', () {
      final m = maskWith(21, 21, [(10, 10, 10, 10)]);
      final d = dilate(m, 21, 21, 5);
      expect(d[10 * 21 + 15], 255); // 5 right
      expect(d[10 * 21 + 16], 0);
      expect(d[5 * 21 + 10], 255); // 5 up
      expect(d[4 * 21 + 10], 0);
      expect(d[6 * 21 + 6], 0); // diagonal corner of the box is outside
      expect(d[8 * 21 + 8], 255);
    });

    test('stays inside the bitmap at the edges', () {
      final d = dilate(maskWith(10, 10, [(0, 0, 0, 0)]), 10, 10, 3);
      expect(d[0], 255);
      expect(d[3], 255);
      expect(d.length, 100);
    });
  });

  group('squareCrop and areaDownscale', () {
    test('centres the box on a square canvas with ~12% padding', () {
      final m = maskWith(100, 100, [(10, 20, 59, 29)]); // 50 x 10
      final c = squareCrop(m, 100, 100);
      expect(c.side, (50 / 0.76).ceil());
      // Horizontally the box spans the canvas minus the padding...
      var minX = c.side, maxX = 0, minY = c.side, maxY = 0;
      for (var y = 0; y < c.side; y++) {
        for (var x = 0; x < c.side; x++) {
          if (c.pixels[y * c.side + x] == 0) continue;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
      expect(maxX - minX + 1, 50);
      expect(minX, closeTo(c.side - 1 - maxX, 1)); // centred left-right
      expect(minY, closeTo(c.side - 1 - maxY, 1)); // and top-bottom
      expect(minX / c.side, closeTo(0.12, 0.02));
    });

    test('an empty mask gives a blank canvas', () {
      final c = squareCrop(Uint8List(25), 5, 5);
      expect(c.pixels.every((v) => v == 0), isTrue);
    });

    test('averages areas, so edges become partial coverage', () {
      // 4x4 source, left half set: 2x2 output is 255 | 0 per row.
      final src = maskWith(4, 4, [(0, 0, 1, 3)]);
      expect(areaDownscale(src, 4, 2), [255, 0, 255, 0]);
      // 3 -> 2 splits pixels: the middle source column counts half each side.
      final third = maskWith(3, 3, [(0, 0, 0, 2)]);
      final out = areaDownscale(third, 3, 2);
      expect(out[0], closeTo(255 * 2 / 3, 1));
      expect(out[1], 0);
    });
  });

  test('whiteWithAlpha makes pure white with the coverage as alpha', () {
    final image = whiteWithAlpha(Uint8List.fromList([0, 128, 255, 40]), 2);
    final p = image.getPixel(1, 0);
    expect([p.r, p.g, p.b, p.a], [255, 255, 255, 128]);
    expect(image.getPixel(0, 0).a, 0);
  });

  group('the committed icons', () {
    const res = 'android/app/src/main/res';

    test('are pure white with a shape in the alpha, at the right sizes', () {
      const sizes = {
        'drawable-mdpi': 24,
        'drawable-hdpi': 36,
        'drawable-xhdpi': 48,
        'drawable-xxhdpi': 72,
        'drawable-xxxhdpi': 96,
      };
      for (final e in sizes.entries) {
        final file = File('$res/${e.key}/ic_stat_bpj.png');
        expect(file.existsSync(), isTrue, reason: '${file.path} exists');
        final image = img.decodePng(file.readAsBytesSync())!;
        expect([image.width, image.height], [e.value, e.value]);
        var opaque = 0;
        var clear = 0;
        for (final p in image) {
          if (p.a > 0) {
            // No coloured pixels: white wherever there is any coverage.
            expect([p.r, p.g, p.b], [255, 255, 255]);
          }
          if (p.a == 255) opaque++;
          if (p.a == 0) clear++;
        }
        expect(opaque, greaterThan(e.value), reason: 'has a shape');
        expect(clear, greaterThan(e.value * e.value ~/ 3), reason: 'has room');
        // The border is empty (padding), so nothing is clipped.
        for (var i = 0; i < e.value; i++) {
          expect(image.getPixel(i, 0).a, 0);
          expect(image.getPixel(0, i).a, 0);
        }
      }
    });

    test('the large icon is the round logo with transparent corners', () {
      final image = img.decodePng(
        File('$res/drawable-xxhdpi/ic_notification_large.png')
            .readAsBytesSync(),
      )!;
      expect([image.width, image.height], [192, 192]);
      expect(image.getPixel(0, 0).a, 0);
      expect(image.getPixel(191, 191).a, 0);
      expect(image.getPixel(96, 96).a, 255);
    });
  });
}
