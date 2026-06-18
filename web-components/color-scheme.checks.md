# Color-Scheme — Post-Implementation Checks

Run every check below **after** you finish writing the dark-mode CSS, and
**before** declaring the work done.

Each check has: what to look for, how to verify it, and what failure looks
like. Failing any check means the work is not complete. Mark each as ✅ pass
or ❌ fail in the PR description.

Read [color-scheme.md](./color-scheme.md) for the rationale behind each check.

Each check is tagged **`[auto]`**, **`[semi]`**, or **`[manual]`** — see
[css-structure.checks.md](./css-structure.checks.md) for the meaning of
each tier.

---

## C-CS-1 — No *bare* `:host { color-scheme: ... }` (conditional is fine)

**Tier:** `[semi]` — grep finds every `color-scheme`; classifying each match as bare vs conditional is a regex/lookup step (same shape as C-TC-4)

**What:** The component must not declare `color-scheme` on a bare
`:host` selector. A bare declaration blocks the page's color-scheme
from inheriting for every instance and is the #1 footgun (multiselect
v1.10 → v1.11 bug).

**Conditional declarations are explicitly allowed.** A
`:host([data-theme="dark"]) { color-scheme: dark }`,
`:host-context([data-bs-theme="dark"]) { color-scheme: dark }`, etc.,
fires *only* when the consumer has explicitly signalled their theme
intent — it amplifies the signal rather than fighting page
inheritance. This is the recommended "Strategy B" pattern in
[color-scheme.md](./color-scheme.md).

**How to verify:**
```bash
grep -rn "color-scheme" src/css/
```

For every match, classify it:

| Selector shape | Verdict |
|---|---|
| `:host { color-scheme: ... }` (bare, no qualifier) | ❌ Fail |
| `:host([attr]) { color-scheme: ... }` | ✅ Conditional — pass |
| `:host-context(...) { color-scheme: ... }` | ✅ Conditional — pass |
| Inside `@media` query | ✅ Pass |
| Inside a comment / documentation | ✅ Pass |

**Pass:** Every match is either inside a comment, inside `@media`, or
on a *conditional* `:host(...)` / `:host-context(...)` selector.

**Failure mode:** A bare `:host { color-scheme }` shadows page
inheritance for every instance. The component renders light even when
the page sets `body { color-scheme: dark }`.

**Worked example (passing — Strategy B):**
`@keenmate/web-multiselect` v1.12.0-rc01+ — `src/css/dark-mode.css`
declares `color-scheme: dark`/`light` on five conditional selectors
(`:host([data-theme="dark"])`, `:host([data-theme="light"])`,
`:host-context([data-theme="dark"])`,
`:host-context([data-bs-theme="dark"])`, `:host-context(.dark)`, plus
light counterparts). The bare `:host` block in `variables.css` carries
a long explanatory comment about *why* it deliberately doesn't
declare `color-scheme`.

---

## C-CS-2 — `light-dark()` in color fallbacks

**Tier:** `[auto]`

**What:** Every hardcoded color fallback for text / surface / border / input /
hover / tooltip variables is wrapped in `light-dark(<light>, <dark>)`.

**How to verify:**
```bash
# Find color hex literals NOT inside light-dark()
grep -nE "var\(--base-[a-z-]+,\s*#[0-9a-f]{3,6}\s*\)" src/css/_variables.css
```

**Pass:** No matches (every color fallback uses `light-dark()` or chains to
another variable that does). A few intentional exceptions are OK if
documented (e.g., `--base-text-on-accent` which is `#ffffff` in both modes).

**Failure mode:** Consumers who set only `body { color-scheme: dark }` see a
light component on a dark page.

---

## C-CS-3 — Framework class selectors present

**Tier:** `[semi]` — needs D-CS-2 conventions list as input; grepping each chosen selector is mechanical

**What:** `:host-context()` selectors exist for every framework convention
declared in [color-scheme.decisions.md](./color-scheme.decisions.md) D-CS-2.

**How to verify:** Open `src/css/_dark-mode.css` (or wherever the framework-
class overrides live) and confirm presence of every selector chosen in D-CS-2.

**Pass:** Every chosen convention has both `dark` and `light` selectors. The
override blocks set the same variables in both directions.

**Failure mode:** Users on Bootstrap (or whichever framework was missed) get
no dark mode even though the component supports it.

---

## C-CS-4 — Per-instance override works

**Tier:** `[manual]` (browser observation)

**What:** `:host([data-theme="dark"])` and `:host([data-theme="light"])`
selectors flip the component on a per-instance basis.

**How to verify:** In the dev server, drop two instances side-by-side:
```html
<my-component data-theme="dark"></my-component>
<my-component data-theme="light"></my-component>
```
on a light page (no other theme classes). The first should render dark, the
second light, regardless of OS preference.

**Pass:** Visual difference between the two instances matches expectation.

**Failure mode:** Both instances render the same color; per-instance escape
hatch doesn't work.

---

## C-CS-5 — Contrast test fixture exists

**Tier:** `[auto]` (file-exists check)

**What:** A test fixture (`docs/test/dark-mode.html` or equivalent) mounts the
component on a dark page with multiple theming configurations.

**How to verify:**
```bash
ls docs/test/dark-mode.html
```

**Pass:** Fixture exists, mounts the component at least once per signal that
the component claims to support (per D-CS-5).

**Failure mode:** No way to regress-test dark mode beyond eyeballing.

---

## C-CS-6 — Playwright contrast assertions

**Tier:** `[semi]` — file existence + running `npx playwright test` returns exit code, but coverage match against D-CS-5 declared signals requires knowing the declared set

**What:** A Playwright spec computes WCAG contrast ratios and asserts ≥ 3:1
(non-text UI) or ≥ 4.5:1 (body text) for every signal the component supports.

**How to verify:**
```bash
ls e2e/dark-mode.spec.ts
npx playwright test e2e/dark-mode.spec.ts
```

**Pass:** Spec exists, runs, all assertions pass. Coverage matches what was
declared in D-CS-5.

**Failure mode:** Dark mode regresses silently in a future refactor.

---

## C-CS-7 — Visual smoke test in dev server

**Tier:** `[manual]` (browser observation; explicitly the human-eye check)

**What:** Manually load the component in a browser and confirm dark mode
looks right.

**How to verify:** Start the dev server, navigate to the dark-mode fixture
page, and:

1. Confirm text is readable on every visible surface.
2. Hover over interactive elements — hover highlight is visible.
3. Click/focus elements — focus indicator is visible.
4. Open dropdowns, tooltips, popovers (if present) — their backgrounds are
   the right shade and text is readable. **Tooltips that portal outside
   the container** (rendered to `document.body`) are the highest-risk
   case; C-CS-10 covers them mechanically — this step is the visual
   confirmation.
5. Try the same with OS dark mode forced on (browser DevTools → Rendering →
   Emulate CSS prefers-color-scheme).
6. Try with `body { color-scheme: dark }` removed — explicit `data-theme`
   class still works.

**Pass:** Nothing looks broken. No invisible text, no white-on-white, no
oddly-tinted surfaces.

**Failure mode:** A user reports "looks weird in dark mode" after release.
This check is your last line of defense — automated checks can't catch
*everything* a human eye notices.

---

## C-CS-8 — `docs/theming.md` documents the color-scheme contract

**Tier:** `[manual]` (read the file, judge coverage)

**What:** The component's `docs/theming.md` (per the
[readme-structure](./readme-structure.md) triad — the home of the
theming contract since the README slim-down) lists which theme
conventions it supports and how consumers opt in.

**How to verify:** Open `packages/<component>/docs/theming.md` and
find a section covering:

- What `--base-*` variables the component reads (or link to manifest)
- Which `data-theme` attributes are honored on the host and on ancestors
- Which framework class conventions are honored
- How OS preference is picked up (`color-scheme` declaration required)
- Any deviations from default decisions made in D-CS-1 through D-CS-6

**Pass:** Section exists and is accurate. A new user could read the
file and know how to theme the component.

**Failure mode:** Consumers ask support questions that the docs
should have answered.

**Exception:** A component that pre-dates the readme-structure triad
can still pass if the information lives in `README.md` under a
"Theming" section — flag for the readme-structure migration
(D-RS-6).

---

## C-CS-9 — CHANGELOG entry

**Tier:** `[semi]` — existence is mechanical; judging whether the entry is "concrete" is human work

**What:** A CHANGELOG entry exists for the version that lands the theming
work, summarizing what changed.

**How to verify:**
```bash
head -50 CHANGELOG.md
```

**Pass:** The unreleased / new-version block has entries under `Changed`
and/or `Added` describing the theming work. Entries are concrete (not "fix
dark mode") and call out which variables changed semantics.

**Failure mode:** Downstream consumers don't notice the change and don't
update their theme configs.

---

## C-CS-10 — Tooltips render correct contrast in dark mode

**Tier:** `[semi]` — finding tooltip code paths is grep work; classifying each path (in-container / portal / native) and verifying its theme-propagation mechanism is judgment work

**What:** Every tooltip the component renders must invert correctly
when the surrounding theme flips. The canonical taxonomy already
defines the variables (`--base-tooltip-bg` → chains through
`--base-inverse-bg`; `--base-tooltip-text-color`) — the failure mode
this check guards is the variables not *reaching* the tooltip element
in the first place. `@keenmate/web-grid` shipped with this bug:
dark-themed container, tooltip rendered to `document.body` with a
stale dark background and a black `color: #...` literal — unreadable.

Three tooltip kinds exist; verify each that this component actually
uses.

**A — Custom tooltip rendered inside the container / shadow DOM**
- Tooltip CSS reads `--<prefix>-tooltip-bg` / `--<prefix>-tooltip-text-color`
  declared on the container, which chain through `--base-tooltip-bg`
  / `--base-tooltip-text-color` with a `light-dark()` literal as the
  final fallback.
- No `background: #...` or `color: #...` literal in the tooltip
  rule itself — same rule as C-CS-2 + C-BV-1 / C-CSS-8, but tooltip
  rules are an easy place to forget it.
- Pass: every tooltip surface (bg, text, border) resolves through a
  `var(--<prefix>-tooltip-*, ...)` chain.

**B — Tooltip portaled outside the container** (rendered to
`document.body`, a `<dialog>`, the Popover API, or a `display:
contents` slot)
- Once the tooltip leaves the container, the container's
  `--<prefix>-*` variables and `data-theme` selectors no longer
  reach it. One of these three propagation mechanisms must be in
  place:
  1. The portal element receives a `data-theme` attribute mirrored
     from the container at insertion time, and the tooltip CSS has
     matching `[data-theme="dark"]` / `[data-theme="light"]`
     selectors (same shape as the host selectors, but applied to
     the portal root). This is the canonical fix.
  2. The tooltip CSS reads `--base-tooltip-bg` / `--base-tooltip-text-color`
     directly (skipping the `--<prefix>-*` layer entirely) and the
     page-level `color-scheme` is the only signal. Acceptable if the
     component declares this limitation in `docs/theming.md`.
  3. The portal element declares its own conditional
     `color-scheme: dark` block driven by the same signals listed in
     D-CS-2, parallel to the host's signal selectors.
- Pass: the portal renders with correctly contrasting colors when the
  container is in dark mode (verify in the contrast fixture, C-CS-5).
- Failure mode: web-grid bug — dark bg + dark text in dark mode
  because the portal didn't receive the container's theme signal and
  the tooltip CSS had a hardcoded `color: #...` literal.

**C — Browser-native `title=""` tooltips**
- Browser renders the native tooltip honoring the page's
  `color-scheme`. The component only needs to *not block* this by
  declaring a bare `:host { color-scheme: ... }` (already enforced
  by C-CS-1).
- Pass: C-CS-1 is green and no JS rewrites `title` attributes in a
  way that suppresses native tooltips. Otherwise N/A.

**How to verify:**
```bash
# Find every tooltip code path
grep -rnE "tooltip|Tooltip|popover|Popover" src/ | grep -vE "//|/\*|\*/"

# Find portal-style instantiation (CANDIDATE Kind B — must still trace the
# call site; see note below before concluding Kind B)
grep -rnE "document\.body\.(append|insertAdjacent)|createPortal|popover|<dialog|attachShadow.*body" src/

# Find tooltip CSS rules with hardcoded colors (any kind — A or B fail)
grep -nE "(tooltip|popover)[^{]*\{[^}]*(background|color):\s*#[0-9a-f]" src/css/
```

For each tooltip code path:

1. **Classify A / B / C by tracing the actual `container` argument at
   the instantiation site — NOT by reading the Tooltip/popover class's
   constructor default.**

   The Tooltip class commonly defaults to `document.body` (e.g.
   `opts.container ?? document.body`) — that's the standalone JS-class
   fallback. The web-component path usually overrides it: the Element
   class (`web-component.ts`) passes `container: this.shadow as unknown
   as HTMLElement` into the Logic class's options, which then flows
   down to `new Tooltip({ container, ... })`. The `document.body` fall-
   back never fires for the web-component path.

   Reading just the constructor default (or a Logic-class line like
   `this.options.container || document.body`) and concluding Kind B is
   a false positive. Both `@keenmate/web-multiselect` (`web-component.ts:639`)
   and `@keenmate/web-daterangepicker` (`web-component.ts:474`) follow
   the shadow-root-as-container pattern; tooltips in their web-component
   paths are **Kind A**, not Kind B.

   To classify correctly, walk the call chain in this order:
   - Find the `new Tooltip(...)` (or equivalent `appendChild(tooltipEl)`)
     site in the Logic class. Note the value passed as `container`.
   - That value is usually `this.options.container || document.body` or
     similar. Find where `this.options.container` is set — typically in
     the Logic-class constructor, fed from the Element class.
   - Find the Element class's call to `new <LogicClass>(...)`. Look for
     `container: this.shadow` (or equivalent shadow-root reference) in
     the options object.
   - **If the Element class passes the shadow root → Kind A.** The
     `document.body` line you see in the Logic class is dead code in
     the web-component path; it only fires if a consumer instantiates
     the Logic class directly with no `container` option.
   - **If no shadow-root override exists at any call site, or if the
     consumer-instantiation path is the only supported usage → Kind B.**
   - **If both paths are supported and divergent — document the duality
     (Kind A for web-component usage, Kind B for standalone) and verify
     the propagation mechanism for Kind B.**

   Also note: `target.getRootNode().host` does NOT return the shadow
   root — it returns the host element, which lives in light DOM. Don't
   propose patches that use `target.getRootNode().host` as the container
   thinking it will keep the tooltip in shadow scope.

2. Walk the variable chain back to a `light-dark()` literal — or, for
   confirmed Kind B, verify one of the three propagation mechanisms.
3. Cross-check with the dark-mode fixture (C-CS-5): the fixture
   should explicitly trigger the tooltip in dark mode.

**Pass:** Each tooltip kind the component uses has a verified theme
path. Each chain ends in a `light-dark()` literal or a
`--base-tooltip-*` read. Dark-mode fixture renders the tooltip with
≥ 4.5:1 contrast.

**Failure mode:** Tooltip in dark mode shows dark bg + dark text (or
light bg + light text). Reported as "looks broken in dark mode" by a
downstream consumer; the visual smoke test (C-CS-7) catches it last,
this check catches it earlier.

**Worked example (the bug family this check exists to prevent):**
`@keenmate/web-grid` shipped a tooltip whose dark-mode contrast was
broken — dark background, dark text — even though
`floating.css:.wg__tooltip` correctly read `var(--wg-tooltip-bg)` /
`var(--wg-tooltip-color)` and `variables.css` chained those through
`light-dark()`. The bug can take any of three shapes; the check
forces the developer to walk all three:

1. **Hardcoded literal in the tooltip rule.** A `color: #...` or
   `background: #...` that bypasses the variable chain entirely.
   Catches it: the script's auto sub-check (for dedicated tooltip
   CSS files) and Grep at the [semi] tier (for tooltip rules in
   shared files like `floating.css`).
2. **Variable chain anchored on a non-`light-dark()` literal.** A
   `--<prefix>-tooltip-color: var(--base-tooltip-color, #000)` —
   the chain looks fine but the final fallback doesn't flip. Catches
   it: walking the chain back to its terminus and confirming a
   `light-dark()` literal.
3. **Theme signal doesn't reach the tooltip element.** The tooltip
   variables are correctly defined on `:host`, but the tooltip DOM
   isn't under `:host` at render time (portaled outside — Kind B)
   or the `color-scheme: dark` flip doesn't propagate (some
   shadow-DOM rendering quirks with `display: contents` or `slot`
   reparenting). Catches it: Kind-B propagation verification + the
   `docs/test/dark-mode.html` fixture that explicitly opens a
   tooltip in dark mode.

**Exception:** A component with zero tooltips (no custom tooltip
element, no `title=""` usage in templates) is N/A. Cite the grep that
returned no matches.

**Companion check (geometry, not contrast):** C-CS-10 covers tooltip
*color* and theme propagation. Tooltip *geometry* (padding, font-size,
line-height, border-radius, max-width, box-shadow) has its own
canonical scale (`--base-tooltip-padding-*`, `--base-tooltip-font-size`,
…) and is enforced by **C-BV-14** in
[base-variables.checks.md](./base-variables.checks.md). Components
that ship a Kind A or Kind B tooltip should run both checks — C-CS-10
verifies the dark-mode contrast story; C-BV-14 verifies the
cross-component sizing story.

---

## Summary checklist

Paste into PR description, tick every box:

```
[ ] C-CS-1 [semi]   no bare :host { color-scheme: ... } (conditional ok)
[ ] C-CS-2 [auto]   light-dark() in color fallbacks
[ ] C-CS-3 [semi]   framework class selectors present (for chosen conventions)
[ ] C-CS-4 [manual] per-instance override works
[ ] C-CS-5 [auto]   contrast test fixture exists
[ ] C-CS-6 [semi]   Playwright contrast assertions pass
[ ] C-CS-7 [manual] visual smoke test passed
[ ] C-CS-8 [manual] docs/theming.md documents the color-scheme contract
[ ] C-CS-9 [semi]   CHANGELOG entry
[ ] C-CS-10 [semi]  tooltips render correct contrast in dark mode (in-shadow / portal / native)

Tier totals: 2 auto, 5 semi, 3 manual
```

If any box is unchecked, the work is not done.
