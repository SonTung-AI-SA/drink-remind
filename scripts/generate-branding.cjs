// Rasterize the original SVG master; requires sharp (Apache-2.0).
const fs = require('node:fs/promises');
const path = require('node:path');
const sharp = require(process.env.MIZU_SHARP_PATH || 'sharp');
const root = path.resolve(__dirname, '..');
async function render(svg, file, width, transparent = false) {
  await fs.mkdir(path.dirname(file), {recursive: true});
  let pipeline = sharp(Buffer.from(svg)).resize(width, width);
  if (!transparent) pipeline = pipeline.removeAlpha();
  await pipeline.png().toFile(file);
}
(async () => {
  const svg = await fs.readFile(path.join(root, 'assets/branding/app-icon.svg'), 'utf8');
  await render(svg, path.join(root, 'assets/branding/app-icon-1024.png'), 1024);
  for (const [density, size] of Object.entries({mdpi:48, hdpi:72, xhdpi:96, xxhdpi:144, xxxhdpi:192})) {
    await render(svg, path.join(root, `apps/mobile/android/app/src/main/res/mipmap-${density}/ic_launcher.png`), size);
  }
  const ios = path.join(root, 'apps/mobile/ios/Runner/Assets.xcassets');
  const manifest = JSON.parse(await fs.readFile(path.join(ios, 'AppIcon.appiconset/Contents.json'), 'utf8'));
  for (const image of manifest.images) {
    await render(svg, path.join(ios, 'AppIcon.appiconset', image.filename), Math.round(parseFloat(image.size) * parseFloat(image.scale)));
  }
  const transparent = svg.replace('<rect width="1024" height="1024" fill="#E7F5F7"/>', '');
  for (const [suffix, size] of [['',168], ['@2x',336], ['@3x',504]]) {
    await render(transparent, path.join(ios, `LaunchImage.imageset/LaunchImage${suffix}.png`), size, true);
  }
  await render(svg, path.join(root, 'apps/mobile/web/favicon.png'), 64);
  for (const size of [192,512]) {
    for (const prefix of ['Icon-', 'Icon-maskable-']) await render(svg, path.join(root, `apps/mobile/web/icons/${prefix}${size}.png`), size);
  }
  console.log('Generated Android/iOS/web brand assets from app-icon.svg');
})().catch(error => { console.error(error.message); process.exitCode=1; });
