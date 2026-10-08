// Extrae del HTML de prototipos, con la hora congelada, los 15 presets y los
// avisos del panel "Validación". Los tests de Dart comparan LiveIsland.check()
// contra estos archivos.
// Uso: npm i playwright-core && node tool/extract_html_checks.js
const { chromium } = require('playwright-core');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const html = 'file://' + path.join(root, 'docs/design/live_island_prototipos.html');
const out = path.join(root, 'test/fixtures');
const NOW = '2026-10-04T15:00:00.000Z';

(async () => {
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  });
  const page = await browser.newPage({ viewport: { width: 1400, height: 1000 } });
  await page.addInitScript((now) => {
    const t = Date.parse(now);
    Date.now = () => t;
  }, NOW);
  await page.goto(html);
  await page.waitForTimeout(500);

  const data = await page.evaluate(() => {
    const img = (v) => v ? {
      fit: v.fit || 'contain',
      shape: v.shape || null,
      kb: Math.max(1, Math.round(v.src.length * 0.75 / 1024)),
    } : null;
    const presets = [], checks = {};
    for (const p of PRESETS) {
      load(p.id);
      const s = state;
      presets.push({
        ...s,
        logoImg: img(s.logoImg), mainImg: img(s.mainImg),
        avatarImg: img(s.avatarImg), trackerImg: img(s.trackerImg),
        deadline: new Date(deadline).toISOString(),
      });
      checks[p.id] = [...document.querySelectorAll('#checks .ck')].map((e) => ({
        sev: e.querySelector('.dot').className.replace('dot', '').trim(),
        text: e.children[1].textContent.replace(/\s+/g, ' ').trim(),
      }));
    }
    return { sf: SF, presets, checks };
  });

  fs.writeFileSync(path.join(out, 'html_presets.json'),
    JSON.stringify({ now: NOW, sf: data.sf, presets: data.presets }, null, 2) + '\n');
  fs.writeFileSync(path.join(out, 'html_checks.json'),
    JSON.stringify(data.checks, null, 2) + '\n');
  console.log('presets:', data.presets.length);
  await browser.close();
})();
