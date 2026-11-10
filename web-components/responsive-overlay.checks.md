# Responsive Overlay — Post-Implementation Checks

Run every check below **after** you finish the phone/tablet presentation
work, and **before** declaring it done.

Each check has: what to look for, how to verify it, and what failure
looks like. Failing any check means the work is not complete. Mark each
as ✅ pass or ❌ fail in the PR description.

Read [responsive-overlay.md](./responsive-overlay.md) for the rationale
behind each check.

Each check is tagged **`[auto]`**, **`[semi]`**, or **`[manual]`** — see
[css-structure.checks.md](./css-structure.checks.md) for the meaning of
each tier.

**Applicability:** this triad applies only to components that open a
floating panel / overlay (D-RO-1). A fully-inline component (player,
switch, display-only widget) is **N/A** — cite the D-RO-1 = B decision
and skip. C-RO-1 is the gate.

Paths below assume the CSS lives in `src/css/` and the panel BEM prefix
is `<prefix>` (e.g. `ms`). Adapt to the component.

---

## C-RO-1 — Applicability gate: the component opens a panel

**Tier:** `[semi]` — presence of a floating panel is a grep + judgment call

**What:** Confirm whether the triad applies. It applies iff the component
renders an opened panel/overlay (dropdown, calendar, autocomplete, menu).

**How to verify:**
```bash
# Signals of an opened panel: a panel-named class, or code that anchors or
# presents one (positioning engine, core's resolvePresentation, Popover API,
# <dialog>, a dialog / listbox role).
grep -rnE "__(panel|dropdown|menu|popup|calendar|listbox|overlay)\b" src/css/
grep -rnE "computePosition|resolvePresentation|showPopover|showModal|popover=|(dialog|listbox)['\"]" src/
```

`position: absolute|fixed`, `getBoundingClientRect` and `matchMedia` on
their own are **not** signals: tooltips, drag ghosts, a pseudo-element
overlay (`::after { inset: 0 }`) and layout code use them too, and none
of those is a panel with a phone presentation.

**Pass (applies):** at least one opened-panel element exists → walk the
rest of the checks.

**Pass (N/A):** no panel element, no open/close state, no positioning →
record "responsive-overlay: N/A (D-RO-1 = B)" and mark every remaining
check N/A.

**Failure mode:** a component that clearly opens a panel is skipped, and
its phone experience is never validated.

---

## C-RO-2 — Phone breakpoint media query present, single source

**Tier:** `[auto]`

**What:** Exactly one `@media (max-width: <phone>)` block (default 600px)
drives the phone presentation. The literal is not scattered.

**How to verify:**
```bash
grep -rnE "@media[^{]*max-width:\s*[0-9]+px" src/css/
```

**Pass:** A `max-width` media query at the D-RO-3 value exists, and the
same literal appears in at most one CSS `@media` condition (multiple
*rules* inside that one query are fine). If the JS is mode-aware
(D-RO-5 = B), the same literal in `matchMedia(...)` is the one allowed
second copy — verify it matches (see C-RO-5). Only the literal after
`max-width:` counts (the `min-width` of a range query is not a phone
breakpoint).

**Pass (D-RO-3 = C):** the component picks its presentation with core's
`resolvePresentation(…)`. There is no phone `@media`, and any
`max-width` queries left are layout tiers inside a presentation (grid
columns, panel widths), not counted here.

**Failure mode:** no phone breakpoint at all (the panel stays anchored on
phone), or the literal duplicated across several `@media` conditions that
can drift (anti-pattern #6).

---

## C-RO-3 — Full-screen block uses fixed/inset + dvh/dvw

**Tier:** `[semi]` — grep finds the block; confirming it's the full-screen
geometry is a read

**What:** Inside the phone media query, the panel becomes edge-to-edge:
`position: fixed`, `inset: 0` (or `top/right/bottom/left: 0`), full
`100dvw`/`100dvh`, `border`/`radius`/`shadow` reset.

**How to verify:** Open the phone `@media` block and confirm the panel
rule sets fixed positioning and full dynamic-viewport sizing.
```bash
grep -rnE "inset:\s*0|position:\s*fixed|100dv[hw]" src/css/
```

**Pass:** the panel goes full-screen with `dvh`/`dvw` sizing. Borders /
radius / shadow are removed (edge-to-edge, not a floating card at full
size).

**Failure mode:** the phone block only tweaks width, leaving the panel
anchored and clipped; or it uses `vh`/`vw` (caught harder by C-RO-4).

---

## C-RO-4 — No static `vh`/`vw` in overlay sizing

**Tier:** `[auto]`

**What:** Full-screen sizing uses `dvh`/`dvw`, never bare `vh`/`vw`
(constraint #2 — `vh` includes the area behind the URL bar and clips the
panel bottom).

**How to verify:**
```bash
# Bare vh/vw NOT preceded by the 'd' of dvh/dvw, and not svh/lvh.
grep -rnE "[^a-z0-9]([0-9]+(\.[0-9]+)?)(vh|vw)\b" src/css/ | grep -vE "d(vh|vw)|s(vh|vw)|l(vh|vw)"
```

**Pass:** no matches (every viewport-relative size is `dvh`/`dvw`, or the
intentional `svh`/`lvh` where documented). Bare `vh`/`vw` on a
non-full-screen decorative rule that's documented is an acceptable
exception — note it.

**Failure mode:** `height: 100vh` full-screen panel whose bottom (list
tail, Done button) sits behind the mobile URL bar, unreachable
(anti-pattern #2).

---

## C-RO-5 — Positioning engine yields to full-screen

**Tier:** `[semi]` — matches D-RO-5; verifying the chosen mechanism is a read

**What:** The JS positioning engine's inline `top/left/transform` must not
win over the full-screen media query. One of:
- **D-RO-5 = A:** the phone `@media` full-screen geometry is `!important`.
- **D-RO-5 = B:** the positioning JS gates on `matchMedia('(max-width: <phone>)')`
  and skips anchoring on phone, with a `change` listener.

**How to verify:**
```bash
# A — !important on full-screen geometry inside the phone block
grep -rnE "(position|inset|width|height|transform)[^;]*!important" src/css/
# B — matchMedia gate in the positioning JS, same literal as C-RO-2
grep -rnE "matchMedia\([^)]*max-width:\s*[0-9]+px" src/
```

**Pass:** the mechanism declared in D-RO-5 is present. For B, the
`matchMedia` literal equals the CSS `@media` literal (C-RO-2) and a
`change`/`addEventListener('change', …)` re-evaluates on rotation.

**Failure mode:** neither mechanism present → the inline anchoring styles
win and "full-screen" renders as a clipped anchored panel
(anti-pattern #4). Or the two literals disagree → a dead width band
(anti-pattern #6).

---

## C-RO-6 — Explicit close affordance in full-screen

**Tier:** `[semi]` — grep the template + judge it's reachable in full-screen

**What:** The full-screen panel has an explicit ✕ / "Done" control
(D-RO-6). Backdrop-tap alone is not acceptable — full-screen has no
visible outside.

**How to verify:** Inspect the panel template for a close button that
renders in the (full-screen) header/footer, and the handler that closes
on Esc + hardware-back.
```bash
grep -rnE "__(close|done|dismiss)\b|aria-label=\"?[Cc]lose|Escape|popstate" src/
```

**Pass:** a close control exists in the full-screen chrome; Esc closes;
Android back closes (or is documented as out of scope). The control meets
the touch-target minimum (C-RO-7).

**Failure mode:** full-screen panel with no visible close → user trapped
(anti-pattern #3).

---

## C-RO-7 — Touch targets ≥ minimum in phone mode

**Tier:** `[semi]` — grep the phone block + confirm the target size

**What:** Interactive rows and controls are ≥ the D-RO-7 minimum (default
44px) inside the phone media query, via `--base-touch-target-min`.

**How to verify:** In the phone `@media` block, confirm option rows and
the close/Done button carry a `min-height` (and `min-width` for
icon-only) ≥ 44px.
```bash
grep -rnE "min-(height|width):\s*(var\(--base-touch-target-min|4[4-9]px|[5-9][0-9]px)" src/css/
```

**Pass:** every tappable element in phone mode meets the minimum, ideally
through the `--base-touch-target-min` token (not a bare literal).

**Failure mode:** desktop-dense 28px rows carried into phone → mis-taps
(anti-pattern #5).

---

## C-RO-8 — Scroll containment on the panel list

**Tier:** `[auto]`

**What:** The scrollable list uses `overscroll-behavior: contain` so a
scroll gesture at the list edge doesn't chain to the page behind
(constraint #7).

**How to verify:**
```bash
grep -rnE "overscroll-behavior(-y)?:\s*(contain|none)" src/css/
```

**Pass:** the scroll container declares `overscroll-behavior: contain`
(or `none`). If D-RO-10 = B (`<dialog>`/Popover top-layer), the top layer
locks scroll implicitly — cite it and pass.

**Failure mode:** flinging the list scrolls the page underneath; on phone
the background visibly moves under the "full-screen" panel.

---

## C-RO-9 — Safe-area insets on the full-screen sheet — all four edges

**Tier:** `[semi]` — grep + confirm all four edges are covered

**What:** The full-screen sheet keeps its content inside the safe area on
**both axes** (constraint #4): top/bottom for the notch / home indicator,
**and left/right for the landscape side nav bar / camera cutout.** The
left/right inset is the one that's routinely missed and clips row content
in landscape. The clean form is `box-sizing: border-box` +
`env(safe-area-inset-*)` on all four edges of the fixed sheet (background
stays full-bleed).

**How to verify:**
```bash
# All four edges must appear. The left/right pair is the landscape fix.
grep -rnE "env\(safe-area-inset-(top|bottom|left|right)\)" src/css/
# RED FLAG: a full-screen sheet with NO left/right inset at all →
# guaranteed landscape clip on a cutout phone (anti-pattern #7).
grep -rnE "env\(safe-area-inset-(left|right)\)" src/css/ || echo "MISSING left/right inset"
```

**Pass:** the full-screen sheet insets **left, right, top, and bottom**.
For a uniform-background sheet, all four are bare `env(...)` on the sheet
with `box-sizing: border-box`; where a distinct header/footer background
must bleed, top/bottom may be `max(<base>, env(...))` on that chrome while
left/right stay on the sheet. `docs/usage.md` notes that non-zero insets
need the consumer's `viewport-fit=cover`. (N/A only if D-RO-9 = B is
documented.)

**Failure mode:** left/right insets absent → in landscape the option rows
and search field run under the side nav bar / cutout, clipped and looking
"too wide for the screen" (anti-pattern #7). Or top/bottom absent → header
under the status bar, footer under the home indicator.

---

## C-RO-10 — Soft-keyboard behavior (device / emulator)

**Tier:** `[manual]` (needs a real device or emulator with a soft keyboard)

**What:** With the search field focused and the keyboard up, the list
stays scrollable and the close/Done control is reachable; nothing
important is hidden behind the keyboard.

**How to verify:** In a mobile emulator (or a real phone), open the panel,
focus the search input, and:
1. Confirm the list scrolls with the keyboard up.
2. Confirm the close/Done control is reachable (not behind the keyboard).
3. Type to filter — results update and remain scrollable.
4. Rotate the device — the panel re-lays-out (full-screen still full).

**Pass:** the panel remains usable with the keyboard up in both
orientations.

**Failure mode:** the keyboard covers the list or the Done button; the
list won't scroll because a parent used `100vh` (see C-RO-4).

---

## C-RO-11 — Visual smoke test: phone full-screen, tablet anchored

**Tier:** `[manual]` (browser device emulation)

**What:** At phone widths the panel is edge-to-edge full-screen; just
above the breakpoint it is the anchored floating panel (D-RO-4 = A).

**How to verify:** In the dev server with device emulation (DevTools →
device toolbar):
1. At ≤ 600px (e.g. iPhone 390px): open the panel → full-screen,
   edge-to-edge, own header + close, no border/shadow.
2. At 601–1024px (tablet): open the panel → anchored floating panel
   (or, if D-RO-4 = B, the bordered modal).
3. At desktop: anchored floating panel.
4. Drag the viewport across 600px: the panel flips mode cleanly with no
   dead band where it's neither anchored nor full-screen (anti-pattern #6).
5. **Landscape on a real cutout device (not just emulation).** Open the
   full-screen sheet on an actual phone with a display cutout / gesture or
   3-button nav, then **rotate to landscape**. Confirm the search field
   and every option row stay fully visible — nothing clipped under the
   side nav bar or camera cutout, the field is not wider than the visible
   screen (anti-pattern #7). DevTools device emulation does **not** model
   the side insets, so this step needs real hardware or an OS emulator
   with a cutout profile.

**Pass:** each band renders its declared presentation; the transition at
the breakpoint is clean; and in landscape on a cutout device the content
sits entirely within the safe area.

**Failure mode:** full-screen leaks onto tablet, or the phone panel
renders anchored/clipped, or a width band shows a broken hybrid, or
landscape content is clipped under the side system bars.

---

## C-RO-12 — BEM + variable discipline for the mode

**Tier:** `[semi]` — reuses C-NC-8 / C-CSS-7 / C-BV-1 evidence

**What:** The full-screen state is expressed as a prefixed BEM modifier
(`<prefix>__panel--fullscreen`) or a `data-*` attribute on the container
— not an ad-hoc class. The phone media query touches **geometry only**:
no color literals, no variable redeclarations. The breakpoint px is the
only sanctioned literal (constraint #1); sizes use tokens.

**How to verify:**
```bash
# Color literals inside the phone media block would be a violation
grep -rnE "@media[^{]*max-width" src/css/    # locate the block, then read it
# Ad-hoc non-BEM state classes
grep -rnE "\.(fullscreen|mobile|phone)\b" src/css/   # should be <prefix>__…--… instead
```

**Pass:** the mode is a prefixed BEM modifier / `data-*` attribute; the
phone block contains only positioning/sizing/spacing (no `#hex`, no
`--<prefix>-*: …` redeclarations). Theming and dark mode keep working
because the media query never touched them.

**Failure mode:** a bare `.fullscreen` class (breaks the BEM contract,
C-NC-8), or colors hardcoded in the phone block (breaks C-BV-1 / C-CSS-8
and silently defeats dark mode in full-screen).

---

## C-RO-13 — Docs cover the responsive behavior + consumer duties

**Tier:** `[semi]` — read `docs/usage.md`, judge coverage

**What:** `docs/usage.md` (or a "Responsive / mobile" section) documents:
the phone-vs-tablet behavior, the breakpoint, and the two **consumer
responsibilities** the component can't self-serve —
`interactive-widget=resizes-content` (keyboard resize) and
`viewport-fit=cover` (safe-area insets).

**How to verify:** Open `docs/usage.md` and find the responsive section.
```bash
grep -rniE "full-?screen|mobile|responsive|interactive-widget|viewport-fit" docs/
```

**Pass:** a reader learns that the panel goes full-screen on phones, at
what width, and what viewport-meta they should set for the best result.

**Failure mode:** consumers file "the calendar is tiny / cut off on my
phone" issues that a documented viewport-meta note would have prevented.

---

## C-RO-14 — CHANGELOG entry

**Tier:** `[semi]` — existence is mechanical; judging concreteness is human

**What:** A CHANGELOG entry exists for the version that lands the
responsive-overlay work, with the D-RO decision summary.

**How to verify:**
```bash
head -50 CHANGELOG.md
```

**Pass:** the new-version block describes the phone full-screen behavior
and pastes (or links) the D-RO decision summary. Concrete, not "improve
mobile".

**Failure mode:** consumers don't notice the new phone presentation and
don't adjust their viewport-meta.

---

## Summary checklist

Paste into PR description, tick every box:

```
[ ] C-RO-1  [semi]   applicability gate — component opens a panel (else N/A)
[ ] C-RO-2  [auto]   phone breakpoint media query present, single source
[ ] C-RO-3  [semi]   full-screen block uses fixed/inset + dvh/dvw
[ ] C-RO-4  [auto]   no static vh/vw in overlay sizing
[ ] C-RO-5  [semi]   positioning engine yields to full-screen (!important or matchMedia)
[ ] C-RO-6  [semi]   explicit close affordance in full-screen
[ ] C-RO-7  [semi]   touch targets ≥ 44px in phone mode
[ ] C-RO-8  [auto]   overscroll-behavior: contain on the list
[ ] C-RO-9  [semi]   safe-area insets on full-screen chrome
[ ] C-RO-10 [manual] soft-keyboard behavior (device / emulator)
[ ] C-RO-11 [manual] visual smoke test — phone full-screen, tablet anchored
[ ] C-RO-12 [semi]   BEM + variable discipline for the mode
[ ] C-RO-13 [semi]   docs cover responsive behavior + consumer viewport-meta duties
[ ] C-RO-14 [semi]   CHANGELOG entry

Tier totals: 3 auto, 9 semi, 2 manual
```

If any box is unchecked, the work is not done.
