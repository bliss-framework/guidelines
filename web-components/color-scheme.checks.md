# Color-Scheme — Post-Implementation Checks

Run every check below **after** you finish writing the dark-mode CSS, and
**before** declaring the work done.

Each check has: what to look for, how to verify it, and what failure looks
like. Failing any check means the work is not complete. Mark each as ✅ pass
or ❌ fail in the PR description.

Read [color-scheme.md](./color-scheme.md) for the rationale behind each check.

---

## C-CS-1 — No `:host { color-scheme: ... }` declaration

**What:** The component must not declare `color-scheme` on `:host`. It blocks
the page's color-scheme from inheriting and is the #1 footgun.

**How to verify:**
```bash
grep -rn "color-scheme" src/css/
```

**Pass:** No match in any `:host { ... }` block. Matches only inside `@media`
queries, comments, or documentation are fine.

**Failure mode:** The component renders light even when the page sets
`body { color-scheme: dark }`.

---

## C-CS-2 — `light-dark()` in color fallbacks

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

**What:** Manually load the component in a browser and confirm dark mode
looks right.

**How to verify:** Start the dev server, navigate to the dark-mode fixture
page, and:

1. Confirm text is readable on every visible surface.
2. Hover over interactive elements — hover highlight is visible.
3. Click/focus elements — focus indicator is visible.
4. Open dropdowns, tooltips, popovers (if present) — their backgrounds are
   the right shade and text is readable.
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

## C-CS-8 — README documents the theming contract

**What:** The component's README lists which theme conventions it supports
and how consumers opt in.

**How to verify:** Open `packages/<component>/README.md` and find a section
covering:

- What `--base-*` variables the component reads (or link to manifest)
- Which `data-theme` attributes are honored on the host and on ancestors
- Which framework class conventions are honored
- How OS preference is picked up (`color-scheme` declaration required)
- Any deviations from default decisions made in D-CS-1 through D-CS-6

**Pass:** Section exists and is accurate. A new user could read the README
and know how to theme the component.

**Failure mode:** Consumers ask support questions that the README should have
answered.

---

## C-CS-9 — CHANGELOG entry

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

## Summary checklist

Paste into PR description, tick every box:

```
[ ] C-CS-1 No :host { color-scheme: ... }
[ ] C-CS-2 light-dark() in color fallbacks
[ ] C-CS-3 framework class selectors present (for chosen conventions)
[ ] C-CS-4 per-instance override works
[ ] C-CS-5 contrast test fixture exists
[ ] C-CS-6 Playwright contrast assertions pass
[ ] C-CS-7 visual smoke test passed
[ ] C-CS-8 README documents the theming contract
[ ] C-CS-9 CHANGELOG entry
```

If any box is unchecked, the work is not done.
