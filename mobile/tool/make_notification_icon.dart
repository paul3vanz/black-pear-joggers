// Builds the Android notification icons from the club logo (D112).
//
//   dart run tool/make_notification_icon.dart [--preview <dir>]
//
// Run it from `mobile/`. It reads assets/images/logo.png (a round black logo
// with a white pear outline, ring and lettering on a white square) and writes:
//
//  * android/app/src/main/res/drawable-{mdpi..xxxhdpi}/ic_stat_bpj.png: the
//    small status-bar icon. Android draws it as a silhouette from the alpha
//    channel only, so it is pure white with the shape as alpha (24, 36, 48, 72
//    and 96 px).
//  * android/app/src/main/res/drawable-xxhdpi/ic_notification_large.png: the
//    round logo (corners transparent) at 192 px, for the large icon.
//
// How the pear is found: threshold the logo (luminance > 128 = white), label the
// connected white blobs, and keep the biggest one that sits inside the disc
// (not the white square or the outer ring) and is not lettering. That is the
// pear + leaf + stem outline. It is then thickened so the thin line survives
// at 24 px, cropped, centred on a square canvas with padding and downscaled by
// area averaging so the edges are anti-aliased.
//
// With --preview <dir> it also writes debug PNGs (the picked blob, the
// thickened shape and the final icons on a checkerboard) so you can look at them.
//
// (Dart note: this is a plain script, so `main` runs on `dart run`. The helpers
// are top-level functions so test/notification_icon_test.dart can import them
// without running `main`. That is like exporting functions from a TS module
// and keeping the CLI part under `if (require.main === module)`.)
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

const _logoPath = 'assets/images/logo.png';
const _resDir = 'android/app/src/main/res';

/// Output density folders and the small icon size (px) for each.
const _statSizes = {
  'drawable-mdpi': 24,
  'drawable-hdpi': 36,
  'drawable-xhdpi': 48,
  'drawable-xxhdpi': 72,
  'drawable-xxxhdpi': 96,
};

/// Luminance above this is "white" (the lines, ring and lettering).
const whiteThreshold = 128;

/// Thickening radius at the 1000 px logo scale.
const dilateRadius = 22;

/// Empty border around the pear, as a fraction of the canvas side.
const padFraction = 0.12;

/// A connected group of white pixels.
class Blob {
  Blob(this.label, this.x, this.y)
    : size = 0,
      minX = x,
      minY = y,
      maxX = x,
      maxY = y;

  final int label;

  /// First pixel found (the scan start).
  final int x;
  final int y;
  int size;
  int minX;
  int minY;
  int maxX;
  int maxY;

  int get width => maxX - minX + 1;
  int get height => maxY - minY + 1;
}

/// Result of [labelComponents]: [labels] has one entry per pixel (0 = not
/// white, otherwise the 1-based index into [blobs] + 1).
class Labelled {
  Labelled(this.labels, this.blobs);

  final Int32List labels;
  final List<Blob> blobs;
}

/// Labels the connected `true`/non-zero pixels of [mask] (w x h), 8-connected
/// so a thin diagonal line stays in one piece. Iterative breadth-first search
/// (a recursive flood fill would overflow the stack on a 1000 px bitmap).
Labelled labelComponents(Uint8List mask, int w, int h) {
  final labels = Int32List(w * h);
  final blobs = <Blob>[];
  final queue = Queue<int>();
  for (var start = 0; start < w * h; start++) {
    if (mask[start] == 0 || labels[start] != 0) continue;
    final blob = Blob(blobs.length + 1, start % w, start ~/ w);
    blobs.add(blob);
    labels[start] = blob.label;
    queue.add(start);
    while (queue.isNotEmpty) {
      final p = queue.removeFirst();
      final px = p % w;
      final py = p ~/ w;
      blob.size++;
      if (px < blob.minX) blob.minX = px;
      if (px > blob.maxX) blob.maxX = px;
      if (py < blob.minY) blob.minY = py;
      if (py > blob.maxY) blob.maxY = py;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final nx = px + dx;
          final ny = py + dy;
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          final n = ny * w + nx;
          if (mask[n] == 0 || labels[n] != 0) continue;
          labels[n] = blob.label;
          queue.add(n);
        }
      }
    }
  }
  return Labelled(labels, blobs);
}

/// The pear outline: the biggest blob (by pixel count) whose bounding box lies
/// entirely within [maxRadius] of the image centre (box corners count, so the pear, which reaches about 430 px at its corner, passes and the 640 px ring does not). The white square
/// background and the outer ring reach further out, and each letter is far
/// smaller than the pear. Null when nothing qualifies.
Blob? pickOutline(List<Blob> blobs, int w, int h, {double maxRadius = 500}) {
  final cx = (w - 1) / 2;
  final cy = (h - 1) / 2;
  Blob? best;
  for (final b in blobs) {
    // The farthest bounding-box corner from the centre.
    final far = [
      for (final x in [b.minX, b.maxX])
        for (final y in [b.minY, b.maxY])
          math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)),
    ].reduce(math.max);
    if (far > maxRadius) continue;
    if (best == null || b.size > best.size) best = b;
  }
  return best;
}

/// A mask (255/0) of the pixels carrying [label].
Uint8List maskOfLabel(Labelled l, int label) {
  final out = Uint8List(l.labels.length);
  for (var i = 0; i < out.length; i++) {
    if (l.labels[i] == label) out[i] = 255;
  }
  return out;
}

/// Grows every set pixel of [mask] into a disc of [radius] px.
Uint8List dilate(Uint8List mask, int w, int h, int radius) {
  // Half-width of the disc on each row offset, so each set pixel stamps spans.
  final span = <int>[
    for (var dy = -radius; dy <= radius; dy++)
      math.sqrt(radius * radius - dy * dy).floor(),
  ];
  final out = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (mask[y * w + x] == 0) continue;
      for (var dy = -radius; dy <= radius; dy++) {
        final ny = y + dy;
        if (ny < 0 || ny >= h) continue;
        final half = span[dy + radius];
        final from = math.max(0, x - half);
        final to = math.min(w - 1, x + half);
        out.fillRange(ny * w + from, ny * w + to + 1, 255);
      }
    }
  }
  return out;
}

/// Crops [mask] to its bounding box and centres it on a square canvas whose
/// empty border is [padding] of the side on every edge. Returns the canvas and
/// its side length. An empty mask gives a blank 1 px canvas.
({Uint8List pixels, int side}) squareCrop(
  Uint8List mask,
  int w,
  int h, {
  double padding = padFraction,
}) {
  var minX = w, minY = h, maxX = -1, maxY = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (mask[y * w + x] == 0) continue;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
  }
  if (maxX < 0) return (pixels: Uint8List(1), side: 1);
  final bw = maxX - minX + 1;
  final bh = maxY - minY + 1;
  final side = (math.max(bw, bh) / (1 - 2 * padding)).ceil();
  final out = Uint8List(side * side);
  final offX = (side - bw) ~/ 2;
  final offY = (side - bh) ~/ 2;
  for (var y = 0; y < bh; y++) {
    for (var x = 0; x < bw; x++) {
      out[(offY + y) * side + offX + x] = mask[(minY + y) * w + minX + x];
    }
  }
  return (pixels: out, side: side);
}

/// Shrinks the square [src] (side [srcSide]) to [target] px by area averaging:
/// each output pixel is the mean of the source area it covers (partial pixels
/// weighted), so edges come out anti-aliased as 0-255 coverage.
Uint8List areaDownscale(Uint8List src, int srcSide, int target) {
  final scale = srcSide / target;
  final out = Uint8List(target * target);
  for (var ty = 0; ty < target; ty++) {
    final y0 = ty * scale;
    final y1 = (ty + 1) * scale;
    for (var tx = 0; tx < target; tx++) {
      final x0 = tx * scale;
      final x1 = (tx + 1) * scale;
      var sum = 0.0;
      for (var sy = y0.floor(); sy < math.min(srcSide, y1.ceil()); sy++) {
        final wy = math.min(sy + 1, y1) - math.max(sy, y0);
        for (var sx = x0.floor(); sx < math.min(srcSide, x1.ceil()); sx++) {
          final wx = math.min(sx + 1, x1) - math.max(sx, x0);
          sum += src[sy * srcSide + sx] * wy * wx;
        }
      }
      out[ty * target + tx] = (sum / (scale * scale)).round().clamp(0, 255);
    }
  }
  return out;
}

/// Pure white RGB with [coverage] (0-255) as alpha.
img.Image whiteWithAlpha(Uint8List coverage, int side) {
  final image = img.Image(width: side, height: side, numChannels: 4);
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      image.setPixelRgba(x, y, 255, 255, 255, coverage[y * side + x]);
    }
  }
  return image;
}

/// Luminance (0-255) of each pixel of [image], composited over white.
Uint8List luminance(img.Image image) {
  final rgba = image
      .convert(numChannels: 4)
      .getBytes(order: img.ChannelOrder.rgba);
  final out = Uint8List(image.width * image.height);
  for (var i = 0; i < out.length; i++) {
    final r = rgba[i * 4];
    final g = rgba[i * 4 + 1];
    final b = rgba[i * 4 + 2];
    final a = rgba[i * 4 + 3] / 255;
    final lum = 0.299 * r + 0.587 * g + 0.114 * b;
    out[i] = (lum * a + 255 * (1 - a)).round();
  }
  return out;
}

/// The logo with everything outside the black disc made transparent. The white
/// square is the white area connected to the border; the pixels within 2 px of
/// it are the disc's anti-aliased edge, drawn black with alpha = darkness, so
/// the circle's rim stays smooth.
img.Image circleMasked(img.Image logo) {
  final w = logo.width;
  final h = logo.height;
  final lum = luminance(logo);
  final white = Uint8List(w * h);
  for (var i = 0; i < white.length; i++) {
    if (lum[i] > whiteThreshold) white[i] = 255;
  }
  final labelled = labelComponents(white, w, h);
  // Blobs touching the border are the background square.
  final background = <int>{
    for (final b in labelled.blobs)
      if (b.minX == 0 || b.minY == 0 || b.maxX == w - 1 || b.maxY == h - 1)
        b.label,
  };
  final bg = Uint8List(w * h);
  for (var i = 0; i < bg.length; i++) {
    if (background.contains(labelled.labels[i])) bg[i] = 255;
  }
  final zone = dilate(bg, w, h, 2);
  final out = img.Image(width: w, height: h, numChannels: 4);
  final rgba = logo
      .convert(numChannels: 4)
      .getBytes(order: img.ChannelOrder.rgba);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (zone[i] != 0) {
        out.setPixelRgba(x, y, 0, 0, 0, 255 - lum[i]);
      } else {
        out.setPixelRgba(
          x,
          y,
          rgba[i * 4],
          rgba[i * 4 + 1],
          rgba[i * 4 + 2],
          255,
        );
      }
    }
  }
  return out;
}

/// The thickened pear mask (255/0, same size as the logo) plus the blob picked.
({Uint8List thick, Uint8List picked, Blob blob}) buildPearMask(img.Image logo) {
  final w = logo.width;
  final h = logo.height;
  final lum = luminance(logo);
  final white = Uint8List(w * h);
  for (var i = 0; i < white.length; i++) {
    if (lum[i] > whiteThreshold) white[i] = 255;
  }
  final labelled = labelComponents(white, w, h);
  // The limit is for the 1000 px logo (pear corner about 430 px out, the ring box corner about 640); scale it for other sizes.
  final blob = pickOutline(labelled.blobs, w, h, maxRadius: 0.5 * w);
  if (blob == null) {
    throw StateError('Could not find the pear outline in the logo.');
  }
  final picked = maskOfLabel(labelled, blob.label);
  final radius = (dilateRadius * w / 1000).round();
  return (thick: dilate(picked, w, h, radius), picked: picked, blob: blob);
}

/// Greyscale preview PNG of a 255/0 mask.
img.Image maskPreview(Uint8List mask, int w, int h) {
  final out = img.Image(width: w, height: h, numChannels: 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final v = mask[y * w + x];
      out.setPixelRgba(x, y, v, v, v, 255);
    }
  }
  return out;
}

/// [icon] (white on transparent) drawn over a checkerboard, enlarged so small
/// icons are visible in a preview.
img.Image onChecker(img.Image icon, int zoom) {
  final size = icon.width * zoom;
  final out = img.Image(width: size, height: size, numChannels: 4);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dark = ((x ~/ 8) + (y ~/ 8)).isEven;
      final base = dark ? 70 : 110;
      final p = icon.getPixel(x ~/ zoom, y ~/ zoom);
      final a = p.a / 255;
      final v = (p.r * a + base * (1 - a)).round();
      out.setPixelRgba(x, y, v, v, v, 255);
    }
  }
  return out;
}

void _write(String path, img.Image image) {
  final file = File(path)..createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  stdout.writeln('wrote $path (${image.width}x${image.height})');
}

void main(List<String> args) {
  final logoFile = File(_logoPath);
  if (!logoFile.existsSync()) {
    stderr.writeln('$_logoPath not found: run this from the mobile/ folder.');
    exit(1);
  }
  final previewAt = args.indexOf('--preview');
  final previewDir = previewAt >= 0 && previewAt + 1 < args.length
      ? args[previewAt + 1]
      : null;

  final logo = img.decodePng(logoFile.readAsBytesSync());
  if (logo == null) {
    stderr.writeln('Could not decode $_logoPath.');
    exit(1);
  }
  final w = logo.width;
  final h = logo.height;
  final pear = buildPearMask(logo);
  stdout.writeln(
    'pear blob: ${pear.blob.size} px, '
    'box ${pear.blob.minX},${pear.blob.minY} to ${pear.blob.maxX},${pear.blob.maxY}',
  );
  final square = squareCrop(pear.thick, w, h);

  for (final entry in _statSizes.entries) {
    final coverage = areaDownscale(square.pixels, square.side, entry.value);
    _write(
      '$_resDir/${entry.key}/ic_stat_bpj.png',
      whiteWithAlpha(coverage, entry.value),
    );
  }

  final large = img.copyResize(
    circleMasked(logo),
    width: 192,
    height: 192,
    interpolation: img.Interpolation.average,
  );
  _write('$_resDir/drawable-xxhdpi/ic_notification_large.png', large);

  if (previewDir != null) {
    _write('$previewDir/1_picked_blob.png', maskPreview(pear.picked, w, h));
    _write('$previewDir/2_thickened.png', maskPreview(pear.thick, w, h));
    for (final entry in _statSizes.entries) {
      final coverage = areaDownscale(square.pixels, square.side, entry.value);
      final icon = whiteWithAlpha(coverage, entry.value);
      _write(
        '$previewDir/3_${entry.value}px.png',
        onChecker(icon, 192 ~/ entry.value),
      );
    }
    _write('$previewDir/4_large.png', onChecker(large, 1));
  }
}
