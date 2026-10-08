// Genera los PNG de íconos de Android (`LiveIcon.android`) de la app de ejemplo
// a partir de los trazos de lib/src/preview/preview_symbols.dart.
// Uso: npm i playwright-core && node tool/make_example_icons.js
const { chromium } = require('playwright-core');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const dart = fs.readFileSync(path.join(root, 'lib/src/preview/preview_symbols.dart'), 'utf8');
const paths = {};
for (const m of dart.matchAll(/'([^']+)':\s*'([^']+)'/g)) paths[m[1]] = m[2];

// archivo -> nombre en preview_symbols.dart
const icons = {
  phone: 'phone', share2: 'share2', mappin: 'mappin', bike: 'bike', house: 'house',
  truck: 'truck', utensils: 'utensils', squareparking: 'squareparking', plus: 'plus',
  x: 'x', package: 'package', trophy: 'trophy',
};
const out = path.join(root, 'example/assets/live');
const COLOR = '#5F6368';

(async () => {
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  });
  const page = await browser.newPage({ viewport: { width: 96, height: 96 }, deviceScaleFactor: 1 });
  for (const [file, key] of Object.entries(icons)) {
    const d = paths[key];
    if (!d) throw new Error('falta el trazo: ' + key);
    await page.setContent(`<body style="margin:0;background:transparent"><svg id="s" width="96" height="96" viewBox="0 0 24 24" fill="none" stroke="${COLOR}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="${d}"/></svg></body>`);
    await page.locator('#s').screenshot({ path: path.join(out, `${file}.png`), omitBackground: true });
  }
  console.log('íconos:', Object.keys(icons).length);
  await browser.close();
})();
