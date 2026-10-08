// Genera las capturas de docs/design/capturas/ desde el HTML de prototipos.
// Uso: npm i playwright-core && node tool/capture_html.js  (necesita Google Chrome instalado)
const { chromium } = require('playwright-core');
const out = '/Users/entelgy/Documents/Flutter animaciones/live_island/docs/design/capturas';
const url = 'file:///Users/entelgy/Documents/Flutter animaciones/live_island/docs/design/live_island_prototipos.html';
(async () => {
  const browser = await chromium.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' });
  const page = await browser.newPage({ viewport: { width: 1400, height: 1000 }, deviceScaleFactor: 2, colorScheme: 'light' });
  await page.goto(url);
  await page.waitForTimeout(1500);
  const ids = await page.$$eval('#preset option', o => o.map(x => x.value));
  for (const id of ids) {
    await page.selectOption('#preset', id);
    await page.waitForTimeout(300);
    await page.locator('#iosWall').screenshot({ path: `${out}/${id}_ios.png` });
    await page.locator('#androidMock').screenshot({ path: `${out}/${id}_android.png` });
    await page.locator('#checks').screenshot({ path: `${out}/${id}_validacion.png` });
    await page.locator('#code').evaluate(e => { e.style.maxHeight = 'none'; });
    await page.locator('#code').screenshot({ path: `${out}/${id}_codigo.png` });
    console.log('ok', id);
  }
  await page.selectOption('#preset', 'taxi');
  await page.locator('#gallery').screenshot({ path: `${out}/galeria.png` });
  for (const sec of ['editable', 'medidas', 'componentes', 'fidelidad']) {
    await page.locator('#' + sec).screenshot({ path: `${out}/seccion_${sec}.png` });
  }
  await page.screenshot({ path: `${out}/pagina_completa.png`, fullPage: true });
  await browser.close();
})();
