// Builds the app icon PNGs from assets/icon/logo.svg (the round club badge) plus
// the club stripes, then run `dart run flutter_launcher_icons`.
//   node scripts/build-icons.mjs
// Needs `sharp`; it is borrowed from the Next.js workspace (run `npm i` in ../next).
import { createRequire } from 'node:module';
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const require = createRequire(new URL('../../next/package.json', import.meta.url));
const sharp = require('sharp');
const dir = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'assets', 'icon');

const SIZE = 1024;
const ORANGE = '#ff7e32';
const STRIPE = 120; // width of each of the three stripes (orange centre, white either side)
const BADGE_IOS = 0.74; // badge diameter as a fraction of the iOS icon
const BADGE_ANDROID = 0.58; // must sit inside Android's circular safe zone (~66%)
const ROTATION = 45; // rotation angle for the stripes

const c = SIZE / 2;
const stripes = `<g transform="rotate(${ROTATION} ${c} ${c})">
  <rect x="${c - STRIPE * 1.5}" y="-1024" width="${STRIPE * 3}" height="${SIZE * 3}" fill="#fff"/>
  <rect x="${c - STRIPE / 2}" y="-1024" width="${STRIPE}" height="${SIZE * 3}" fill="${ORANGE}"/>
</g>`;
const bg = Buffer.from(
  `<svg xmlns="http://www.w3.org/2000/svg" width="${SIZE}" height="${SIZE}">
    <rect width="${SIZE}" height="${SIZE}" fill="#000"/>${stripes}</svg>`
);

const logo = readFileSync(path.join(dir, 'logo.svg'));
const logoDataUri = `data:image/svg+xml;base64,${logo.toString('base64')}`;
const badgeSvg = (fraction) => {
  const d = Math.round(SIZE * fraction);
  const off = Math.round((SIZE - d) / 2);
  return `<image x="${off}" y="${off}" width="${d}" height="${d}" href="${logoDataUri}"/>`;
};
const svg = (content) => `<svg xmlns="http://www.w3.org/2000/svg" width="${SIZE}" height="${SIZE}" viewBox="0 0 ${SIZE} ${SIZE}">${content}</svg>`;
async function badge(fraction) {
  const d = Math.round(SIZE * fraction);
  const png = await sharp(logo, { density: 300 }).resize(d, d).png().toBuffer();
  const off = Math.round((SIZE - d) / 2);
  return { input: png, left: off, top: off };
}

const out = (name, buf) => writeFileSync(path.join(dir, name), buf);
const base = sharp(bg).png();
out('icon_background.png', await base.toBuffer());
out('icon_background.svg', svg(`<rect width="${SIZE}" height="${SIZE}" fill="#000"/>${stripes}`));
out('icon.svg', svg(`<rect width="${SIZE}" height="${SIZE}" fill="#000"/>${stripes}${badgeSvg(BADGE_IOS)}`));
out('icon_foreground.svg', svg(badgeSvg(BADGE_ANDROID)));
out(
  'icon.png',
  await sharp(bg)
    .composite([await badge(BADGE_IOS)])
    .flatten({ background: '#000' })
    .png()
    .toBuffer()
);
out(
  'icon_foreground.png',
  await sharp({ create: { width: SIZE, height: SIZE, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite([await badge(BADGE_ANDROID)])
    .png()
    .toBuffer()
);
console.log('wrote icon.png, icon_background.png, icon_foreground.png and SVG equivalents');
