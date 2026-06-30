#!/bin/bash
# Visual audit screenshot — adapted from jensen-vvs/.claude/scripts/screenshot.sh
# Usage: bash /home/ubuntu/projects/clients/roblox-scripts/bed-wars-script/docs/screenshots/screenshot.sh <file> <width> <height>

FILE=${1:-preview-current.html}
WIDTH=${2:-393}
HEIGHT=${3:-852}

BASE="/home/ubuntu/projects/clients/roblox-scripts/bed-wars-script/docs/screenshots"
FULL_PATH="$BASE/$FILE"
BASENAME=$(basename "$FILE" .html)
OUT="$BASE/$BASENAME-${WIDTH}.png"

if [ ! -f "$FULL_PATH" ]; then
  echo "❌ File not found: $FULL_PATH"
  exit 1
fi

node -e "
const { chromium } = require('/home/ubuntu/projects/node_modules/playwright-core');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.setViewportSize({ width: ${WIDTH}, height: ${HEIGHT} });
  await page.goto('file://${FULL_PATH}');
  await page.waitForTimeout(800);
  await page.screenshot({ path: '${OUT}', fullPage: false });
  await browser.close();
  console.log('✅ Screenshot saved: ${OUT}');
})().catch(e => { console.error('❌', e.message); process.exit(1); });
" 2>&1
