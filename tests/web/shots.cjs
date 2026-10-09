// Screenshots of the web export in headless Chromium (software rendering).
// The viewer runs in shot mode (?shots=…&views=…): it prints "SHOT <label>" when a view is
// ready and waits until the page sets window.__shot = <label>.
// Usage: node shots.cjs <playwright-module-dir> <base-url> <out-dir> <ids|all|ui> <views>
const path = require('path');
const fs = require('fs');
const { chromium } = require(path.join(process.argv[2], 'playwright'));
const [base, out, ids, views] = process.argv.slice(3);

async function sheet(browser, files, target) {
  const imgs = files.map(f => `<img src="data:image/png;base64,${fs.readFileSync(f).toString('base64')}">`);
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  await page.setContent(`<style>body{margin:0;display:grid;grid-template-columns:1fr 1fr;gap:0}
    img{width:640px;height:360px;display:block}</style>${imgs.join('')}`);
  await page.screenshot({ path: target });
  await page.close();
}

(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader',
    '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  let failed = false;
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
    const errors = [];
    const shots = {};
    let done = false;
    let queue = Promise.resolve();
    page.on('pageerror', e => errors.push('pageerror: ' + e.message));
    page.on('console', m => {
      const t = m.text();
      if (/SCRIPT ERROR|^ERROR|USER ERROR/.test(t)) errors.push(t);
      if (t.startsWith('SHOT ')) {
        const label = t.slice(5).trim();
        queue = queue.then(async () => {
          const file = path.join(out, `${label}.png`);
          await page.screenshot({ path: file });
          const id = label.split('__')[0];
          (shots[id] = shots[id] || []).push(file);
          await page.evaluate(l => { window.__shot = l; }, label);
        });
      }
      if (t.startsWith('SHOTS DONE')) done = true;
    });
    if (ids === 'ui') {
      await page.goto(`${base}/index.html`);
      await page.waitForTimeout(12000);
      await page.screenshot({ path: path.join(out, 'ui.png') });
      done = true;
    } else {
      await page.goto(`${base}/index.html?shots=${ids}&views=${views}`);
    }
    const t0 = Date.now();
    while (!done && Date.now() - t0 < 900000) await page.waitForTimeout(250);
    await queue;
    for (const [id, files] of Object.entries(shots)) {
      if (files.length > 1) await sheet(browser, files.slice(0, 4), path.join(out, `${id}.png`));
      console.log(`${id}: ${files.length} views`);
    }
    if (!done) { console.log('TIMEOUT'); failed = true; }
    if (errors.length) { console.log('ERRORS\n  ' + errors.slice(0, 10).join('\n  ')); failed = true; }
  } finally {
    await browser.close();
  }
  process.exit(failed ? 1 : 0);
})();
