// Extrae del HTML de prototipos (1) los íconos, convertidos a trazos SVG
// (lib/src/preview/preview_symbols.dart) y (2) las imágenes de ejemplo en PNG
// (test/fixtures/images/) que usan las pruebas de la vista previa.
// Uso: npm i playwright-core && node tool/extract_assets.js
const { chromium } = require('playwright-core');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const html = 'file://' + path.join(root, 'docs/design/live_island_prototipos.html');

const r = (n) => String(Math.round(n * 1000) / 1000);

// Primitivas SVG de Lucide -> datos de trazo (todas se dibujan con stroke).
function toPath([tag, a]) {
  const n = (k, d = 0) => parseFloat(a[k] ?? d);
  switch (tag) {
    // Un 'm' inicial es absoluto en su propio <path>; al unir trazos hay que
    // escribirlo como 'M' para que no sea relativo al trazo anterior.
    case 'path': {
      const m = /^\s*m\s*(-?[\d.]+)[\s,]*(-?[\d.]+)([\s\S]*)$/.exec(a.d);
      if (!m) return a.d;
      // Los pares que siguen al primero de un 'm' son líneas relativas.
      const rest = m[3].trim();
      return `M${m[1]} ${m[2]}` + (/^[-\d.]/.test(rest) ? 'l' + rest : rest);
    }
    case 'circle': {
      const [cx, cy, rad] = [n('cx'), n('cy'), n('r')];
      return `M${r(cx - rad)} ${r(cy)}a${r(rad)} ${r(rad)} 0 1 0 ${r(rad * 2)} 0a${r(rad)} ${r(rad)} 0 1 0 ${r(-rad * 2)} 0Z`;
    }
    case 'rect': {
      const [x, y, w, h] = [n('x'), n('y'), n('width'), n('height')];
      const rx = Math.min(n('rx', a.ry ?? 0), w / 2), ry = Math.min(n('ry', a.rx ?? 0), h / 2);
      if (!rx && !ry) return `M${r(x)} ${r(y)}h${r(w)}v${r(h)}h${r(-w)}Z`;
      return `M${r(x + rx)} ${r(y)}h${r(w - 2 * rx)}a${r(rx)} ${r(ry)} 0 0 1 ${r(rx)} ${r(ry)}v${r(h - 2 * ry)}a${r(rx)} ${r(ry)} 0 0 1 ${r(-rx)} ${r(ry)}h${r(-(w - 2 * rx))}a${r(rx)} ${r(ry)} 0 0 1 ${r(-rx)} ${r(-ry)}v${r(-(h - 2 * ry))}a${r(rx)} ${r(ry)} 0 0 1 ${r(rx)} ${r(-ry)}Z`;
    }
    case 'line': return `M${a.x1} ${a.y1}L${a.x2} ${a.y2}`;
    case 'polyline':
    case 'polygon': {
      const nums = a.points.trim().split(/[\s,]+/).map(Number);
      const pts = [];
      for (let i = 0; i < nums.length; i += 2) pts.push(`${r(nums[i])} ${r(nums[i + 1])}`);
      return 'M' + pts.join('L') + (tag === 'polygon' ? 'Z' : '');
    }
  }
  throw new Error('primitiva no soportada: ' + tag);
}

(async () => {
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  });
  const page = await browser.newPage({ viewport: { width: 600, height: 400 }, deviceScaleFactor: 3 });
  await page.goto(html);
  const { icons, sf, samples } = await page.evaluate(() => ({ icons: ICONS, sf: SF, samples: SAMPLES }));

  const symbols = {};
  for (const [lucide, prims] of Object.entries(icons)) {
    const d = prims.map(toPath).join('');
    symbols[lucide.toLowerCase()] = d;
    if (sf[lucide]) symbols[sf[lucide]] = d;
  }
  const keys = Object.keys(symbols).sort();
  const dart = [
    '// GENERADO por tool/extract_assets.js a partir del HTML de prototipos. No editar.',
    '// Trazos de los íconos Lucide (viewBox 24, solo contorno), por nombre de SF',
    '// Symbol y por nombre de archivo de Android en minúsculas.',
    '',
    'const Map<String, String> kPreviewSymbols = {',
    ...keys.map((k) => `  '${k}': '${symbols[k]}',`),
    '};',
    '',
  ].join('\n');
  fs.writeFileSync(path.join(root, 'lib/src/preview/preview_symbols.dart'), dart);

  const sizes = { logo: [120, 120], car: [200, 90], photo: [120, 120] };
  for (const [name, [w, h]] of Object.entries(sizes)) {
    await page.setContent(`<body style="margin:0;background:transparent"><img id="i" src="${samples[name]}" width="${w}" height="${h}" style="display:block"></body>`);
    await page.waitForTimeout(100);
    await page.locator('#i').screenshot({ path: path.join(root, `test/fixtures/images/${name}.png`), omitBackground: true });
  }
  console.log('símbolos:', keys.length);
  await browser.close();
})();
