---
name: appstore-screenshots
description: Generate high-converting App Store marketing screenshots by compositing raw simulator captures into branded frames with big benefit headlines, rendered at exact App Store pixel sizes via headless Chrome. Use when creating or updating App Store screenshots, designing screenshot marketing frames, wanting text/layout control beyond fastlane frameit, or building a repeatable screenshot pipeline. No subscription apps, no design tool.
allowed-tools: Bash, Read, Write, Edit, Glob
---

# App Store Marketing Screenshots

Paid screenshot tools (AppLaunchpad, Previewed, Shotbot, Rotato, Picasso) are all
the same thing: an HTML/canvas compositor that drops a screenshot onto a
background with a headline, rented monthly. `frameit` is the free-but-rigid
version — fixed layout, tiny title, PNG backgrounds, almost no control.

This skill reproduces the paid output for free: an **HTML/CSS template rendered
by headless Chrome** at the exact App Store pixel size. Full control over
typography, gradients, device bezel, shadow, and headline. AI writes the
conversion copy and design system; a JSON file drives every slide; one command
regenerates the whole set.

## Why headless Chrome (not frameit, not a paid app)

- Every pixel is CSS. Change a headline, colour, or layout by editing text.
- Renders at the precise required resolution (e.g. 1320×2868 for 6.9″ iPhone).
- Fully scriptable and committed to the repo — repeatable across releases.
- Zero install if Google Chrome is present; zero subscription always.

## Pipeline

```
fastlane snapshot                 raw simulator captures -> screenshots_raw/<locale>/
fastlane marketing (this skill)   composite branded frames -> screenshots/<locale>/
fastlane upload_screenshots       deliver uploads screenshots/<locale>/ (no binary/submit)
```

`deliver` uploads every PNG in `screenshots/<locale>/`, ordered by filename — so
prefix names `01_`, `02_`, … and keep that dir clean (the renderer wipes it each
run).

## Conversion copy (this is what actually matters)

Only the **first 3 screenshots** show in search results without tapping. They
make the install decision. Rules that convert:

- **Benefit headlines, not feature labels.** "Never miss a renewal" beats
  "Vehicle List". 2–5 words per line, big enough to read at thumbnail size.
- **Slot order:** 1 = primary value proposition, 2 = core differentiator,
  3 = next strongest feature, then supporting features / social proof.
- **Never** lead with onboarding, splash, or empty states.
- One consistent visual system across all slides so the set reads as one story.
- Highlight one keyword per headline in the accent colour (the `*word*` syntax
  below) to pull the eye.
- Match the app's real typeface (embed the system font via `@font-face`) so the
  marketing frame and the app feel like one product.
- **Make the raw capture say the right thing.** A headline about reminders over a
  screen showing "notifications off", or a "documents" slide showing a red
  Delete button, undercuts the pitch. Force a believable state from the
  `--screenshots` demo seed and control scroll position in the UI test — fix the
  capture, not the frame.

## Design system (the frame that reads as premium)

The template composes, top to bottom, on a crafted background:

- **Background:** warm paper gradient + two soft radial glows (accent colour top,
  gold bottom-right) + a fine SVG `feTurbulence` grain at ~5% multiply. Atmosphere
  and depth, never a flat fill.
- **Brand lockup:** rounded app icon + wordmark (falls back to an uppercase gold
  kicker if no `iconPath`).
- **Headline:** heavy SF (weight ~850), tight tracking, the `*keyword*` in the
  accent colour with a translucent gold underline swash.
- **Subhead:** one benefit line.
- **Device:** realistic titanium frame — a diagonal metallic gradient rail with
  inset highlight/shadow, a Dynamic Island pill, and a colour-tinted drop shadow
  so the phone floats.

Keep the system identical across all slides (only the headline/screenshot change);
consistency is what makes an App Store set convert, not per-slide novelty.

## Requirements (or App Store rejects)

- **Exact pixel size** per device class. 6.9″ iPhone = 1320×2868 or 1290×2796.
  6.9″ alone satisfies the iPhone requirement; smaller sizes auto-scale. iPad
  sizes only if the app runs on iPad. Check Apple's current screenshot
  specifications — they change per device generation.
- **RGB, no alpha channel.** Alpha triggers `ERROR ITMS-90475`. Chrome emits
  opaque RGB already; the renderer also flattens with `magick` when present.
- 1–10 screenshots per size; 5–6 is the sweet spot.

## `slides.json` — the whole config

Paths are relative to the repo root. `*word*` in a headline line renders that
token in the accent colour with the underline swash.

```json
{
  "canvas": { "width": 1320, "height": 2868 },
  "locale": "en-GB",
  "fontPath": "/System/Library/Fonts/SFNS.ttf",
  "rawDir": "fastlane/screenshots_raw/en-GB",
  "outDir": "fastlane/screenshots/en-GB",
  "style": {
    "name": "My App",
    "iconPath": "MyApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png",
    "accent": "#2D7D4D",
    "gold": "#B0842F",
    "ink": "#14231A",
    "subInk": "#5A655E"
  },
  "slides": [
    {
      "out": "01_Home.png",
      "src": "iPhone 17 Pro Max-01_Home.png",
      "head": ["Never miss a", "*renewal* again"],
      "sub": "One short benefit line under the headline."
    }
  ]
}
```

## `render.mjs` — the compositor

Drop this at `fastlane/marketing/render.mjs`. No npm dependencies. Runs under
`node` or `bun`. Override the browser with `CHROME_BIN` (Chromium/Edge work).

```js
#!/usr/bin/env node
import { execFileSync, spawnSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, isAbsolute, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const root = resolve(scriptDir, "..", "..");
const configPath = resolve(process.argv[2] ?? join(scriptDir, "slides.json"));
const cfg = JSON.parse(readFileSync(configPath, "utf8"));

const chrome = process.env.CHROME_BIN ??
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
if (!existsSync(chrome)) fail(`Chrome not found at "${chrome}". Set CHROME_BIN.`);

const abs = (p) => (isAbsolute(p) ? p : resolve(root, p));
const { width, height } = cfg.canvas;
const s = cfg.style;
const rawDir = abs(cfg.rawDir);
const outDir = abs(cfg.outDir);
const fontUrl = pathToFileURL(cfg.fontPath).href;
const iconUrl = s.iconPath ? pathToFileURL(abs(s.iconPath)).href : null;
const tmpDir = join(scriptDir, ".tmp");
const hasMagick = spawnSync("magick", ["-version"], { stdio: "ignore" }).status === 0;

rmSync(tmpDir, { recursive: true, force: true });
mkdirSync(tmpDir, { recursive: true });
rmSync(outDir, { recursive: true, force: true }); // deliver uploads everything here
mkdirSync(outDir, { recursive: true });

const esc = (t) => t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const markup = (line) => esc(line).replace(/\*([^*]+)\*/g, '<span class="g">$1</span>');
const grain = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='220' height='220'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E";

function hex(h, a) { const n = parseInt(h.slice(1), 16); return `rgba(${(n>>16)&255},${(n>>8)&255},${n&255},${a})`; }

function html(slide) {
  const src = pathToFileURL(join(rawDir, slide.src)).href;
  const headHtml = slide.head.map(markup).join("<br>");
  const lockup = iconUrl
    ? `<div class="lockup"><img class="icon" src="${iconUrl}"><span class="name">${esc(s.name)}</span></div>`
    : `<div class="kicker">${esc(s.name)}</div>`;
  return `<!doctype html><html><head><meta charset="utf-8"><style>
@font-face{font-family:"App";src:url("${fontUrl}");font-weight:100 900;}
*{margin:0;padding:0;box-sizing:border-box;}
html,body{width:${width}px;height:${height}px;}
.frame{position:relative;width:${width}px;height:${height}px;overflow:hidden;
  display:flex;flex-direction:column;align-items:center;padding:120px 96px 0;
  font-family:"App",sans-serif;
  background:
    radial-gradient(115% 75% at 50% -12%, ${hex(s.accent,0.22)} 0%, transparent 58%),
    radial-gradient(85% 55% at 108% 106%, ${hex(s.gold,0.16)} 0%, transparent 55%),
    linear-gradient(180deg, #F7F3EA 0%, #EFE9DC 56%, #E8E1D1 100%);}
.frame::after{content:"";position:absolute;inset:0;pointer-events:none;
  background-image:url("${grain}");background-size:220px 220px;opacity:.05;mix-blend-mode:multiply;}
.lockup{display:flex;align-items:center;gap:22px;margin-bottom:46px;z-index:2;}
.lockup .icon{width:82px;height:82px;border-radius:19px;
  box-shadow:0 8px 20px -4px rgba(20,40,25,.28),0 0 0 1px rgba(0,0,0,.04);}
.lockup .name{font-weight:600;font-size:41px;letter-spacing:.3px;color:${s.ink};}
.kicker{font-weight:700;font-size:40px;letter-spacing:3px;text-transform:uppercase;color:${s.gold};margin-bottom:30px;z-index:2;}
h1{font-weight:850;font-size:122px;line-height:1.02;letter-spacing:-3.5px;color:${s.ink};text-align:center;z-index:2;}
h1 .g{color:${s.accent};position:relative;white-space:nowrap;}
h1 .g::after{content:"";position:absolute;left:1%;right:1%;bottom:.02em;height:13px;border-radius:8px;background:${s.gold};opacity:.34;}
.sub{font-weight:500;font-size:44px;line-height:1.32;color:${s.subInk};text-align:center;margin-top:38px;max-width:1000px;z-index:2;}
.stage{margin-top:84px;z-index:2;}
.device{width:948px;border-radius:132px;padding:22px;position:relative;
  background:linear-gradient(150deg,#42454b 0%,#191a1e 26%,#0b0c0e 58%,#2a2c31 100%);
  box-shadow:inset 0 2px 3px rgba(255,255,255,.14),inset 0 -2px 3px rgba(0,0,0,.5),
    0 84px 130px -40px ${hex(s.accent,0.42)},0 34px 66px -30px rgba(0,0,0,.42);}
.screen{position:relative;border-radius:110px;overflow:hidden;background:#000;}
.screen img{width:100%;display:block;}
.island{position:absolute;top:30px;left:50%;transform:translateX(-50%);width:252px;height:74px;background:#000;border-radius:40px;z-index:3;}
</style></head><body><div class="frame">
${lockup}
<h1>${headHtml}</h1>
<div class="sub">${esc(slide.sub)}</div>
<div class="stage"><div class="device"><div class="screen">
<img src="${src}"><div class="island"></div>
</div></div></div>
</div></body></html>`;
}

for (const slide of cfg.slides) {
  if (!existsSync(join(rawDir, slide.src)))
    fail(`Raw screenshot missing: ${join(cfg.rawDir, slide.src)}. Run \`fastlane snapshot\` first.`);
  const htmlPath = join(tmpDir, slide.out.replace(/\.png$/, ".html"));
  const outPath = join(outDir, slide.out);
  writeFileSync(htmlPath, html(slide));
  execFileSync(chrome, ["--headless", "--disable-gpu", "--hide-scrollbars",
    "--force-device-scale-factor=1", `--window-size=${width},${height}`,
    `--screenshot=${outPath}`, pathToFileURL(htmlPath).href],
    { stdio: ["ignore", "ignore", "ignore"] });
  if (!existsSync(outPath)) fail(`Chrome did not produce ${outPath}`);
  if (hasMagick) execFileSync("magick", [outPath, "-alpha", "remove", "-alpha", "off", "-strip", outPath]);
  console.log(`  ${slide.out}`);
}
rmSync(tmpDir, { recursive: true, force: true });
console.log(`Rendered ${cfg.slides.length} frames -> ${cfg.outDir}`);
function fail(m) { console.error(`render.mjs: ${m}`); process.exit(1); }
```

## Fastlane wiring

Replace any `frameit` step. The renderer resolves its own paths from the repo
root, so the lane's cwd is irrelevant.

```ruby
desc "Capture raw screenshots, then composite marketing frames"
lane :screenshots do
  snapshot
  marketing
end

desc "Composite raw simulator captures into branded App Store marketing frames"
lane :marketing do
  script = File.join(File.expand_path(FastlaneCore::FastlaneFolder.path), "marketing", "render.mjs")
  UI.user_error!("Renderer missing: #{script}") unless File.exist?(script)
  sh("node", script)
end

desc "Upload the composited screenshots to App Store Connect (no binary, no submit)"
lane :upload_screenshots do
  deliver(skip_binary_upload: true, skip_metadata: true, skip_screenshots: false,
          overwrite_screenshots: true, force: true)
end
```

`upload_screenshots` needs App Store Connect credentials — an API key (`.p8`) for
non-interactive runs, else interactive 2FA. `deliver` maps each PNG to a display
size by its pixel dimensions and replaces the current set for that size.

## Adapting to a new app

1. Run `fastlane snapshot` to produce raw captures in `screenshots_raw/<locale>/`.
2. Copy `render.mjs` into `fastlane/marketing/`.
3. Write `fastlane/marketing/slides.json`: set `rawDir`/`outDir`/`locale`,
   pick `style` colours from the app's palette, set `iconPath` + `name`, embed
   the app's font in `fontPath`, one slide per screen with a benefit headline.
4. `fastlane screenshots`, then eyeball each frame.
5. `fastlane upload_screenshots` (or your submit/`deliver` lane) uploads them.

## Design tuning

- **Bolder look:** drop the `.device` background to go bezel-less, or crop the
  screenshot so the device bleeds off the bottom edge for higher stop-power.
- **Backgrounds** are any CSS `background` — swap the paper gradient for a solid
  brand colour, or a `url(...)` AI-generated scene for a lifestyle style.
- **Localise** with a `slides.json` per locale and a matching
  `screenshots_raw/<locale>/` capture set. Rewrite copy per market — translate the
  benefit, don't machine-translate the words.

## Common pitfalls

- Leaving stale framings in `screenshots/<locale>/` — deliver uploads them too.
  The renderer wipes the dir; don't hand-drop extra PNGs there.
- Alpha channel → ITMS-90475. Keep the flatten step.
- Onboarding/empty screens in the first 3 slots.
- Headlines too long or too small to read as a search-result thumbnail.
- Demo seed / scroll position showing an off, empty, or destructive state that
  contradicts the headline — fix the `--screenshots` seed and the UI test, then
  re-`fastlane screenshots`.
