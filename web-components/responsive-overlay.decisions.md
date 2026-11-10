# Responsive Overlay — Pre-Implementation Decisions

Answer every decision below **before** writing the CSS/JS for how the
component's panel presents on phone vs tablet vs desktop. Each decision
has a recommended default; deviating from the default requires a one-line
justification (write it down — README, CHANGELOG, or PR description).

Read [responsive-overlay.md](./responsive-overlay.md) first if any of
these questions don't make sense.

---

## D-RO-1 — Applicability: does this component open an overlay / panel?

**Question:** Does the component render a floating panel / overlay that a
user opens — a dropdown list, a calendar, an autocomplete popup, a
command palette, a menu?

| Option | When to pick | Implication |
|--------|--------------|-------------|
| **A. Yes — opens a panel** *(triad applies)* | Multiselect, daterangepicker, autocomplete, combobox, menu. | Walk every decision below; run every C-RO check. |
| **B. No — fully inline** *(triad N/A)* | Player, switch, inline treeview, a grid whose body is always in-flow, a display-only widget. | The whole triad is **N/A**. Record it once and skip. |

**Default:** decide by inspection. A component with no
`position: absolute`/`fixed` opened-panel element, no "open/close"
state, and no positioning engine is **B**.

**If B:** note "responsive-overlay: N/A — no floating panel" in the PR /
CHANGELOG and stop here.

---

## D-RO-2 — Phone presentation mode

**Question:** How does the panel present on a phone (≤ the D-RO-3 width)?

| Option | When to pick | Implication |
|--------|--------------|-------------|
| **A. Edge-to-edge full-screen** *(default)* | Search-heavy panel with a long, filterable list (multiselect, daterangepicker). | `position: fixed; inset: 0; 100dvh/100dvw`; own header with input + explicit close. The native default for pickers. |
| B. Bottom sheet | Short, browse-only list; one-handed use is the priority. | Slides up ~60–90% height, rounded top, drag-to-dismiss. **Not yet covered by C-RO checks** — formalize sheet rules before shipping. |
| C. Keep anchored *(discouraged)* | Almost never. | Reads as a shrunk desktop dialog; loses room to the keyboard. Only if the panel is tiny and never has a search field. |

**Default: A. Full-screen.**

**If B or C:** justify, and (for B) add the sheet-specific checks.

---

## D-RO-3 — Phone breakpoint value

**Question:** At what viewport width does the panel switch from anchored
to the phone presentation?

| Option | When to pick |
|--------|--------------|
| **A. `max-width: 600px`** *(default)* | Material's compact→medium boundary; just above the widest portrait phone. |
| B. Other value | A specific product's device matrix demands it. Document why. |
| C. No breakpoint — core's `resolvePresentation` | The component is on `@keenmate/web-components-core` and switches presentation in JS. | The device class (touch-primary + the shorter viewport side) picks phone / tablet / desktop, so it survives rotation and has no width literal to drift. Media queries left in the CSS are layout tiers, not the phone switch (C-RO-2). |

**Default: A. 600px** (C for components that use core's
`resolvePresentation`). For A / B, whatever you pick lives in **one** CSS
`@media` block; if the JS positioning engine is mode-aware (D-RO-5 = B),
the same literal appears in its `matchMedia` string and the two MUST stay
in sync (constraint #1 / anti-pattern #6).

---

## D-RO-4 — Tablet & desktop presentation

**Question:** How does the panel present above the phone breakpoint?

| Option | When to pick | Implication |
|--------|--------------|-------------|
| **A. Anchored floating panel** *(default)* | Keep the panel you already built for desktop; tablet inherits it. | One presentation for everything > 600px. Simplest — one extra mode total (phone). |
| B. Bordered modal on tablet | You want a distinct, Material-style tablet treatment (centered, 16px margins). | A *third* presentation (phone full-screen / tablet modal / desktop anchored). Add the tablet-modal checks. |

**Default: A. Keep the anchored floating panel.** (Team decision:
tablet keeps floating; the bordered modal is a future opt-in.)

---

## D-RO-5 — How the positioning engine yields to full-screen

**Question:** The JS positioning engine writes inline `top/left/transform`
to anchor the panel. On phone the full-screen CSS must win. How?

| Option | When to pick | Implication |
|--------|--------------|-------------|
| A. CSS `!important` override | The component uses its own inline positioning and you don't want to touch the JS. | The phone `@media` block marks full-screen geometry `!important`. Self-contained in CSS; positioning JS still runs (wasted) on phone. |
| **B. Mode-aware JS (`matchMedia`)** *(recommended)* | The component uses the shared `@keenmate/web-components-core` positioning engine, or you can edit the positioning JS. | The engine checks `matchMedia('(max-width: 600px)')`, skips anchoring on phone, and re-evaluates on the `change` event. No `!important`; costs a second copy of the breakpoint literal. |

**Default: B for components on the shared engine** (implement the skip
once in core); **A for components with bespoke inline positioning** that
aren't ready to touch the JS.

**Not a theme-detection violation:** CLAUDE.md #3 forbids JS *color-scheme*
detection. `matchMedia` for a *layout/positioning* decision is a
different axis and is allowed — see responsive-overlay.md constraint #5.

---

## D-RO-6 — Dismissal affordances on phone

**Question:** How does the full-screen panel close?

**Mandatory (not a choice):** an **explicit** close affordance — a ✕ or
"Done" button in the header/footer. Plus Esc and Android hardware-back.

| Optional add-on | When to pick |
|-----------------|--------------|
| Swipe-down to dismiss | Bottom-sheet mode (D-RO-2 = B) or a nicety on full-screen. |
| Backdrop-tap | N/A for true full-screen (no visible backdrop); applies only to modal/sheet modes. |

**Default:** explicit ✕/Done + Esc + hardware-back. No backdrop-only
dismissal.

---

## D-RO-7 — Touch-target minimum size

**Question:** What is the minimum tappable size for rows and controls in
the phone presentation?

| Option | When to pick |
|--------|--------------|
| **A. 44px** *(default)* | Apple HIG minimum; the safe cross-platform floor. |
| B. 48px | Following Material's 48×48 with 8px spacing for a roomier feel. |

**Default: A. 44px**, expressed as `--base-touch-target-min` so it's a
cross-component token, consumed in the phone `@media` block.

---

## D-RO-8 — Viewport-height unit

**Question:** Which unit sizes the full-screen panel?

| Option | When to pick |
|--------|--------------|
| **A. `dvh`/`dvw`** *(default)* | Always, on any modern target. Tracks the visible viewport as chrome / keyboard show and hide. |
| B. `vh`/`vw` + JS resize | Only for a legacy engine without `dvh` support — and then compute the height in JS on `resize`/`visualViewport`. |

**Default: A. `dvh`/`dvw`.** B is a last resort; document the target that
forced it.

---

## D-RO-9 — Safe-area insets

**Question:** Does the full-screen chrome respect notch / home-indicator
safe areas?

| Option | When to pick |
|--------|--------------|
| **A. `max(base, env(safe-area-inset-*))`** *(default)* | Any component that can ship inside a notched-phone PWA / full-bleed page. Degrades to base padding when insets are 0. |
| B. Ignore safe areas | Only if the component is guaranteed never to render full-bleed. Document it. |

**Default: A.** Note in `docs/usage.md` that non-zero insets require the
consumer's `<meta name="viewport" content="viewport-fit=cover">`.

---

## D-RO-10 — Full-screen container mechanism & scroll lock

**Question:** How is the full-screen overlay realized, and how is the
background scroll locked?

| Option | When to pick | Implication |
|--------|--------------|-------------|
| **A. In-place `position: fixed` + `overscroll-behavior: contain`** *(default)* | Simplest; panel stays in the shadow scope so theming Just Works. | Add an explicit scroll-lock (`overflow: hidden` on a lock target) if `overscroll-behavior` isn't enough. |
| B. Native `<dialog>` / Popover top-layer | You need top-layer escape from `overflow`/stacking clipping, a real backdrop, and implicit scroll lock. | The panel leaves the shadow scope — propagate `data-theme` / read `--base-*` per **C-CS-10 Kind B**, or dark mode breaks in the top layer. |

**Default: A.** Choose B when clipping / stacking context forces
top-layer rendering; then wire the theme propagation.

---

## Decision summary table

Fill this out and paste it into the component's CHANGELOG entry or PR
description.

```
D-RO-1 applicability          : [A opens a panel | B inline — N/A]
D-RO-2 phone presentation     : [A full-screen | B bottom sheet | C anchored]
D-RO-3 phone breakpoint       : [600px | ______ | C core resolvePresentation]
D-RO-4 tablet/desktop         : [A anchored | B bordered modal on tablet]
D-RO-5 positioning yield      : [A CSS !important | B mode-aware matchMedia]
D-RO-6 dismissal              : explicit ✕/Done + Esc + back [+ swipe? + backdrop?]
D-RO-7 touch target min       : [A 44px | B 48px]
D-RO-8 viewport unit          : [A dvh/dvw | B vh + JS]
D-RO-9 safe-area insets       : [A max(base, env()) | B ignore]
D-RO-10 container & scroll lock: [A fixed + overscroll-contain | B <dialog>/Popover top-layer]
```

---

When done deciding, proceed to implementation. Use
[responsive-overlay.checks.md](./responsive-overlay.checks.md) before
declaring it done.
