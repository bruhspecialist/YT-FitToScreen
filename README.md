# YouTube Fit to Screen

A tiny Chrome extension for ultrawide monitors. It adds a **Fit to screen** button to the YouTube player, just left of the fullscreen button. Clicking it:

1. Enters fullscreen, and
2. Scales the video up until it **fills the entire screen, cropping** the overflow (top/bottom for 16:9 video on a 21:9 monitor) — it never stretches or distorts the image.

Click the button again (or press <kbd>Esc</kbd> / exit fullscreen) to go back to normal.

## Install

1. Open `chrome://extensions` in Chrome (or Edge/Brave).
2. Enable **Developer mode** (toggle in the top-right corner).
3. Click **Load unpacked** and select this folder.
4. Open any YouTube video — the new button appears next to the fullscreen button.

## How it works

- `content.js` injects a `ytp-button` before YouTube's `.ytp-fullscreen-button` and re-injects it after YouTube's single-page navigations (via a MutationObserver and the `yt-navigate-finish` event).
- Toggling the button enters fullscreen through YouTube's own fullscreen control and adds a `ytfts-active` class to the player.
- `styles.css` then sizes the `<video>` element to `100vw × 100vh` with `object-fit: cover`, which crops instead of stretching.
- The crop only applies while fullscreen, so leaving fullscreen always restores the normal view.

## Files

| File | Purpose |
| --- | --- |
| `manifest.json` | Manifest V3 extension definition |
| `content.js` | Injects the button and handles the toggle |
| `styles.css` | The crop-to-fill rule and button styling |
