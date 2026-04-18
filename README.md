# StickyImage

A tiny macOS app that pins images as borderless, always-on-top, resizable
floating windows — like sticky notes for reference images.

## Build

```sh
./build.sh
```

Produces `StickyImage.app` next to `build.sh`. Move it to `/Applications` once
so Launch Services registers it for "Open With".

## Open an image

- `⌘O` — open a file picker
- `⌘V` / `⌘N` — paste image (or file) from clipboard as a new window
- Drag image files onto the Dock icon or onto an existing window
- Finder → right-click an image → **Open With ▸ StickyImage**
- Terminal: `open -a StickyImage some.png` or `open -a StickyImage a.png b.jpg`

## Use

- **Move** — drag anywhere on the image
- **Resize** — drag a corner (aspect ratio locked to the image)
- **Free resize** — hold **Shift** while dragging a corner
- **Opacity** — scroll wheel over the image
- **Hover** — ✕ close, 📌 toggle always-on-top, ⋯ menu
- **Right-click** — Copy Image, Save As…, Reveal in Finder, Always on Top,
  All Spaces, Reset Opacity, Close
- **⌘W** — close the focused window

Windows float above other apps and follow you across Spaces by default.

## Requirements

macOS 13+, Xcode 16 / Swift 6 to build.
