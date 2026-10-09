// Combines screenshots into one contact sheet: node sheet.cjs <playwright-dir> <out.png> <cols> <img...>
const path = require('path');
const fs = require('fs');
const { chromium } = require(path.join(process.argv[2], 'playwright'));
const [out, cols, ...files] = process.argv.slice(3);
(async () => {
  const browser = await chromium.launch();
  try {
    const w = 1600, cw = Math.floor(w / cols), ch = Math.round(cw * 9 / 16);
    const rows = Math.ceil(files.length / cols);
    const page = await browser.newPage({ viewport: { width: w, height: rows * ch } });
    const cells = files.map(f => `<div style="position:relative"><img src="data:image/png;base64,${fs.readFileSync(f).toString('base64')}">
      <span>${path.basename(f, '.png').split('__')[0]}</span></div>`);
    await page.setContent(`<style>body{margin:0;display:grid;grid-template-columns:repeat(${cols},${cw}px)}
      img{width:${cw}px;height:${ch}px;display:block}span{position:absolute;left:6px;top:4px;font:14px sans-serif;color:#333}</style>${cells.join('')}`);
    await page.screenshot({ path: out });
  } finally { await browser.close(); }
})();
