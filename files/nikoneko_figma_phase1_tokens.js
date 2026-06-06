// NIKO NEKO — Figma Plugin
// Phase 1: Design Tokens, Color Styles, Text Styles

const THEMES = {
  obsidian: {
    name: "Obsidian / 黑曜",
    bg:         { r:0.039, g:0.039, b:0.039 },
    surface:    { r:0.078, g:0.078, b:0.078 },
    card:       { r:0.067, g:0.067, b:0.067 },
    text:       { r:0.941, g:0.929, b:0.910 },
    textDim:    { r:0.180, g:0.180, b:0.180 },
    textMid:    { r:0.400, g:0.400, b:0.400 },
    accent:     { r:0.941, g:0.929, b:0.910 },
    accentMid:  { r:0.533, g:0.533, b:0.533 },
    accentDim:  { r:0.118, g:0.118, b:0.118 },
    bar0:       { r:0.102, g:0.102, b:0.102 },
    bar1:       { r:0.118, g:0.227, b:0.118 },
    bar2:       { r:0.180, g:0.361, b:0.180 },
    bar3:       { r:0.290, g:0.549, b:0.290 },
    bar4:       { r:0.427, g:0.729, b:0.427 },
  },
  paper: {
    name: "Paper / 白紙",
    bg:         { r:1.000, g:1.000, b:1.000 },
    surface:    { r:0.961, g:0.961, b:0.961 },
    card:       { r:0.922, g:0.922, b:0.922 },
    text:       { r:0.067, g:0.067, b:0.067 },
    textDim:    { r:0.667, g:0.667, b:0.667 },
    textMid:    { r:0.333, g:0.333, b:0.333 },
    accent:     { r:0.067, g:0.067, b:0.067 },
    accentMid:  { r:0.333, g:0.333, b:0.333 },
    accentDim:  { r:0.867, g:0.867, b:0.867 },
    bar0:       { r:0.910, g:0.910, b:0.910 },
    bar1:       { r:0.800, g:0.800, b:0.800 },
    bar2:       { r:0.667, g:0.667, b:0.667 },
    bar3:       { r:0.333, g:0.333, b:0.333 },
    bar4:       { r:0.067, g:0.067, b:0.067 },
  },
  limestone: {
    name: "Limestone / 石灰岩",
    bg:         { r:0.957, g:0.941, b:0.918 },
    surface:    { r:0.925, g:0.910, b:0.878 },
    card:       { r:0.894, g:0.875, b:0.839 },
    text:       { r:0.110, g:0.102, b:0.086 },
    textDim:    { r:0.722, g:0.690, b:0.627 },
    textMid:    { r:0.533, g:0.502, b:0.439 },
    accent:     { r:0.235, g:0.220, b:0.188 },
    accentMid:  { r:0.565, g:0.502, b:0.439 },
    accentDim:  { r:0.816, g:0.784, b:0.722 },
    bar0:       { r:0.894, g:0.875, b:0.839 },
    bar1:       { r:0.800, g:0.769, b:0.706 },
    bar2:       { r:0.659, g:0.596, b:0.502 },
    bar3:       { r:0.502, g:0.408, b:0.314 },
    bar4:       { r:0.235, g:0.220, b:0.188 },
  },
  zinc: {
    name: "Zinc / 鋅 (GitHub)",
    bg:         { r:0.051, g:0.067, b:0.090 },
    surface:    { r:0.086, g:0.106, b:0.137 },
    card:       { r:0.129, g:0.149, b:0.176 },
    text:       { r:0.902, g:0.929, b:0.953 },
    textDim:    { r:0.188, g:0.212, b:0.239 },
    textMid:    { r:0.545, g:0.580, b:0.620 },
    accent:     { r:0.345, g:0.651, b:1.000 },
    accentMid:  { r:0.475, g:0.753, b:1.000 },
    accentDim:  { r:0.051, g:0.165, b:0.290 },
    bar0:       { r:0.086, g:0.106, b:0.137 },
    bar1:       { r:0.039, g:0.165, b:0.102 },
    bar2:       { r:0.000, g:0.427, b:0.196 },
    bar3:       { r:0.149, g:0.651, b:0.255 },
    bar4:       { r:0.224, g:0.827, b:0.325 },
  },
  grove: {
    name: "Grove / 林間",
    bg:         { r:0.961, g:0.925, b:0.843 },
    surface:    { r:0.922, g:0.886, b:0.804 },
    card:       { r:0.867, g:0.831, b:0.737 },
    text:       { r:0.208, g:0.208, b:0.208 },
    textDim:    { r:0.373, g:0.373, b:0.373 },
    textMid:    { r:0.408, g:0.651, b:0.490 },
    accent:     { r:0.561, g:0.749, b:0.624 },
    accentMid:  { r:0.141, g:0.380, b:0.231 },
    accentDim:  { r:0.784, g:0.867, b:0.816 },
    bar0:       { r:0.784, g:0.867, b:0.816 },
    bar1:       { r:0.596, g:0.784, b:0.659 },
    bar2:       { r:0.408, g:0.722, b:0.502 },
    bar3:       { r:0.141, g:0.380, b:0.231 },
    bar4:       { r:0.945, g:0.561, b:0.004 },
  },
  moss: {
    name: "Moss & Amber / 苔蘚琥珀",
    bg:         { r:0.867, g:0.867, b:0.867 },
    surface:    { r:0.933, g:0.933, b:0.933 },
    card:       { r:0.894, g:0.894, b:0.894 },
    text:       { r:0.161, g:0.145, b:0.141 },
    textDim:    { r:0.471, g:0.443, b:0.424 },
    textMid:    { r:0.396, g:0.533, b:0.392 },
    accent:     { r:0.396, g:0.533, b:0.392 },
    accentMid:  { r:0.290, g:0.408, b:0.282 },
    accentDim:  { r:0.718, g:0.718, b:0.541 },
    bar0:       { r:0.718, g:0.718, b:0.541 },
    bar1:       { r:0.604, g:0.667, b:0.439 },
    bar2:       { r:0.396, g:0.533, b:0.392 },
    bar3:       { r:0.290, g:0.408, b:0.282 },
    bar4:       { r:0.737, g:0.424, b:0.145 },
  },
  mocha: {
    name: "Mocha Mousse / 摩卡慕斯",
    bg:         { r:0.102, g:0.071, b:0.063 },
    surface:    { r:0.141, g:0.102, b:0.078 },
    card:       { r:0.118, g:0.082, b:0.063 },
    text:       { r:0.910, g:0.835, b:0.753 },
    textDim:    { r:0.290, g:0.188, b:0.125 },
    textMid:    { r:0.690, g:0.502, b:0.376 },
    accent:     { r:0.784, g:0.584, b:0.416 },
    accentMid:  { r:0.627, g:0.439, b:0.282 },
    accentDim:  { r:0.188, g:0.118, b:0.063 },
    bar0:       { r:0.141, g:0.102, b:0.078 },
    bar1:       { r:0.290, g:0.173, b:0.094 },
    bar2:       { r:0.478, g:0.282, b:0.157 },
    bar3:       { r:0.690, g:0.439, b:0.251 },
    bar4:       { r:0.784, g:0.584, b:0.416 },
  },
  seafloor: {
    name: "Seafloor / 海床",
    bg:         { r:0.337, g:0.443, b:0.537 },
    surface:    { r:0.482, g:0.561, b:0.631 },
    card:       { r:0.416, g:0.502, b:0.596 },
    text:       { r:0.976, g:0.976, b:0.976 },
    textDim:    { r:0.863, g:0.863, b:0.863 },
    textMid:    { r:0.812, g:0.725, b:0.592 },
    accent:     { r:0.969, g:0.749, b:0.478 },
    accentMid:  { r:0.910, g:0.627, b:0.314 },
    accentDim:  { r:0.243, g:0.349, b:0.459 },
    bar0:       { r:0.243, g:0.349, b:0.459 },
    bar1:       { r:0.353, g:0.471, b:0.596 },
    bar2:       { r:0.482, g:0.561, b:0.631 },
    bar3:       { r:0.969, g:0.749, b:0.478 },
    bar4:       { r:0.812, g:0.725, b:0.592 },
  },
  navy: {
    name: "Deep Navy / 深海藍",
    bg:         { r:0.059, g:0.110, b:0.180 },
    surface:    { r:0.122, g:0.169, b:0.243 },
    card:       { r:0.165, g:0.212, b:0.314 },
    text:       { r:1.000, g:1.000, b:1.000 },
    textDim:    { r:0.878, g:0.878, b:0.878 },
    textMid:    { r:0.302, g:0.392, b:0.553 },
    accent:     { r:0.675, g:0.761, b:0.937 },
    accentMid:  { r:0.239, g:0.353, b:0.502 },
    accentDim:  { r:0.122, g:0.227, b:0.373 },
    bar0:       { r:0.122, g:0.227, b:0.373 },
    bar1:       { r:0.180, g:0.314, b:0.502 },
    bar2:       { r:0.302, g:0.392, b:0.553 },
    bar3:       { r:0.675, g:0.761, b:0.937 },
    bar4:       { r:0.808, g:0.910, b:1.000 },
  },
  lavender: {
    name: "Lavender Fog / 薰衣草霧",
    bg:         { r:0.961, g:0.953, b:0.969 },
    surface:    { r:0.914, g:0.894, b:0.929 },
    card:       { r:0.867, g:0.839, b:0.894 },
    text:       { r:0.290, g:0.290, b:0.290 },
    textDim:    { r:0.529, g:0.529, b:0.529 },
    textMid:    { r:0.604, g:0.451, b:0.710 },
    accent:     { r:0.545, g:0.373, b:0.749 },
    accentMid:  { r:0.380, g:0.224, b:0.561 },
    accentDim:  { r:0.839, g:0.776, b:0.882 },
    bar0:       { r:0.839, g:0.776, b:0.882 },
    bar1:       { r:0.769, g:0.659, b:0.847 },
    bar2:       { r:0.604, g:0.451, b:0.710 },
    bar3:       { r:0.545, g:0.373, b:0.749 },
    bar4:       { r:0.380, g:0.224, b:0.561 },
  },
  midnight: {
    name: "Midnight Mauve / 午夜藕色",
    bg:         { r:0.082, g:0.098, b:0.192 },
    surface:    { r:0.145, g:0.157, b:0.255 },
    card:       { r:0.180, g:0.192, b:0.314 },
    text:       { r:0.906, g:0.820, b:0.733 },
    textDim:    { r:0.518, g:0.478, b:0.525 },
    textMid:    { r:0.627, g:0.588, b:0.647 },
    accent:     { r:0.627, g:0.588, b:0.635 },
    accentMid:  { r:0.784, g:0.706, b:0.753 },
    accentDim:  { r:0.275, g:0.243, b:0.294 },
    bar0:       { r:0.180, g:0.192, b:0.314 },
    bar1:       { r:0.275, g:0.243, b:0.294 },
    bar2:       { r:0.439, g:0.376, b:0.439 },
    bar3:       { r:0.627, g:0.565, b:0.635 },
    bar4:       { r:0.906, g:0.820, b:0.733 },
  },
  teal: {
    name: "Teal & Coral / 青與珊瑚",
    bg:         { r:0.949, g:0.937, b:0.914 },
    surface:    { r:0.910, g:0.898, b:0.875 },
    card:       { r:0.867, g:0.855, b:0.831 },
    text:       { r:0.200, g:0.200, b:0.200 },
    textDim:    { r:0.361, g:0.361, b:0.361 },
    textMid:    { r:0.000, g:0.545, b:0.475 },
    accent:     { r:0.000, g:0.659, b:0.588 },
    accentMid:  { r:0.000, g:0.420, b:0.376 },
    accentDim:  { r:0.627, g:0.847, b:0.816 },
    bar0:       { r:0.627, g:0.847, b:0.816 },
    bar1:       { r:0.314, g:0.753, b:0.690 },
    bar2:       { r:0.000, g:0.659, b:0.588 },
    bar3:       { r:0.000, g:0.420, b:0.376 },
    bar4:       { r:1.000, g:0.420, b:0.420 },
  },
  blush: {
    name: "Blush Garden / 胭脂花園",
    bg:         { r:0.988, g:0.933, b:0.961 },
    surface:    { r:1.000, g:1.000, b:1.000 },
    card:       { r:0.980, g:0.851, b:0.902 },
    text:       { r:0.161, g:0.145, b:0.141 },
    textDim:    { r:0.471, g:0.443, b:0.424 },
    textMid:    { r:0.380, g:0.753, b:0.749 },
    accent:     { r:0.380, g:0.753, b:0.749 },
    accentMid:  { r:0.227, g:0.596, b:0.596 },
    accentDim:  { r:0.733, g:0.871, b:0.839 },
    bar0:       { r:0.980, g:0.851, b:0.902 },
    bar1:       { r:1.000, g:0.714, b:0.725 },
    bar2:       { r:0.910, g:0.565, b:0.565 },
    bar3:       { r:0.380, g:0.753, b:0.749 },
    bar4:       { r:0.227, g:0.596, b:0.596 },
  },
};

const TEXT_STYLES = [
  { name: "Timer/Display", size: 72, weight: 200, letterSpacing: -3 },
  { name: "Timer/Seconds", size: 13, weight: 300, letterSpacing: 0 },
  { name: "Hero/Number",   size: 46, weight: 200, letterSpacing: -2 },
  { name: "Hero/Unit",     size: 11, weight: 400, letterSpacing: 0 },
  { name: "Body/Primary",  size: 13, weight: 400, letterSpacing: 0 },
  { name: "Body/Secondary",size: 11, weight: 400, letterSpacing: 0 },
  { name: "Caption/Label", size: 9,  weight: 400, letterSpacing: 0.08 },
  { name: "Caption/Micro", size: 7,  weight: 400, letterSpacing: 0.06 },
  { name: "Card/Value",    size: 14, weight: 200, letterSpacing: -0.3 },
  { name: "Card/Label",    size: 6.5, weight: 400, letterSpacing: 0.05 },
  { name: "Nav/Title",     size: 13, weight: 400, letterSpacing: 0.04 },
  { name: "Tab/Label",     size: 10, weight: 400, letterSpacing: 0.03 },
];

async function run() {
  figma.skipInvisibleInstanceChildren = true;

  let created = 0;
  let skipped = 0;

  // ── 1. Paint Styles ──────────────────────────────
  for (const [themeKey, theme] of Object.entries(THEMES)) {
    const tokens = [
      "bg", "surface", "card",
      "text", "textDim", "textMid",
      "accent", "accentMid", "accentDim",
      "bar0", "bar1", "bar2", "bar3", "bar4"
    ];

    for (const token of tokens) {
      const styleName = `${theme.name}/${token}`;
      const existing = figma.getLocalPaintStyles().find(s => s.name === styleName);
      if (existing) { skipped++; continue; }

      const style = figma.createPaintStyle();
      style.name = styleName;
      style.paints = [{
        type: "SOLID",
        color: theme[token],
        opacity: 1
      }];
      created++;
    }
  }

  // ── 2. Text Styles ───────────────────────────────
  for (const ts of TEXT_STYLES) {
    const existing = figma.getLocalTextStyles().find(s => s.name === ts.name);
    if (existing) { skipped++; continue; }

    const style = figma.createTextStyle();
    style.name = ts.name;
    style.fontSize = ts.size;
    style.letterSpacing = { value: ts.letterSpacing, unit: "PERCENT" };
    // Note: fontWeight set via fontName
    const weight = ts.weight === 200 ? "Thin" :
                   ts.weight === 300 ? "Light" :
                   ts.weight === 500 ? "Medium" : "Regular";
    try {
      await figma.loadFontAsync({ family: "SF Pro Display", style: weight });
      style.fontName = { family: "SF Pro Display", style: weight };
    } catch {
      try {
        await figma.loadFontAsync({ family: "Inter", style: weight === "Thin" ? "Thin" : weight === "Light" ? "Light" : "Regular" });
        style.fontName = { family: "Inter", style: weight === "Thin" ? "Thin" : weight === "Light" ? "Light" : "Regular" };
      } catch {
        await figma.loadFontAsync({ family: "Roboto", style: "Regular" });
        style.fontName = { family: "Roboto", style: "Regular" };
      }
    }
    created++;
  }

  // ── 3. Token Reference Frame ─────────────────────
  await figma.loadFontAsync({ family: "Inter", style: "Regular" });
  await figma.loadFontAsync({ family: "Inter", style: "Bold" });

  const page = figma.currentPage;

  // Remove old token frame if exists
  const oldFrame = page.findOne(n => n.name === "🎨 NIKO NEKO — Design Tokens");
  if (oldFrame) oldFrame.remove();

  const masterFrame = figma.createFrame();
  masterFrame.name = "🎨 NIKO NEKO — Design Tokens";
  masterFrame.resize(1800, 200);
  masterFrame.fills = [{ type: "SOLID", color: { r:0.06, g:0.06, b:0.06 } }];
  masterFrame.x = 0;
  masterFrame.y = 0;
  masterFrame.cornerRadius = 16;
  masterFrame.clipsContent = false;

  // Title
  const titleText = figma.createText();
  await figma.loadFontAsync({ family: "Inter", style: "Bold" });
  titleText.fontName = { family: "Inter", style: "Bold" };
  titleText.characters = "NIKO NEKO — Design Tokens";
  titleText.fontSize = 18;
  titleText.fills = [{ type: "SOLID", color: { r:0.6, g:0.6, b:0.6 } }];
  titleText.x = 32;
  titleText.y = 28;
  masterFrame.appendChild(titleText);

  const subtitleText = figma.createText();
  subtitleText.fontName = { family: "Inter", style: "Regular" };
  subtitleText.characters = `${created} styles created · ${skipped} already existed · 13 themes · 12 text styles`;
  subtitleText.fontSize = 12;
  subtitleText.fills = [{ type: "SOLID", color: { r:0.35, g:0.35, b:0.35 } }];
  subtitleText.x = 32;
  subtitleText.y = 56;
  masterFrame.appendChild(subtitleText);

  // Swatch row per theme
  let swatchX = 32;
  for (const [, theme] of Object.entries(THEMES)) {
    const swatchGroup = figma.createFrame();
    swatchGroup.name = theme.name;
    swatchGroup.resize(110, 110);
    swatchGroup.fills = [];
    swatchGroup.x = swatchX;
    swatchGroup.y = 84;
    swatchGroup.clipsContent = false;

    const label = figma.createText();
    label.fontName = { family: "Inter", style: "Regular" };
    label.characters = theme.name.split("/")[1]?.trim() || theme.name;
    label.fontSize = 8;
    label.fills = [{ type: "SOLID", color: { r:0.35, g:0.35, b:0.35 } }];
    label.x = 0;
    label.y = 0;
    swatchGroup.appendChild(label);

    const swatchTokens = ["bg","surface","card","accent","accentMid","bar1","bar2","bar3","bar4"];
    swatchTokens.forEach((token, idx) => {
      const swatch = figma.createRectangle();
      swatch.resize(10, 10);
      swatch.x = idx * 12;
      swatch.y = 16;
      swatch.cornerRadius = 2;
      swatch.fills = [{ type: "SOLID", color: theme[token] }];
      swatchGroup.appendChild(swatch);
    });

    masterFrame.appendChild(swatchGroup);
    swatchX += 130;
  }

  masterFrame.resize(swatchX + 32, 210);

  figma.viewport.scrollAndZoomIntoView([masterFrame]);

  figma.notify(`✅ Done! ${created} styles created, ${skipped} skipped. Check the Assets panel.`);
  figma.closePlugin();
}

run().catch(err => {
  figma.notify("❌ Error: " + err.message);
  figma.closePlugin();
});
