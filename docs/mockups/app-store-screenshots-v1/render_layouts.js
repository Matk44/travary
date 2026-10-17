// Renders the App Store frame references from layout.html + frames.json.
//
//   node render_layouts.js            placeholder screens, layouts, green bases, style board
//   node render_layouts.js --final    frames with your simulator captures from captures/
//
// Needs Playwright (npm i playwright, or PLAYWRIGHT=/path/to/node_modules/playwright)
// and network access for Google Fonts. Run it from anywhere; paths are relative
// to this folder.
const fs = require('fs');
const path = require('path');
const { chromium } = require(process.env.PLAYWRIGHT || 'playwright');

const here = __dirname;
const data = JSON.parse(fs.readFileSync(path.join(here, 'frames.json'), 'utf8'));
const final = process.argv.includes('--final');
// --only=11,12 renders just those frames (and the contact sheet)
const only = (process.argv.find(a => a.startsWith('--only=')) || '').slice(7).split(',').filter(Boolean);
const wanted = f => only.length === 0 || only.includes(f.id);

async function shoot(page, hash, size, file, type) {
  await page.setViewportSize(size);
  // A query per frame forces a fresh load (a new #hash alone wouldn't re-run the page)
  await page.goto('file://' + path.join(here, 'layout.html') + '?' + hash + '#' + hash);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForFunction(() => [...document.images].every(i => i.complete));
  await page.waitForTimeout(150);
  const over = await page.evaluate(() => document.body.dataset.overflow || '');
  if (over) console.warn(`  ! caption too wide in ${hash}: ${over}`);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  await page.screenshot({ path: file, type, ...(type === 'jpeg' ? { quality: 92 } : {}), clip: { x: 0, y: 0, ...size } });
  console.log('  ' + path.relative(here, file));
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.addInitScript(`window.FRAMES = ${JSON.stringify(data)};`);
  const canvas = { width: data.canvas.width, height: data.canvas.height };
  const ref = p => path.join(here, 'references', p);

  if (final) {
    for (const f of data.frames.filter(wanted)) {
      const capture = path.join(here, 'captures', `${f.id}-${f.slug}.png`);
      if (!fs.existsSync(capture)) { console.log(`  skip ${f.id}: no captures/${f.id}-${f.slug}.png`); continue; }
      await shoot(page, `${f.id}-final`, canvas, path.join(here, 'final', `${f.id}-${f.slug}.png`), 'png');
    }
  } else {
    for (const id of ['06', '08', '09'].filter(id => only.length === 0 || only.includes(id))) {
      const f = data.frames.find(x => x.id === id);
      await shoot(page, `screen-${id}`, { width: data.phone.screen.width, height: data.phone.screen.height }, path.join(here, f.screen), 'jpeg');
    }
    for (const f of data.frames.filter(wanted)) {
      await shoot(page, f.id, canvas, ref(`layout/${f.id}-${f.slug}.jpg`), 'jpeg');
      await shoot(page, `${f.id}-green`, canvas, ref(`green/${f.id}-${f.slug}-green.jpg`), 'jpeg');
    }
    if (only.length === 0) await shoot(page, 'style', { width: 2400, height: 1500 }, ref('style/style-board.jpg'), 'jpeg');
    await shoot(page, 'sheet', { width: 36 * 2 + 396 * data.frames.length + 28 * (data.frames.length - 1), height: 860 + 72 }, ref('contact-sheet.jpg'), 'jpeg');
  }
  await browser.close();
})();
