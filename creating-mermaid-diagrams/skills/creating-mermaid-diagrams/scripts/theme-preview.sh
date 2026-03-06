#!/usr/bin/env bash
# theme-preview.sh - Generate an HTML gallery of all 24 mermaid themes on light/dark backgrounds
set -euo pipefail

OUTPUT_DIR="$HOME/.cache/mermaid-preview"
OUTPUT_FILE="$OUTPUT_DIR/mermaid-theme-gallery.html"

mkdir -p "$OUTPUT_DIR"

cat > "$OUTPUT_FILE" <<'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
<title>Mermaid Theme Gallery</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 20px; background: #f0f0f0; }
  .theme-card { background: white; border-radius: 8px; padding: 16px; margin-bottom: 24px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
  .theme-name { font-size: 18px; font-weight: bold; margin-bottom: 12px; }
  .theme-meta { font-size: 12px; color: #666; margin-bottom: 12px; font-family: monospace; white-space: pre-wrap; }
  .previews { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
  .preview { padding: 16px; border-radius: 4px; overflow-x: auto; }
  .preview-light { background: #ffffff; border: 1px solid #d0d7de; }
  .preview-dark { background: #0d1117; border: 1px solid #30363d; }
  .preview-label { font-size: 11px; font-weight: 600; margin-bottom: 8px; text-transform: uppercase; }
  .preview-light .preview-label { color: #656d76; }
  .preview-dark .preview-label { color: #8b949e; }
</style>
</head>
<body>
<h1>Mermaid Theme Gallery</h1>
<p>24 themes rendered on both light and dark backgrounds</p>
<div id="gallery"></div>
<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
<script>
const themes = [
  { name: "ocean-depth",     primary: "#0969da", info: "#0550ae", warning: "#9a6700", success: "#1a7f37", danger: "#cf222e", secondary: "#6e7781", link: "#0969da" },
  { name: "forest-canopy",   primary: "#1a7f37", info: "#0550ae", warning: "#9a6700", success: "#2da44e", danger: "#cf222e", secondary: "#57606a", link: "#1a7f37" },
  { name: "sunset-warmth",   primary: "#bc4c00", info: "#0969da", warning: "#9a6700", success: "#1a7f37", danger: "#cf222e", secondary: "#6e7781", link: "#bc4c00" },
  { name: "midnight-pro",    primary: "#58a6ff", info: "#388bfd", warning: "#d29922", success: "#3fb950", danger: "#f85149", secondary: "#8b949e", link: "#58a6ff" },
  { name: "arctic-frost",    primary: "#218bff", info: "#54aeff", warning: "#d4a72c", success: "#4ac26b", danger: "#ff8182", secondary: "#768390", link: "#218bff" },
  { name: "coral-reef",      primary: "#e5534b", info: "#539bf5", warning: "#c69026", success: "#57ab5a", danger: "#e5534b", secondary: "#768390", link: "#e5534b" },
  { name: "lavender-mist",   primary: "#8250df", info: "#0969da", warning: "#9a6700", success: "#1a7f37", danger: "#cf222e", secondary: "#6e7781", link: "#8250df" },
  { name: "slate-modern",    primary: "#6e7781", info: "#0969da", warning: "#9a6700", success: "#1a7f37", danger: "#cf222e", secondary: "#57606a", link: "#6e7781" },
  { name: "ember-glow",      primary: "#cf222e", info: "#0969da", warning: "#9a6700", success: "#1a7f37", danger: "#a40e26", secondary: "#6e7781", link: "#cf222e" },
  { name: "sage-garden",     primary: "#2da44e", info: "#0969da", warning: "#bf8700", success: "#1a7f37", danger: "#cf222e", secondary: "#57606a", link: "#2da44e" },
  { name: "twilight-haze",   primary: "#a475f9", info: "#6cb6ff", warning: "#daaa3f", success: "#57ab5a", danger: "#f47067", secondary: "#8b949e", link: "#a475f9" },
  { name: "golden-hour",     primary: "#9a6700", info: "#0969da", warning: "#bf8700", success: "#1a7f37", danger: "#cf222e", secondary: "#6e7781", link: "#9a6700" },
  { name: "steel-blue",      primary: "#0550ae", info: "#0969da", warning: "#9a6700", success: "#1a7f37", danger: "#cf222e", secondary: "#6e7781", link: "#0550ae" },
  { name: "autumn-harvest",  primary: "#bc4c00", info: "#9a6700", warning: "#bf8700", success: "#2da44e", danger: "#cf222e", secondary: "#57606a", link: "#bc4c00" },
  { name: "ice-crystal",     primary: "#54aeff", info: "#218bff", warning: "#d4a72c", success: "#4ac26b", danger: "#ff8182", secondary: "#636c76", link: "#54aeff" },
  { name: "rose-quartz",     primary: "#bf3989", info: "#0969da", warning: "#9a6700", success: "#1a7f37", danger: "#cf222e", secondary: "#6e7781", link: "#bf3989" },
  { name: "deep-space",      primary: "#388bfd", info: "#316dca", warning: "#c69026", success: "#46954a", danger: "#e5534b", secondary: "#768390", link: "#388bfd" },
  { name: "mint-fresh",      primary: "#1b7c83", info: "#0969da", warning: "#9a6700", success: "#1a7f37", danger: "#cf222e", secondary: "#6e7781", link: "#1b7c83" },
  { name: "cherry-blossom",  primary: "#cf222e", info: "#bf3989", warning: "#9a6700", success: "#1a7f37", danger: "#a40e26", secondary: "#6e7781", link: "#cf222e" },
  { name: "nordic-night",    primary: "#6cb6ff", info: "#539bf5", warning: "#daaa3f", success: "#6bc46d", danger: "#f47067", secondary: "#8b949e", link: "#6cb6ff" },
  { name: "terracotta",      primary: "#bc4c00", info: "#cf222e", warning: "#9a6700", success: "#2da44e", danger: "#a40e26", secondary: "#57606a", link: "#bc4c00" },
  { name: "moonstone",       primary: "#768390", info: "#539bf5", warning: "#c69026", success: "#57ab5a", danger: "#e5534b", secondary: "#636c76", link: "#768390" },
  { name: "electric-violet", primary: "#8250df", info: "#a475f9", warning: "#d29922", success: "#3fb950", danger: "#f85149", secondary: "#8b949e", link: "#8250df" },
  { name: "sahara-sand",     primary: "#9a6700", info: "#bc4c00", warning: "#bf8700", success: "#2da44e", danger: "#cf222e", secondary: "#57606a", link: "#9a6700" }
];

function diagramDef(t) {
  return `flowchart TD
    user["User Request"] --> api["API Gateway"]
    api --> auth{"Authenticate"}
    auth -->|Pass| service["Service"]
    auth -->|Fail| error["Error Response"]
    service --> db[("Database")]
    db --> response["Success Response"]
    classDef primary fill:${t.primary},stroke:${t.primary},color:#fff
    classDef info fill:${t.info},stroke:${t.info},color:#fff
    classDef warning fill:${t.warning},stroke:${t.warning},color:#fff
    classDef success fill:${t.success},stroke:${t.success},color:#fff
    classDef danger fill:${t.danger},stroke:${t.danger},color:#fff
    classDef secondary fill:${t.secondary},stroke:${t.secondary},color:#fff
    class user primary
    class api info
    class auth warning
    class service success
    class error danger
    class db secondary`;
}

function classDefsText(t) {
  return `classDef primary  ${t.primary}  |  info  ${t.info}  |  warning  ${t.warning}  |  success  ${t.success}  |  danger  ${t.danger}  |  secondary  ${t.secondary}`;
}

mermaid.initialize({ startOnLoad: false, theme: 'neutral', securityLevel: 'loose' });

async function renderAll() {
  const gallery = document.getElementById('gallery');
  for (let i = 0; i < themes.length; i++) {
    const t = themes[i];
    const def = diagramDef(t);

    const card = document.createElement('div');
    card.className = 'theme-card';
    card.innerHTML = `<div class="theme-name">${i + 1}. ${t.name}</div>
      <div class="theme-meta">${classDefsText(t)}</div>
      <div class="previews">
        <div class="preview preview-light">
          <div class="preview-label">Light background</div>
          <div id="light-${i}"></div>
        </div>
        <div class="preview preview-dark">
          <div class="preview-label">Dark background</div>
          <div id="dark-${i}"></div>
        </div>
      </div>`;
    gallery.appendChild(card);

    try {
      const lightResult = await mermaid.render(`svg-light-${i}`, def);
      document.getElementById(`light-${i}`).innerHTML = lightResult.svg;
    } catch (e) {
      document.getElementById(`light-${i}`).textContent = 'Render error: ' + e.message;
    }
    try {
      const darkResult = await mermaid.render(`svg-dark-${i}`, def);
      document.getElementById(`dark-${i}`).innerHTML = darkResult.svg;
    } catch (e) {
      document.getElementById(`dark-${i}`).textContent = 'Render error: ' + e.message;
    }
  }
}
renderAll();
</script>
</body>
</html>
HTMLEOF

echo "Generated: $OUTPUT_FILE"

# Open in default browser
if command -v open &>/dev/null; then
  open "$OUTPUT_FILE"
elif command -v xdg-open &>/dev/null; then
  xdg-open "$OUTPUT_FILE"
else
  echo "Open manually: $OUTPUT_FILE"
fi
