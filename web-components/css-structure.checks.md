# CSS Structure — Post-Implementation Checks

Run every check below **after** scaffolding (or refactoring) a component's
CSS structure, and **before** declaring the work done.

Each check: what to look for, how to verify, what failure looks like.
Failing any check means the work is not complete. Mark each as ✅ pass or
❌ fail in the PR description.

Read [css-structure.md](./css-structure.md) for rationale.

Each check is tagged **`[auto]`**, **`[semi]`**, or **`[manual]`**:

- **`[auto]`** — purely mechanical: a regex / shell one-liner returns a
  pass/fail verdict. Runnable in CI with no agent in the loop. See the
  companion script `css-structure.checks.sh` (TBD for this triad).
- **`[semi]`** — mostly mechanical but needs minimal context (e.g.,
  knowing the component prefix, web-component vs Svelte). Often runnable
  after a small detection prelude.
- **`[manual]`** — needs human or agent judgment: reading code in
  context, browser observation, or judging accuracy of prose.

---

## C-CSS-1 — Canonical file set present

**Tier:** `[auto]`

**What:** Tier-1 and Tier-2 files exist in `src/css/`, regardless of whether
they have content.

**How to verify (canonical strategy):**
```bash
cd packages/<component>/src/css
ls main.css variables.css base.css controls.css floating.css states.css \
   animations.css dark-mode.css 2>&1
```

**Pass:** All 8 files listed, no `No such file` errors.

**Failure mode:** A future feature has no obvious home, and the developer
invents a new ad-hoc file structure.

**Exception:** if D-CSS-1 chose lean strategy, this check doesn't apply.

---

## C-CSS-2 — No underscore-prefixed file names

**Tier:** `[auto]`

**What:** Every CSS file uses kebab-case without an underscore prefix.

**How to verify:**
```bash
ls packages/<component>/src/css/_*.css 2>&1
```

**Pass:** `No such file or directory` (no underscore-prefixed files exist).

**Failure mode:** Underscore prefix signals SASS partials, which these
aren't. Misleading.

**Exception:** if D-CSS-4 chose underscore convention (legacy), document the
exception in the README and skip this check.

---

## C-CSS-3 — `@layer` declared and used

**Tier:** `[auto]`

**What:** `main.css` declares the cascade-layer order and every `@import`
specifies its layer.

**How to verify:**
```bash
grep -n "@layer" packages/<component>/src/css/main.css
grep -n "@import" packages/<component>/src/css/main.css
```

**Pass:** Exactly one `@layer variables, component, overrides;` declaration
exists. Every `@import` line includes `layer(...)`.

**Failure mode:** Consumer can't predictably override the component's rules
without `!important` or specificity arms races.

**Exception:** if D-CSS-3 chose option C (no layers — legacy browser
support), document the exception.

---

## C-CSS-4 — Empty file stub comment

**Tier:** `[auto]`

**What:** Tier-2 files that have no content carry a one-line stub comment
explaining the intent.

**How to verify:**
```bash
for f in controls.css floating.css states.css animations.css; do
  path="packages/<component>/src/css/$f"
  if [ -s "$path" ]; then continue; fi    # has content; skip
  head -1 "$path" | grep -qE "^\s*/\*.*\*/\s*$" || echo "MISSING stub: $f"
done
```

**Pass:** Every empty Tier-2 file has a `/* ... */` stub on line 1.

**Failure mode:** Reader can't distinguish "empty on purpose" from "forgot."

---

## C-CSS-5 — Every file imported by `main.css`

**Tier:** `[auto]`

**What:** Every `.css` file in `src/css/` is imported by `main.css`. No
orphan files that aren't part of the bundle.

**How to verify:**
```bash
cd packages/<component>/src/css
ls *.css | grep -v "^main.css$" | while read f; do
  grep -q "@import.*['\"]\\./$f['\"]" main.css || echo "ORPHAN: $f"
done
```

**Pass:** Empty output (every file is imported, no orphans).

**Failure mode:** A new file is created but never loads. Or an old file
remains after a feature was removed.

---

## C-CSS-6 — Section banners on files > 100 lines

**Tier:** `[auto]`

**What:** Every file with more than 100 lines has at least one section
banner using the `/* === SECTION === */` format.

**How to verify:**
```bash
cd packages/<component>/src/css
for f in *.css; do
  lines=$(wc -l < "$f")
  if [ "$lines" -gt 100 ]; then
    grep -q "==========" "$f" || echo "MISSING banners: $f ($lines lines)"
  fi
done
```

**Pass:** Empty output.

**Failure mode:** Long files are hard to navigate.

**Adjust threshold per D-CSS-7 if a different choice was made.**

---

## C-CSS-7 — BEM convention followed

**Tier:** `[auto]` (requires component prefix as input)

**What:** Every CSS class begins with `<prefix>__` and uses `--` for
modifiers.

**How to verify:** Spot-check a feature file:
```bash
# Find classes that don't follow BEM
grep -oE "\.[a-z][a-z0-9_-]*" packages/<component>/src/css/*.css \
  | sort -u \
  | grep -v "^\.<prefix>__"
```

(Replace `<prefix>` with the actual component prefix.)

**Pass:** Empty output, or only matches inside pseudo-classes / pseudo-
elements (`.host:hover`, `.host::before`).

**Failure mode:** Drift over time — new classes that don't follow the
convention pollute the selector space.

**Exception:** if D-CSS-6 chose option B or C, document the deviation.

---

## C-CSS-8 — No hardcoded colors in feature files

**Tier:** `[auto]`

**What:** Color/border/shadow rules in feature files (`cells.css`,
`header.css`, etc.) consume `var(--...)`, not hex/rgb literals.

**How to verify:**
```bash
grep -nE "(background|color|border|box-shadow|fill|stroke):\s*(#[0-9a-f]|rgb)" \
  packages/<component>/src/css/*.css \
  | grep -v "variables.css" \
  | grep -v "dark-mode.css"
```

**Pass:** Empty output. Only `variables.css` and `dark-mode.css` may contain
literal colors.

**Failure mode:** Theme overrides don't reach the element. Cross-references
[base-variables.checks.md](./base-variables.checks.md) → C-BV-1.

---

## C-CSS-9 — No mixed-bag files

**Tier:** `[manual]` (requires reading each feature file)

**What:** Each file's content matches its name. No `dialogs.css` containing
both tooltips and modals.

**How to verify:** Open each Tier-3 file and confirm its rules all relate
to the one feature its name implies. A file with rules for two unrelated
features should be split.

**Pass:** Each file is focused on one feature.

**Failure mode:** Hard to find things. CSS for feature X is partly in
`feature-x.css` and partly in `dialogs.css`.

---

## C-CSS-10 — Layer contract documented in `docs/theming.md`

**Tier:** `[semi]` (section existence is mechanical; accuracy of
content is judgment)

**What:** The component's `docs/theming.md` (per the
[readme-structure](./readme-structure.md) triad — the home of the
theming contract since the README slim-down) describes the cascade
layer contract so consumers know how to override — *and* warns about
the unlayered-reset footgun **only if** this component is at risk of
that interaction (any component shipping `@layer component` rules
qualifies).

**How to verify:** Open `packages/<component>/docs/theming.md`, find
a "Cascade layers" / "Override contract" section, confirm it
mentions:

- The three `@layer` names (or whatever was chosen in D-CSS-3)
- The override contract ("any unlayered consumer rule wins")
- How to set `--base-*` and `--<prefix>-*` to theme
- The **unlayered-reset footgun**: a consumer-side `* { margin: 0;
  padding: 0; ... }` (Bootstrap reboot, Tailwind preflight,
  hand-rolled, etc.) is unlayered and therefore beats every rule in
  the component's `@layer component`, causing the component to render
  with broken spacing even though variables resolved correctly. The
  docs should tell consumers to wrap universal resets in their own
  layer (`@layer reset { * { ... } }`) so the library's layered
  defaults can win. See `css-structure.md` → "The unlayered-reset
  footgun" for the canonical write-up to lift.

**Pass:** Section exists, is accurate, and includes the unlayered-reset
warning.

**Failure mode:** Consumers reach for `!important` because they don't
realize the layer escape hatch exists — *or* consumers report
mysteriously broken spacing because a global reset is silently winning
against the component's layered defaults.

**Exception:** A component that pre-dates the readme-structure triad
can still pass if the information lives in `README.md` — flag for
the readme-structure migration (D-RS-6).

---

## C-CSS-11 — `main.css` has no rules

**Tier:** `[auto]`

**What:** `main.css` contains only `@layer`, `@import`, and comments — no
selector rules.

**How to verify:**
```bash
grep -nE "^[^@/]" packages/<component>/src/css/main.css | grep -v "^\s*$"
```

**Pass:** Empty output (every non-blank line starts with `@`, `/`, or is
whitespace).

**Failure mode:** Rules drift into the entry point and become hard to
find.

---

## C-CSS-12 — Bundle size sanity check

**Tier:** `[semi]` (requires running the build and comparing sizes
against a baseline)

**What:** Empty canonical files don't bloat the published bundle.

**How to verify:**
```bash
cd packages/<component>
npm run build
ls -lh dist/*.css 2>/dev/null  # or wherever your built CSS lands
```

**Pass:** Bundle size hasn't grown by more than ~200 bytes per empty file
(stub comment + import overhead).

**Failure mode:** Canonical strategy was supposed to be near-free; if empty
files are adding kilobytes, the bundler isn't tree-shaking comments or your
"empty" files have something in them.

---

## Summary checklist

Paste into PR description, tick every box:

```
[ ] C-CSS-1  [auto]   canonical file set present
[ ] C-CSS-2  [auto]   no underscore-prefixed file names
[ ] C-CSS-3  [auto]   @layer declared and used
[ ] C-CSS-4  [auto]   empty file stub comment present
[ ] C-CSS-5  [auto]   every file imported by main.css
[ ] C-CSS-6  [auto]   section banners on files > 100 lines
[ ] C-CSS-7  [auto]   BEM convention followed
[ ] C-CSS-8  [auto]   no hardcoded colors in feature files
[ ] C-CSS-9  [manual] no mixed-bag files
[ ] C-CSS-10 [semi]   layer contract documented in docs/theming.md
[ ] C-CSS-11 [auto]   main.css has no rules
[ ] C-CSS-12 [semi]   bundle size sanity check

Tier totals: 9 auto, 2 semi, 1 manual
```

If any box is unchecked, the work is not done.
