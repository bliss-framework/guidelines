# Responsive Overlay Presentation — Web Component Guideline

How a component that opens a **floating panel / overlay** (a multiselect
dropdown, a daterangepicker calendar, an autocomplete list, a command
palette) should present that panel across phone, tablet, and desktop —
so it feels native on a touch device instead of like a shrunk desktop
dialog.

This is a living doc. Update it when a new device idiom emerges or when
we find a foot-gun the current pattern doesn't catch. It concerns only
the **presentation mode of an overlay/panel**; fluid layout *inside* a
component's inline body (responsive grids, column collapsing) is out of
scope — see "Out of scope" at the end.

Cross-references:
- [theme-container.md](./theme-container.md) — the panel and its
  full-screen variant still anchor their variables on the container;
  the C-TC-8 fixed-floating-UI exception is the sibling of the
  positioning discussion here.
- [color-scheme.md](./color-scheme.md) → C-CS-10 — a full-screen panel
  rendered to the top layer (`<dialog>` / Popover API) leaves the shadow
  scope, exactly like a portaled tooltip; the theme signal must be
  propagated the same way.
- [naming-conventions.md](./naming-conventions.md) — the full-screen
  state is a BEM modifier / `data-*` attribute like any other.

---

## TL;DR

> **One panel, chosen by viewport width *in CSS*. Phone (≤ 600px) →
> edge-to-edge full-screen overlay with its own header (search input +
> explicit close). Tablet & desktop (> 600px) → the anchored floating
> panel. Use `dvh`/`dvw`, not `vh`/`vw`. The JS positioning engine must
> *yield* to the full-screen media query. An explicit close affordance
> is mandatory in full-screen — there is no "outside" to tap.**

If you do nothing else, do that.

---

## The problem: an anchored panel is a desktop idiom

A floating panel anchored under its trigger assumes a mouse, a precise
pointer, and a lot of screen. On a ~390px-wide phone with the soft
keyboard up, that same anchored dropdown:

- has almost no vertical room left for the list;
- gets covered by the keyboard the moment the search field focuses;
- is hard to dismiss precisely (mis-taps on a small backdrop);
- reads as a *desktop dialog shrunk down* — the tell of a non-native UI.

Every native mobile picker and the major mobile UI kits (Material,
Ionic, Vant / Ant Design Mobile) present selection-with-search as an
**edge-to-edge full-screen view** or a **bottom sheet** — never a
bordered dialog floating under the field. Material Design's own date
picker ships two modes and picks by screen: **phones → full-screen**
(its own header with the input + close), **tablet / larger / landscape
→ modal** (centered, with margins).

That maps directly onto our decision:

| Band | Width | Presentation |
|------|-------|--------------|
| **Phone** | ≤ 600px | **Edge-to-edge full-screen overlay** |
| **Tablet** | 601–1024px | Anchored floating panel *(same as desktop)* |
| **Desktop** | > 1024px | Anchored floating panel |

Tablet and desktop are identical for this guideline, so the operative
rule is a **single breakpoint at 600px**: phone → full-screen, everything
else → anchored. (A bordered *modal* on tablet is an allowed alternative
— D-RO-4 — but the default is to keep the anchored panel you already
built.)

### Why 600px

600px is the compact→medium window boundary in Material's window-size
classes and sits just above the widest common phone (portrait). It's the
canonical phone ceiling for this guideline. A different value is
allowed (D-RO-3) but must be justified and kept in **one place** (see
"Technical constraints" #1). A component on `@keenmate/web-components-core`
can instead let `resolvePresentation` pick the phone presentation from the
device class (touch-primary + the shorter viewport side) — no width literal
at all (D-RO-3 = C).

### Why not a bottom sheet by default

A bottom sheet (slides up ~60–90% height, rounded top) is arguably even
more common and nicer one-handed for *short* lists. But for a
search-heavy panel with a long, filterable list — the multiselect /
daterangepicker case — full-screen gives the list every pixel once the
keyboard is up and never leaves an awkward half-covered sheet. Full-screen
is the safer default; bottom sheet is an opt-in (D-RO-2 = B).

---

## The CSS pattern

The panel has a single set of feature styles; a **phone media query**
overrides *positioning and sizing only* to make it full-screen. Adapt
the class names to your component's BEM prefix; keep the structure.

```css
/* ── Anchored panel (tablet & desktop; the JS positioning engine sets
      inline top/left/transform on this element) ─────────────────────── */
.ms__panel {
  position: absolute;                 /* anchored to the trigger */
  min-width: var(--ms-panel-min-width, 16rem);
  max-height: var(--ms-panel-max-height, 24rem);
  background: var(--ms-panel-bg, light-dark(#ffffff, #1a1a1a));
  border: 1px solid var(--ms-border, light-dark(#e0e0e0, #3d3d3d));
  border-radius: var(--ms-panel-radius, 0.5rem);
  box-shadow: var(--ms-panel-shadow, 0 4px 12px rgb(0 0 0 / 0.15));
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.ms__list {
  flex: 1 1 auto;
  min-height: 0;                      /* lets the flex child actually scroll */
  overflow-y: auto;
  overscroll-behavior: contain;       /* don't chain scroll to the page */
}

/* ── Phone: edge-to-edge full-screen ──────────────────────────────────
      600px is the phone ceiling. This is the ONE sanctioned magic number
      in the file — keep it in this single @media block (and in sync with
      the positioning engine's matchMedia literal if you use D-RO-5 = B). */
@media (max-width: 600px) {
  .ms__panel {
    /* !important beats the inline top/left/transform the positioning JS
       writes — unless the JS is mode-aware (D-RO-5 = B), in which case it
       skips anchoring on phone and these don't need !important. */
    position: fixed !important;
    inset: 0 !important;
    width: 100dvw !important;
    height: 100dvh !important;        /* dvh, not vh — see constraint #2 */
    max-height: none !important;
    transform: none !important;
    border: none;
    border-radius: 0;
    box-shadow: none;
  }

  /* Full-screen chrome: header carries the search input + explicit close.
     Pad for the notch / status bar via safe-area insets, degrading to the
     base padding when the consumer hasn't set viewport-fit=cover. */
  .ms__panel-header {
    display: flex;
    padding-top: max(var(--ms-panel-pad, 0.75rem), env(safe-area-inset-top));
  }
  .ms__panel-footer {
    padding-bottom: max(var(--ms-panel-pad, 0.75rem), env(safe-area-inset-bottom));
  }

  /* Touch targets: desktop-dense rows are un-tappable on a phone. */
  .ms__option,
  .ms__close {
    min-height: var(--base-touch-target-min, 44px);
  }
  .ms__close { min-width: var(--base-touch-target-min, 44px); }
}
```

Note what the media query does **not** touch: no colors, no variable
redeclarations — only geometry. Dark mode, theming, and the variable
chains all keep working unchanged.

---

## Technical constraints (the ones that bite)

### 1. Media queries can't read CSS custom properties

`@media (max-width: var(--phone-max))` **does not work** — `var()` is
invalid in a media feature value (same for container queries). So the
600px literal is unavoidable in CSS. Keep it in **one** `@media` block.
If you also gate JS on it (D-RO-5 = B), that's a *second* copy of the
literal — the two must stay in sync, or the panel flips mode at
different widths for layout vs positioning and you get a dead zone
where it's neither anchored nor full-screen (anti-pattern #6). This is
the single sanctioned "magic number" in the component; comment it in
both places.

### 2. Use `dvh`/`dvw`, never `vh`/`vw`

On mobile, `100vh` is the **large** viewport — the height *including* the
area behind the browser's URL bar. A `height: 100vh` full-screen panel
runs its bottom (the list tail, the "Done" button) *under* the URL bar,
off-screen and unreachable. `100dvh` (dynamic viewport height) tracks the
*visible* area and shrinks/grows as the browser chrome and the soft
keyboard show and hide. Always `dvh`/`dvw` for full-screen sizing.
(`position: fixed; inset: 0` fills the visual viewport on its own in most
engines, but pair it with a `dvh` height on the scroll container so the
list computes its scroll box against the visible area.)

### 3. The soft keyboard

A search-driven panel focuses an input, which raises the keyboard.
Structure the full-screen panel as a **flex column**:

- header (search input) — fixed height,
- list — `flex: 1 1 auto; min-height: 0; overflow-y: auto; overscroll-behavior: contain`,
- optional footer (Done) — fixed height.

With `dvh`, the panel shrinks when the keyboard opens and the list stays
scrollable. Consumers who want the *page* layout to resize with the
keyboard set `<meta name="viewport" content="… interactive-widget=resizes-content">`
— that's a **consumer responsibility** (the component can't set the host
page's viewport meta); document it in `docs/usage.md`.

### 4. Safe-area insets — all four edges, not just top/bottom

The full-screen sheet must keep its **content** inside the display's safe
area. Two axes, and the second is the one everyone forgets:

- **Vertical (portrait-obvious).** The notch / status bar at the top and
  the home-indicator / gesture pill at the bottom — `safe-area-inset-top`
  / `-bottom`.
- **Horizontal (landscape-only, and the nastier bug).** Rotate an Android
  phone to landscape and the system **navigation bar moves to one side**
  while a **camera cutout / rounded corner** eats the other. A
  `width: 100vw` sheet spans the *entire physical width*, so its left- and
  right-aligned content (search field, option rows) slides **under those
  side bars** — the row text is clipped on the left and the search box
  looks "too wide for the screen," running off under the cutout. This is
  invisible in portrait and in DevTools device emulation (which don't
  model the side insets), so it ships unnoticed. `safe-area-inset-left` /
  `-right` are what you're missing.

**Padding only the header/footer top/bottom does not fix the landscape
clip** — the row content lives in the scrolling body, whose left/right
edges are still at `0` / `100vw`. Inset the **whole sheet's content box**,
all four edges, on the fixed panel itself. Keep `box-sizing: border-box`
so the outer box stays a full-bleed `100vw × 100dvh` — the **background
still paints edge-to-edge** (no gaps at the rounded corners) while the
flex column (header · list · footer) is pulled into the visible region:

```css
.ms__panel--fullscreen {          /* the fixed, full-screen sheet */
  /* … position: fixed; width: 100vw; height: 100dvh; background: … … */
  box-sizing: border-box;         /* padding insets CONTENT, not the bg box */
  padding-top:    env(safe-area-inset-top);
  padding-right:  env(safe-area-inset-right);
  padding-bottom: env(safe-area-inset-bottom);
  padding-left:   env(safe-area-inset-left);
}
```

Apply this on the sheet when its background is uniform (header bg == sheet
bg), which is the common case — one rule fixes both axes. If the header /
footer have a *distinct* background that must bleed under the status bar,
keep the sheet's left/right padding here and instead move the top/bottom
inset onto those chrome elements as `max(var(--pad), env(safe-area-inset-*))`
so their fill reaches the screen edge. Either way, **left/right on the
sheet is mandatory** — that's the landscape fix.

`env()` insets are non-zero only when the consumer sets
`<meta name="viewport" content="viewport-fit=cover">` — a **consumer
responsibility** to document. Because `env()` is `0` otherwise, the
padding is a harmless no-op on letterboxed / non-cutout pages: a fix where
needed, never a regression. (`max(base, env())` is the right shape only
where you want a non-zero *baseline* padding regardless; a bare `env()` is
correct on the sheet, whose children carry their own baseline padding.)

### 5. The positioning engine must yield to the media query

The JS positioning engine anchors the panel by writing **inline**
`position` / `top` / `left` / `transform` onto the panel element. Inline
styles beat stylesheet rules, so on phone the full-screen CSS won't win
unless you handle it. Two sanctioned mechanisms (D-RO-5):

- **A — CSS wins with `!important`.** The phone `@media` block marks the
  full-screen geometry `!important` to override the inline anchoring
  (shown in the pattern above). Self-contained in CSS; the JS stays
  viewport-agnostic. The cost is `!important`, and the positioning JS
  still runs (wasted work) on phone.
- **B — JS is mode-aware (recommended for the shared engine).** The
  positioning engine checks `matchMedia('(max-width: 600px)')`, **skips
  anchoring** when it matches (leaving the panel to the stylesheet's
  full-screen rules), and listens to the `MediaQueryList` `change` event
  to re-evaluate on rotation / resize. No `!important`, no wasted
  positioning work. The cost is a second copy of the 600px literal
  (constraint #1). This is the right home for the behavior in the
  shared `@keenmate/web-components-core` positioning engine — implement
  it once there and every component inherits phone full-screen for free.

**This is not a violation of the "no JS theme detection" invariant.**
That invariant (CLAUDE.md #3) is about *color-scheme* — dark mode is
100% CSS. Viewport-mode detection for *layout / positioning* is a
different axis: the positioning engine is already JS, and `matchMedia`
for a layout decision is legitimate and expected. Keep the *look*
(colors, dark mode) in CSS; the *geometry mode* may consult `matchMedia`.

### 6. Dismissal — full-screen needs an explicit close

An anchored panel dismisses on click-outside / Esc, because there's a
visible "outside". A full-screen panel has **no outside** — so an
**explicit close affordance is mandatory**: a ✕ or "Done" button in the
header/footer. Backdrop-tap is N/A full-screen. Also wire Esc and the
Android hardware-back to close on phone. Never ship a full-screen panel
whose only escape is the browser back button (anti-pattern #3).

### 7. Background scroll lock

While the full-screen overlay is open, the page behind must not scroll.
`overscroll-behavior: contain` on the scroll container stops
scroll-chaining. For a hard lock, either set `overflow: hidden` on a
scroll-lock target (a documented light-DOM touch — one of the few
sanctioned cases where JS reaches into light DOM) or render the panel to
the **top layer** via a native `<dialog>` (`showModal()`) or the Popover
API, which locks scroll and provides the backdrop implicitly (D-RO-10).

### 8. The `<dialog>` / Popover top-layer option

`<dialog>.showModal()` (or `popover`) gives full-screen + top-layer
(escapes `overflow` / stacking-context clipping) + implicit scroll lock +
backdrop, for free. Attractive on phone. The trade-off is the same one
C-CS-10 flags for portaled tooltips: the top-layer element **leaves the
shadow scope**, so the container's `--<prefix>-*` variables and
`data-theme` selectors no longer reach it. If you go this route, propagate
the theme signal (mirror `data-theme` onto the dialog at open time, or
have it read `--base-*` directly) exactly as C-CS-10 Kind B requires.

---

## Rules of the road

### Always

1. **Full-screen on phone, anchored on tablet/desktop**, switched by a
   single `max-width: 600px` media query (or the D-RO-3 value).
2. **`dvh`/`dvw` for full-screen sizing** — never `vh`/`vw`.
3. **An explicit close affordance in full-screen** (✕ / Done), plus Esc
   and hardware-back.
4. **`overscroll-behavior: contain`** on the scrollable list.
5. **Safe-area insets on all four edges** of the full-screen sheet —
   including `left`/`right` (the landscape side-bar / cutout clip), not
   just top/bottom. Inset the sheet content box with `box-sizing:
   border-box` so the background stays full-bleed.
6. **Touch targets ≥ 44px** in the phone media query for rows and the
   close button (use `--base-touch-target-min`).
7. **Keep the breakpoint literal in one place** (or two, in sync, if the
   JS is mode-aware).
8. **The media query touches geometry only** — no colors, no variable
   redeclarations. Theming and dark mode keep working unchanged.

### Never

1. **Never present an anchored dropdown on a phone.** Crammed under the
   trigger, half-covered by the keyboard — the #1 non-native tell.
2. **Never size full-screen with `vh`/`vw`.** The bottom of the list and
   the Done button disappear behind the URL bar.
3. **Never ship a full-screen panel with no explicit close.** The user
   is trapped; the back button is not a close button.
4. **Never let the positioning JS win over the full-screen media query.**
   Either `!important` the geometry (D-RO-5 = A) or make the engine skip
   anchoring on phone (D-RO-5 = B). A stylesheet override without
   `!important` loses to inline styles and renders "full-screen" as a
   clipped anchored panel.
5. **Never carry desktop-dense rows into phone.** 28px rows are
   un-tappable; bump to ≥ 44px.
6. **Never duplicate the breakpoint literal and let it drift.** CSS at
   600px, JS `matchMedia` at 768px → a width band where the panel is
   neither anchored nor full-screen.
7. **Never inset only the top/bottom safe area.** A `100vw` sheet with
   only header/footer notch padding still runs its rows and search field
   under the **landscape** side nav bar / camera cutout. Inset left/right
   too, on the sheet content box.

---

## Anti-patterns we've actually seen

1. **Anchored dropdown on phone** — a tiny 200px panel under the trigger,
   the bottom third behind the keyboard. Fix: the `max-width: 600px`
   full-screen block.
2. **`height: 100vh` full-screen** — the "Done" button rendered ~80px
   below the visible viewport, unreachable without the URL bar
   collapsing. Fix: `100dvh`.
3. **Full-screen with no close button** — testers reported being
   "stuck"; the only way out was Android back, which navigated the page.
   Fix: mandatory ✕/Done + Esc + back-to-close.
4. **Media override without `!important` while JS anchors inline** — the
   panel had `position: fixed; inset: 0` in the stylesheet but the
   positioning engine's inline `top: 340px; left: 12px` won; it rendered
   as a clipped anchored panel at phone widths. Fix: `!important` the
   full-screen geometry (A) or make the engine mode-aware (B).
5. **Desktop row height on phone** — 28px option rows produced constant
   mis-taps. Fix: `min-height: var(--base-touch-target-min, 44px)` in the
   phone block.
6. **Two breakpoint literals out of sync** — CSS flipped to full-screen
   at 600px, the JS positioning skip fired at 768px; between 600–768px
   the CSS said full-screen but the JS still anchored, producing a
   clipped mess. Fix: single literal, or two kept in sync with a comment
   pointing at each other.
7. **Landscape rows clipped under the side nav bar / cutout** — the
   full-screen sheet looked perfect in portrait and in DevTools emulation,
   but on a real Android phone rotated to landscape, the option rows'
   left edge and the search field ran **under the side navigation bar and
   the camera cutout** — the field looked "zoomed / too wide for the
   screen." Root cause: `width: 100vw` spans the full physical width and
   the sheet had **no `env(safe-area-inset-left/right)`** (or padded only
   the header top/bottom). Fix: `box-sizing: border-box` +
   `env(safe-area-inset-*)` on all four edges of the sheet (constraint #4).
   The tell that this class of bug is lurking: the component has a
   full-screen sheet but **zero `env(safe-area-inset-left|right)`** in its
   CSS.

---

## Reference implementations

- **`@keenmate/web-multiselect`** — the component this guideline was
  extracted from. Phone (≤ 600px) → edge-to-edge full-screen panel with
  a header search input + explicit close; tablet / desktop → the anchored
  floating panel. Its full-screen dropdown, selected-items popover, and
  toast now carry the four-edge `env(safe-area-inset-*)` insets
  (constraint #4) — added after a real-device report of the search field
  and rows clipping under the landscape side nav bar / camera cutout
  (anti-pattern #7).
- **`@keenmate/web-daterangepicker`** — same split for the calendar
  panel, aligned with multiselect.
- **`@keenmate/web-components-core`** — the shared positioning engine is
  the right home for D-RO-5 = B (mode-aware anchoring): implement the
  `matchMedia` skip once and every consuming component inherits phone
  full-screen. See the SPEC's positioning slice.

---

## Out of scope / future work

- **Inline responsiveness.** Fluid layout *inside* a component's own body
  — a grid collapsing columns, a toolbar wrapping — is not this triad.
  It may become a future `responsive-layout.md`. This triad is only about
  the presentation mode of an **overlay/panel**.
- **Bottom sheet.** Sanctioned as an opt-in phone mode (D-RO-2 = B) but
  not yet given its own checks. Formalize the sheet-specific rules
  (drag-to-dismiss, snap points, backdrop) if a component ships one.
- **Bordered tablet modal.** D-RO-4 = B allows Material's tablet "modal"
  treatment; if a component adopts it, add the tablet-modal checks then.
- **Foldables / dual-screen.** Not addressed; revisit if a component
  lands on a foldable target.

## Coordination note — `--base-touch-target-min`

This guideline introduces one new cross-component token,
`--base-touch-target-min` (default `44px`, D-RO-7), consumed in the
phone media query for row and control sizing. It is always read **with
its literal fallback** — `var(--base-touch-target-min, 44px)` — so a
component works standalone whether or not theme-designer sets it. But
per CLAUDE.md ("Editing the guidelines themselves"), the canonical
`--base-*` taxonomy in [base-variables.md](./base-variables.md) is the
source of truth, and **adding an entry is a coordination move**. Register
`--base-touch-target-min` in that taxonomy table (and in
`base-variables.decisions.md` if a decision is warranted) as a follow-up
so the token is discoverable alongside `--base-input-size-*-height` and
the `--base-tooltip-*` sizing scale.
