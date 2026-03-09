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
  h1 { margin-bottom: 4px; }
  h2 { color: #555; margin-top: 32px; margin-bottom: 16px; border-bottom: 2px solid #ddd; padding-bottom: 8px; }
  .subtitle { color: #666; margin-bottom: 24px; }
  .theme-card { background: white; border-radius: 8px; padding: 16px; margin-bottom: 24px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
  .theme-name { font-size: 18px; font-weight: bold; margin-bottom: 4px; }
  .theme-source { font-size: 12px; color: #888; margin-bottom: 12px; }
  .theme-meta { font-size: 11px; color: #666; margin-bottom: 12px; font-family: monospace; display: flex; gap: 8px; flex-wrap: wrap; }
  .color-chip { display: inline-flex; align-items: center; gap: 4px; padding: 2px 8px; border-radius: 4px; font-size: 11px; }
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
<p class="subtitle">24 themes from popular editors, rendered on GitHub light (#fff) and dark (#0d1117) backgrounds</p>
<div id="gallery"></div>
<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
<script>
const themes = [
  // Light Themes
  { name: "Ayu Light",           mode: "light", source: "ayu-theme",        primary: "#FF9940", secondary: "#8a9199", success: "#6d9200", warning: "#c98e3a", danger: "#f07171", info: "#469ab8", link: "#5C6773" },
  { name: "Catppuccin Latte",    mode: "light", source: "catppuccin",       primary: "#1e66f5", secondary: "#6c6f83", success: "#37882a", warning: "#bf7a18", danger: "#d20f39", info: "#1a8a9e", link: "#7c7f93" },
  { name: "Everforest Light",    mode: "light", source: "sainnhe/everforest", primary: "#5c6a72", secondary: "#7e8c84", success: "#749100", warning: "#bf8800", danger: "#f85552", info: "#3a94c5", link: "#939f91" },
  { name: "Gruvbox Light",       mode: "light", source: "morhetz/gruvbox",  primary: "#458588", secondary: "#7e7367", success: "#7d8215", warning: "#b5811a", danger: "#cc241d", info: "#5a8a5f", link: "#928374" },
  { name: "Rose Pine Dawn",      mode: "light", source: "rose-pine",        primary: "#907aa9", secondary: "#817c8e", success: "#4a8088", warning: "#c9852a", danger: "#b4637a", info: "#286983", link: "#9893a5" },
  { name: "Solarized Light",     mode: "light", source: "altercation/solarized", primary: "#268bd2", secondary: "#7d8d8d", success: "#6f7f00", warning: "#946f00", danger: "#dc322f", info: "#2aa198", link: "#93a1a1" },
  { name: "Tokyo Night Light",   mode: "light", source: "enkia/tokyo-night", primary: "#34548a", secondary: "#7f8490", success: "#485e30", warning: "#8f5e15", danger: "#8c4351", info: "#0f4b6e", link: "#9699a3" },
  // Dark Themes
  { name: "Ayu Dark",            mode: "dark",  source: "ayu-theme",        primary: "#E6B450", secondary: "#5C6773", success: "#AAD94C", warning: "#FFB454", danger: "#F07178", info: "#59C2FF", link: "#5C6773" },
  { name: "Ayu Mirage",          mode: "dark",  source: "ayu-theme",        primary: "#FFCC66", secondary: "#707A8C", success: "#BAE67E", warning: "#FFD580", danger: "#F28779", info: "#73D0FF", link: "#707A8C" },
  { name: "Catppuccin Mocha",    mode: "dark",  source: "catppuccin",       primary: "#89b4fa", secondary: "#6c7086", success: "#a6e3a1", warning: "#f9e2af", danger: "#f38ba8", info: "#89dceb", link: "#6c7086" },
  { name: "Dracula",             mode: "dark",  source: "dracula/dracula-theme", primary: "#bd93f9", secondary: "#6272a4", success: "#50fa7b", warning: "#f1fa8c", danger: "#ff5555", info: "#8be9fd", link: "#6272a4" },
  { name: "Everforest Dark",     mode: "dark",  source: "sainnhe/everforest", primary: "#a7c080", secondary: "#859289", success: "#a7c080", warning: "#dbbc7f", danger: "#e67e80", info: "#7fbbb3", link: "#859289" },
  { name: "Gruvbox Dark",        mode: "dark",  source: "morhetz/gruvbox",  primary: "#83a598", secondary: "#928374", success: "#b8bb26", warning: "#fabd2f", danger: "#fb4934", info: "#8ec07c", link: "#928374" },
  { name: "Horizon Dark",        mode: "dark",  source: "jolaleye/horizon-theme", primary: "#E95678", secondary: "#6C6F93", success: "#29D398", warning: "#FAB795", danger: "#E95678", info: "#25B0BC", link: "#6C6F93" },
  { name: "Kanagawa",            mode: "dark",  source: "rebelot/kanagawa.nvim", primary: "#7E9CD8", secondary: "#727169", success: "#98BB6C", warning: "#E6C384", danger: "#FF5D62", info: "#7FB4CA", link: "#727169" },
  { name: "Material Dark",       mode: "dark",  source: "material-theme",   primary: "#82AAFF", secondary: "#546E7A", success: "#C3E88D", warning: "#FFCB6B", danger: "#F07178", info: "#89DDFF", link: "#546E7A" },
  { name: "Monokai Pro",         mode: "dark",  source: "monokai.pro",      primary: "#FFD866", secondary: "#727072", success: "#A9DC76", warning: "#FFD866", danger: "#FF6188", info: "#78DCE8", link: "#727072" },
  { name: "Nord",                mode: "dark",  source: "nordtheme",        primary: "#88C0D0", secondary: "#4C566A", success: "#A3BE8C", warning: "#EBCB8B", danger: "#BF616A", info: "#81A1C1", link: "#4C566A" },
  { name: "One Dark",            mode: "dark",  source: "Binaryify/OneDark-Pro", primary: "#61AFEF", secondary: "#5C6370", success: "#98C379", warning: "#E5C07B", danger: "#E06C75", info: "#56B6C2", link: "#5C6370" },
  { name: "Palenight",           mode: "dark",  source: "material-theme",   primary: "#82AAFF", secondary: "#676E95", success: "#C3E88D", warning: "#FFCB6B", danger: "#F07178", info: "#89DDFF", link: "#676E95" },
  { name: "Rose Pine",           mode: "dark",  source: "rose-pine",        primary: "#c4a7e7", secondary: "#6e6a86", success: "#9ccfd8", warning: "#f6c177", danger: "#eb6f92", info: "#31748f", link: "#6e6a86" },
  { name: "Synthwave '84",       mode: "dark",  source: "robb0wen/synthwave-vscode", primary: "#FF7EDB", secondary: "#495495", success: "#72F1B8", warning: "#FEDE5D", danger: "#FE4450", info: "#36F9F6", link: "#495495" },
  { name: "Tokyo Night",         mode: "dark",  source: "enkia/tokyo-night", primary: "#7AA2F7", secondary: "#565F89", success: "#9ECE6A", warning: "#E0AF68", danger: "#F7768E", info: "#7DCFFF", link: "#565F89" },
  { name: "Tokyo Night Storm",   mode: "dark",  source: "enkia/tokyo-night", primary: "#7AA2F7", secondary: "#565F89", success: "#9ECE6A", warning: "#E0AF68", danger: "#F7768E", info: "#7DCFFF", link: "#565F89" }
];

// Determine text color based on fill luminance
function textColor(hex) {
  const r = parseInt(hex.slice(1,3), 16);
  const g = parseInt(hex.slice(3,5), 16);
  const b = parseInt(hex.slice(5,7), 16);
  const lum = (0.299*r + 0.587*g + 0.114*b) / 255;
  return lum > 0.55 ? "#1a1a2e" : "#ffffff";
}

function diagramDef(t) {
  return `flowchart TD
    user["User Request"] --> api["API Gateway"]
    api --> auth{"Authenticate"}
    auth -->|Pass| service["Service"]
    auth -->|Fail| error["Error Response"]
    service --> db[("Database")]
    db --> response["Success Response"]
    classDef primary fill:${t.primary},stroke:${t.primary},color:${textColor(t.primary)}
    classDef info fill:${t.info},stroke:${t.info},color:${textColor(t.info)}
    classDef warning fill:${t.warning},stroke:${t.warning},color:${textColor(t.warning)}
    classDef success fill:${t.success},stroke:${t.success},color:${textColor(t.success)}
    classDef danger fill:${t.danger},stroke:${t.danger},color:${textColor(t.danger)}
    classDef secondary fill:${t.secondary},stroke:${t.secondary},color:${textColor(t.secondary)}
    linkStyle default stroke:${t.link},stroke-width:2px
    class user primary
    class api info
    class auth warning
    class service success
    class error danger
    class db secondary
    class response success`;
}

function colorChips(t) {
  const roles = ['primary','info','warning','success','danger','secondary'];
  return roles.map(r => {
    const bg = t[r];
    const fg = textColor(bg);
    return `<span class="color-chip" style="background:${bg};color:${fg}">${r} ${bg}</span>`;
  }).join('');
}

mermaid.initialize({ startOnLoad: false, theme: 'neutral', securityLevel: 'loose' });

async function renderAll() {
  const gallery = document.getElementById('gallery');
  let currentMode = '';

  for (let i = 0; i < themes.length; i++) {
    const t = themes[i];

    // Add section headers
    if (t.mode !== currentMode) {
      currentMode = t.mode;
      const h2 = document.createElement('h2');
      h2.textContent = currentMode === 'light' ? 'Light Themes' : 'Dark Themes';
      gallery.appendChild(h2);
    }

    const def = diagramDef(t);
    const card = document.createElement('div');
    card.className = 'theme-card';
    card.innerHTML = `<div class="theme-name">${i + 1}. ${t.name}</div>
      <div class="theme-source">${t.mode} &middot; ${t.source}</div>
      <div class="theme-meta">${colorChips(t)}</div>
      <div class="previews">
        <div class="preview preview-light">
          <div class="preview-label">GitHub Light</div>
          <div id="light-${i}"></div>
        </div>
        <div class="preview preview-dark">
          <div class="preview-label">GitHub Dark</div>
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
