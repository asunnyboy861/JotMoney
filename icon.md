# App Icon

## Generation Prompt

```
JotMoney iOS app icon, a bold mint green pen nib curving into a J shape beside a single gold coin,
large dominant subject filling the entire square frame, edge-to-edge composition, no padding,
no margin, no empty space, no transparent edges, solid near-black background, flat design,
simple bold shapes, professional, clean, no text, no words, no letters, square format, 1024x1024
```

## Generated Image

- **File**: `JotMoney/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png`
- **Style**: Flat, bold mint-green nib/coin mark on near-black (#0B0F0E), centered at ~90% of frame
- **API**: Agnes Image 2.1 Flash (primary)
- **Attempts**: 1 (succeeded on first attempt, no Wanx fallback needed)
- **Post-processing**: alpha trimmed, rescaled to 920px subject, composited on opaque background, converted to RGB

## Asset Catalog

- **AppIcon.appiconset configured**: ✅ (single 1024×1024 universal entry, modern Xcode format)
- **All sizes generated**: ✅ (Xcode derives all sizes from the 1024 source)
- **Alpha channel**: none (`sips -g hasAlpha` → `no`)

## Brand Colors

| Role | Hex |
|---|---|
| Brand / success (mint) | `#00C48C` |
| Background | `#0B0F0E` |
| Elevated surface | `#151A18` |
| Warning | `#FFB020` |
| Danger | `#FF5A5F` |
