# Copy Clip — brand assets

## Files

| File | Use for |
| --- | --- |
| `logo.svg` | Primary mark. Full-color, multi-tone. Chrome Web Store hero, marketing, README. |
| `logo-mono.svg` | Single-color variant on blue tile. Use where the multi-tone version would clash. |
| `logo-favicon.svg` | Simplified silhouette for 16/32/48 px. Ships as the extension icon. |

## Concept

Three offset rounded cards, slightly rotated — a **stack of clips**. Reads as "collection of copied items" at any size.

## Colors

| Token | Hex | Where |
| --- | --- | --- |
| Primary | `#2563EB` | Middle card, favicon tile, wordmark |
| Primary Dark | `#1E4FCC` | Bottom (rear) card, top-clip bar accent |
| Primary Light | `#4C82F2` | Top (front) card |
| Surface | `#FFFFFF` | Background tile, content lines on top card |

Corresponds to `AppTheme.primary` in `lib/util/theme.dart` — keep in sync if either changes.

## Geometry rules

- Tile corner radius: **22%** of tile size (macOS Big Sur / Fluent style)
- Cards: 78% width of tile, ~44% height, radius 8% of tile size
- Rotation: rear −10°, middle −2°, front +6° (creates the "fanned stack" feel)
- Content lines on front card: white, 3.1% tile-size height, 55% / 40% / 40% opacity for hierarchy

## Generating raster assets

The extension needs PNGs at 16, 32, 48, 128 px (MV3 manifest sizes) plus 192/512 for PWA.

From this folder:

```bash
# One-time: install rsvg-convert
brew install librsvg

# Extension icons (favicon variant for small sizes, full mark for 128+)
rsvg-convert -w 16  logo-favicon.svg  -o ../web/icons/icon-16.png
rsvg-convert -w 32  logo-favicon.svg  -o ../web/icons/icon-32.png
rsvg-convert -w 48  logo-favicon.svg  -o ../web/icons/icon-48.png
rsvg-convert -w 128 logo.svg          -o ../web/icons/copy-clip-128.png
rsvg-convert -w 192 logo.svg          -o ../web/icons/copy-clip-192.png
rsvg-convert -w 512 logo.svg          -o ../web/icons/copy-clip-512.png
```

## Clear-space rule

Leave at least **1 tile-radius** of clear space around the mark on any surface. Don't crop the tile — the rounded background *is* part of the mark.

## Don't

- Don't add a drop shadow to the mark (the tonal steps already convey depth)
- Don't recolor the cards individually
- Don't stretch or squash — always uniform scale
- Don't place the mono variant on a colored background other than the intended tile
