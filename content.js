(() => {
  'use strict';

  const BTN_CLASS = 'ytfts-button';
  const ACTIVE_CLASS = 'ytfts-active';

  // Outlined screen with outward arrows; the bottom bar lights up when active
  // (same pattern as YouTube's captions-button underline). Two variants:
  // the redesigned player draws icons on a 24x24 grid with the glyph nearly
  // edge to edge (the captions/theater frames span x=1..23), while classic
  // icons sit in the middle ~50% of a 36x36 grid.
  const ICON_PATHS_24 = `
    <rect x="2" y="4" width="20" height="14" rx="2"
          fill="none" stroke="#fff" stroke-width="2"/>
    <path d="M9.5 8 L5.5 11 L9.5 14 Z" fill="#fff"/>
    <path d="M14.5 8 L18.5 11 L14.5 14 Z" fill="#fff"/>
    <rect class="ytfts-underline" x="6" y="21" width="12" height="2" rx="1" fill="#f00"/>`;

  const ICON_PATHS_36 = `
    <rect x="10" y="12" width="16" height="12" rx="1"
          fill="none" stroke="#fff" stroke-width="1.7"/>
    <path d="M15.5 15.5 L13 18 L15.5 20.5 Z" fill="#fff"/>
    <path d="M20.5 15.5 L23 18 L20.5 20.5 Z" fill="#fff"/>
    <rect class="ytfts-underline" x="12" y="27" width="12" height="2" rx="1" fill="#f00"/>`;

  // Clone the fullscreen button's own <svg> (keeping its exact viewBox,
  // size attributes and classes) so our icon goes through the same styling
  // pipeline as the native icons, then draw our paths inside it.
  function makeIcon(fsBtn) {
    const nativeSvg = fsBtn.querySelector('svg');
    let svg;
    if (nativeSvg) {
      svg = nativeSvg.cloneNode(false);
    } else {
      svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.setAttribute('viewBox', '0 0 36 36');
      svg.setAttribute('width', '100%');
      svg.setAttribute('height', '100%');
    }
    const viewBox = (svg.getAttribute('viewBox') || '0 0 36 36').trim().split(/\s+/);
    const size = parseFloat(viewBox[2]) || 36;
    const base = size < 30 ? 24 : 36;
    const paths = base === 24 ? ICON_PATHS_24 : ICON_PATHS_36;
    svg.innerHTML = `<g transform="scale(${size / base})">${paths}</g>`;
    svg.classList.add('ytfts-icon');
    return svg;
  }

  function setActive(player, on) {
    player.classList.toggle(ACTIVE_CLASS, on);
    const btn = player.querySelector('.' + BTN_CLASS);
    if (btn) {
      btn.classList.toggle('ytfts-on', on);
      btn.setAttribute('aria-pressed', String(on));
      btn.title = on ? 'Exit fit to screen' : 'Fit to screen';
    }
  }

  // Players where the user wants fill active — persists across F/Esc cycles.
  const fillDesired = new WeakSet();

  function onButtonClick(event) {
    const btn = event.currentTarget;
    const player = btn.closest('.html5-video-player');
    if (!player) return;

    const turningOn = !player.classList.contains(ACTIVE_CLASS);
    setActive(player, turningOn);

    if (turningOn) {
      fillDesired.add(player);
      // Enter fullscreen if not already in it — but never exit it.
      if (!document.fullscreenElement) {
        player.querySelector('.ytp-fullscreen-button')?.click();
      }
    } else {
      fillDesired.delete(player);
    }
  }

  function makeButton(fsBtn) {
    // Clone the native fullscreen button (attributes only, no children or
    // listeners) so we inherit any extra classes/attributes the current
    // YouTube UI relies on for layout, then strip its identity.
    const btn = fsBtn.cloneNode(false);
    btn.classList.remove('ytp-fullscreen-button');
    btn.classList.add(BTN_CLASS);
    for (const attr of ['data-tooltip-target-id', 'data-tooltip-title', 'data-title-no-tooltip', 'data-priority', 'aria-keyshortcuts', 'id']) {
      btn.removeAttribute(attr);
    }
    btn.title = 'Fit to screen';
    btn.setAttribute('aria-label', 'Fit to screen');
    btn.setAttribute('aria-pressed', 'false');
    btn.appendChild(makeIcon(fsBtn));
    btn.addEventListener('click', onButtonClick);
    return btn;
  }

  function ensureButtons() {
    for (const player of document.querySelectorAll('.html5-video-player')) {
      if (player.querySelector('.' + BTN_CLASS)) continue;
      const fsBtn = player.querySelector('.ytp-fullscreen-button');
      if (!fsBtn) continue; // e.g. Shorts player has no fullscreen button
      fsBtn.parentElement.insertBefore(makeButton(fsBtn), fsBtn);
    }
  }

  document.addEventListener('fullscreenchange', () => {
    if (document.fullscreenElement) {
      // Re-entering fullscreen — restore fill for any player that wants it.
      for (const player of document.querySelectorAll('.html5-video-player')) {
        if (fillDesired.has(player)) setActive(player, true);
      }
    } else {
      // Leaving fullscreen — clear fill visually but keep the desire.
      for (const player of document.querySelectorAll('.' + ACTIVE_CLASS)) {
        setActive(player, false);
      }
    }
  });

  // YouTube is a SPA: the player and its controls can appear/rebuild at any
  // time, so re-check whenever the DOM changes (coalesced per frame).
  let scheduled = false;
  const observer = new MutationObserver(() => {
    if (scheduled) return;
    scheduled = true;
    requestAnimationFrame(() => {
      scheduled = false;
      ensureButtons();
    });
  });
  observer.observe(document.documentElement, { childList: true, subtree: true });

  document.addEventListener('yt-navigate-finish', ensureButtons);
  ensureButtons();
})();
