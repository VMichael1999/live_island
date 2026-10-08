// Pone lado a lado la tarjeta de la galería del HTML y el golden de Flutter de
// cada preset, para revisar la fidelidad (docs/PROMPT.md §9).
// Uso: npm i playwright-core && node tool/compare_html.js
// Antes: flutter test test/golden_test.dart --update-goldens
const { chromium } = require('playwright-core');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const html = 'file://' + path.join(root, 'docs/design/live_island_prototipos.html');
const goldens = path.join(root, 'test/goldens');
const out = path.join(root, 'docs/design/comparaciones');
const NOW = '2026-10-04T15:00:00.000Z';

(async () => {
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  });
  const page = await browser.newPage({ viewport: { width: 1400, height: 1000 }, deviceScaleFactor: 2 });
  await page.addInitScript((now) => { const t = Date.parse(now); Date.now = () => t; }, NOW);
  await page.goto(html);
  await page.waitForTimeout(500);
  // Quita la animación de reloj: el HTML vuelve a pintar cada segundo.
  await page.evaluate(() => { for (let i = 1; i < 9999; i++) clearInterval(i); });

  const ids = await page.$$eval('#preset option', (o) => o.map((x) => x.value));
  const cards = await page.$$('#gallery .g-card');
  const shot = await browser.newPage({ viewport: { width: 1000, height: 40 }, deviceScaleFactor: 1 });
  for (let i = 0; i < ids.length; i++) {
    const id = ids[i];
    const wall = await cards[i].$('.g-wall');
    const htmlPng = (await wall.screenshot()).toString('base64');
    const row = ['dark', 'light'].map((b) => {
      const g = fs.readFileSync(path.join(goldens, `galeria_${id}_${b}.png`)).toString('base64');
      return `<figure><img src="data:image/png;base64,${g}"><figcaption>Flutter · ${b === 'dark' ? 'oscuro' : 'claro'}</figcaption></figure>`;
    }).join('');
    await shot.setContent(`<body style="margin:0;padding:16px;background:#fff;font:13px system-ui;display:flex;gap:20px;align-items:flex-start">
      <figure style="margin:0"><img style="width:278px" src="data:image/png;base64,${htmlPng}"><figcaption>HTML · ${id}</figcaption></figure>
      ${row.replace(/<img/g, '<img style="width:278px"')}</body>`);
    await shot.waitForTimeout(100);
    await shot.screenshot({ path: path.join(out, `${id}.png`), fullPage: true });
  }
  console.log('comparaciones:', ids.length);
  await browser.close();
})();
