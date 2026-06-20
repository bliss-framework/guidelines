# README Structure — Post-Implementation Checks

Run every check below **after** writing or restructuring a
component's documentation, and **before** declaring the work done.

Each check: what to look for, how to verify, what failure looks
like. Failing any check means the work is not complete. Mark each
as ✅ pass, ❌ fail, ⚠️ exception (with reason), or N/A in the PR
description.

Read [readme-structure.md](./readme-structure.md) for rationale and
[readme-structure.decisions.md](./readme-structure.decisions.md) for
the matching decision tags.

Each check is tagged **`[auto]`**, **`[semi]`**, or **`[manual]`** —
see [css-structure.checks.md](./css-structure.checks.md) for the
meaning of each tier.

---

## C-RS-1 — `README.md` exists at the package root

**Tier:** `[auto]`

**What:** A `README.md` file is present at the package root.

**How to verify:**
```bash
test -f packages/<component>/README.md && echo ok || echo missing
```

**Pass:** The file exists.

**Failure mode:** npm publishes the package with no landing page;
GitHub shows the bare repo tree.

**Tag:** D-RS-6.

---

## C-RS-2 — `README.md` is under 400 lines

**Tier:** `[auto]`

**What:** The README is no longer than 400 lines. Soft target: 200.

**How to verify:**
```bash
wc -l < packages/<component>/README.md
```

**Pass:** ≤ 400.

**Failure mode:** Content has leaked from `docs/` back into the
README — usually the theming contract, the full API table, or the
examples cookbook. Move it back.

**Exception:** A documented one-off (e.g. an extensive support-table
the team explicitly wants on the landing page) can push past 400 if
the PR description names the section and the team signs off.

**Tag:** D-RS-6.

---

## C-RS-3 — `docs/` folder exists with the required files

**Tier:** `[auto]`

**What:** The package has a `docs/` folder containing `usage.md`,
`theming.md`, `examples.md`, and (unless D-RS-2 = B) `accessibility.md`.

**How to verify:**
```bash
ls packages/<component>/docs/
```

Expect: `usage.md`, `theming.md`, `examples.md`, `accessibility.md`.

**Pass:** All four files exist (three if D-RS-2 = B, with
README-side a11y paragraph in lieu).

**Failure mode:** Deep docs got pushed into the README, or the
README links to files that don't exist.

**Tag:** D-RS-2.

---

## C-RS-4 — README links to every `docs/` file at least once

**Tier:** `[auto]`

**What:** The README's "Demos & docs" section (or equivalent) links
to each `docs/*.md` file using a relative path.

**How to verify:**
```bash
grep -E "\(\.\/docs\/(usage|theming|examples|accessibility)\.md\)" \
  packages/<component>/README.md
```

Expect one match per existing `docs/` file.

**Pass:** Every existing `docs/` file is linked from the README at
least once, via a relative path.

**Failure mode:** Visitors can't discover the deep docs; deep docs
exist but go unread.

**Tag:** D-RS-6.

---

## C-RS-5 — README has the canonical section headings

**Tier:** `[auto]`

**What:** The README contains headings matching the canonical
section list in [readme-structure.md](./readme-structure.md): a
"What is it" intro, "Install", "Quick start" (or equivalent), and
"License".

**How to verify:**
```bash
grep -E "^## (What is it|Install|Quick start|Quick demo|License)" \
  packages/<component>/README.md
```

Expect at least one heading per required section.

**Pass:** Required headings present (exact wording may vary but
intent must match).

**Failure mode:** The landing page skips orientation, jumps straight
into code, or never shows the install command.

**Tag:** D-RS-6.

---

## C-RS-6 — README "What is it" is tight

**Tier:** `[semi]`

**What:** The "What is it" / intro section is 1–3 short paragraphs
and under ~30 lines, focused on value proposition and audience.

**How to verify:** Read the section. Count the paragraphs and
lines.

**Pass:** ≤ 30 lines, 1–3 paragraphs, says *what* the component is
and *who it's for*.

**Failure mode:** The intro is a wall of feature bullets, or jumps
into API discussion before the visitor knows what they're looking
at.

**Tag:** D-RS-6.

---

## C-RS-7 — README "What's new" links `CHANGELOG.md`

**Tier:** `[semi]`

**What:** Per D-RS-5, the README has a "What's new" section that
mentions the latest version and links to `CHANGELOG.md` (or omits
the section per D-RS-5 = C).

**How to verify:**
```bash
grep -E "What'?s new|CHANGELOG\.md" packages/<component>/README.md
```

**Pass:** Section present and links `./CHANGELOG.md`, OR D-RS-5 = C
with `CHANGELOG.md` linked from "Demos & docs".

**Failure mode:** Visitors can't tell whether the component is alive,
when it last released, or where to find release history.

**Tag:** D-RS-5.

---

## C-RS-8 — Deployed demo link is present and current

**Tier:** `[semi]`

**What:** Per D-RS-1, the README links to a deployed demo (unless
D-RS-1 = D). The link returns 200.

**How to verify:** Open the URL in a browser; check it loads the
expected demo. Or:
```bash
curl -sI <demo-url> | head -1
```

**Pass:** Link present, returns 200, demo loads the current version
of the component.

**Failure mode:** Demo link points at a 404 or at a stale version
that doesn't match the current API.

**Exception:** D-RS-1 = D (no deployed demo) — mark N/A and note
the package is private/internal.

**Tag:** D-RS-1.

---

## C-RS-9 — Quick-start snippet actually runs

**Tier:** `[manual]`

**What:** The code in the README's "Quick start" section, copy-
pasted into a fresh HTML page with the install command from the
README, renders a working instance of the component.

**How to verify:** Set up a clean folder. Run the install command.
Paste the quick-start HTML. Open in a browser. Confirm the
component renders and the basic interaction (whatever the snippet
shows) works.

**Pass:** Renders correctly. No console errors. The shown
interaction works.

**Failure mode:** Snippet drifted from the current API; consumers
following the README hit immediate errors and lose trust.

**Tag:** D-RS-6.

---

## C-RS-10 — `docs/usage.md` covers the full public surface

**Tier:** `[semi]`

**What:** `docs/usage.md` documents every public attribute / prop,
event / callback, slot, and imperative method the component exposes.
For web-components, the `ATTRIBUTE_TABLE` (per C-NC-7) is reflected
here.

**How to verify:** Read `docs/usage.md`. Compare its tables against
the source: `ATTRIBUTE_TABLE` for attributes, the `dispatchEvent`
call sites for events, the public methods on the Element class.
Flag any source-only entries.

**Pass:** Every public surface item has a row in `docs/usage.md`
with type, default, and intent.

**Failure mode:** Consumers reverse-engineer the API from source or
TypeScript types instead of reading the docs.

**Tag:** D-RS-6.

---

## C-RS-11 — `docs/theming.md` covers the four contracts

**Tier:** `[semi]`

**What:** `docs/theming.md` covers the container contract (per
C-TC-11), the variable contract (per C-BV-8), the color-scheme
strategy (per C-CS-8), and the cascade-layer contract (per
C-CSS-10). This file is the **single home** for those four contracts;
none of them live in the README anymore.

**How to verify:** Read `docs/theming.md`. Confirm sections for:
container element + framework conventions, `--base-*` and
`--<prefix>-*` overrides with one example each, per-instance dark
mode + framework class selectors, `@layer` order with consumer
override guidance.

**Pass:** All four contracts covered.

**Failure mode:** Theming docs scattered (some in README, some in
`docs/`); consumers don't know where to look. Or the file references
the theming triads but doesn't reproduce the consumer-facing
contract.

**Tag:** D-RS-6.

---

## C-RS-12 — `docs/examples.md` has at least one worked example

**Tier:** `[semi]`

**What:** `docs/examples.md` (or `docs/examples/` per D-RS-3 = B)
contains at least one worked example **beyond** the README's quick
start.

**How to verify:** Read the file. Confirm at least one example
section that's not a copy of the README quick start.

**Pass:** ≥ 1 distinct example present.

**Failure mode:** Consumers hit a configuration that's not in the
quick start and have no reference for how anyone else solved it.

**Tag:** D-RS-3.

---

## C-RS-13 — `docs/accessibility.md` covers keyboard + ARIA + focus

**Tier:** `[semi]` (N/A if D-RS-2 = B)

**What:** `docs/accessibility.md` documents keyboard navigation,
ARIA roles/states/properties, screen-reader behavior, and focus
management. For each interactive surface the component exposes.

**How to verify:** Read the file. Confirm sections for: keyboard
keys (Tab / Shift+Tab / Enter / Space / Esc / arrows / Home / End,
as applicable), ARIA attributes set by the component, focus on
open/close/destroy.

**Pass:** All four areas covered.

**Failure mode:** Auditors / a11y consumers can't determine
compliance; assistive-tech users hit unexpected behavior.

**Exception:** D-RS-2 = B (display-only component) — mark N/A and
confirm the README's "Accessibility notes" paragraph is present.

**Tag:** D-RS-2.

---

## C-RS-14 — README acknowledges BlissFramework guidelines and links to `blissframework.dev`

**Tier:** `[auto]`

**What:** The README contains both a mention of the **BlissFramework
component guidelines** (the rulebook this component follows) and an
absolute link to **`https://blissframework.dev/`** (or
`https://blissframework.dev/...`, e.g. a deep link into the
guidelines section). Recommended placement: a short "Built with
BlissFramework" paragraph in a dedicated footer-style section
between *Browser support* and *License*, or folded into the
*License* section.

**How to verify:**
```bash
grep -E "https?://blissframework\.dev"      packages/<component>/README.md  # link present
grep -iE "blissframework|guidelines?"       packages/<component>/README.md  # attribution prose present
```

Both must match. A single line such as

> Built following the [BlissFramework component guidelines](https://blissframework.dev/).

satisfies the rule.

**Pass:** The README contains a `blissframework.dev` link *and* at
least one mention of "BlissFramework" or "guidelines" (case
insensitive).

**Failure mode:** Visitors can't trace the component back to the
shared rulebook — they assume it's a one-off and rebuild conventions
that already exist, or they miss the theming / accessibility
contracts that the guidelines cross-link into.

**Exception:** Components published under a fork or white-label
brand may use a brand-equivalent URL — document the deviation in
`VALIDATION-NOTES.md` under a `## C-RS-14 — white-label attribution`
heading citing the consumer-facing URL.

**Tag:** D-RS-6.

---

## C-RS-15 — README has the canonical `## About` paragraph (KeenMate + Pure Admin)

**Tier:** `[auto]`

**What:** The README contains the canonical **About** paragraph
defined in [readme-structure.md](./readme-structure.md) → "`## About`
— canonical text". The paragraph names KeenMate as the author,
states the component ships standalone, names Pure Admin as the
auto-theming host, and references the `--base-*` taxonomy as the
integration mechanism.

The paragraph is the **same** in every component README — it's the
single source of truth for how the components relate to KeenMate
and to Pure Admin. Today's components carry contradictory and
factually wrong claims ("Created by KeenMate as part of the Pure
Admin design system" / "Extracted from the Pure Admin design
system"); this check forces convergence on the canonical text.

**How to verify:**

```bash
# Heading (## About, or — transition period — ## Credits)
grep -E "^## (About|Credits)" packages/<component>/README.md

# Author attribution
grep -iE "KeenMate" packages/<component>/README.md

# Pure Admin reference (link or prose)
grep -iE "Pure Admin|pureadmin" packages/<component>/README.md

# Standalone claim
grep -iE "standalone" packages/<component>/README.md

# Integration mechanism (--base-* taxonomy)
grep -E "\-\-base-\*" packages/<component>/README.md
```

All five greps must match. The auto-script bundles them and reports
which token is missing if any fail.

**Pass:** The README contains a `## About` (or `## Credits` during
transition) section that mentions KeenMate, Pure Admin, the word
"standalone", and the `--base-*` taxonomy. Components adopting the
canonical text verbatim pass automatically.

**Failure mode:** Each component invents its own attribution wording.
Some claim Pure Admin extraction (wrong), some omit Pure Admin
entirely (no signal to consumers about the auto-theming), some
omit KeenMate (no author attribution). Consumers reading two
component READMEs side-by-side get conflicting stories about the
relationship between the components and Pure Admin.

**Transition note:** Components shipping a `## Credits` section
satisfy the heading grep during the transition. The recommended
move is to rename to `## About` when next touching the README; the
canonical-layout table in [readme-structure.md](./readme-structure.md)
puts `About` between Browser support and Built with BlissFramework.

**Exception:** White-label / fork builds may replace KeenMate +
Pure Admin references with brand-equivalent equivalents — document
the deviation in `VALIDATION-NOTES.md` under a
`## C-RS-15 — white-label attribution` heading.

**Tag:** D-RS-6.

---

## C-RS-16 — `## What's New in vX.Y.Z` sections follow the canonical format

**Tier:** `[auto]`

**What:** The README contains at least one (and at most two)
`## What's New in vX.Y.Z` section(s), each one matching the
canonical format defined in
[readme-structure.md](./readme-structure.md) → "`## What's New in
vX.Y.Z` — canonical format":

1. **Heading shape** — `## What's New in v<semver>` (lowercase
   `v`, no backticks around the version, no date).
2. **Section count** — exactly 1 or 2 sections. Three or more
   means the publish step's trim pass was skipped; older releases
   belong in `CHANGELOG.md`, not in the README.
3. **Bullet pattern** — every bullet in a `What's New` section
   starts with `- **` (bold-opened lead phrase) and contains
   ` — ` (a true em-dash separator, U+2014, with surrounding
   spaces) between the bold lead phrase and the prose body. Plain
   hyphens or en-dashes don't satisfy the rule.
4. **No sub-headers** — no `### Added` / `### Fixed` headings
   inside a `What's New` section. The structured Added/Changed/
   Fixed split lives in `CHANGELOG.md`. What's New is a flat
   list.

The format exists so a reader who has skimmed one component's
release highlights knows what to expect from the next, and so the
`/publish` slash-command in every repo drafts new sections in the
same shape rather than each one inventing its own.

**How to verify:**

```bash
# 1) At least one canonical heading is present
grep -cE "^## What's New in v[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?$" \
  packages/<component>/README.md

# 2) At most two canonical headings are present
[ "$(grep -cE "^## What's New in v" packages/<component>/README.md)" -le 2 ]

# 3) Every bullet directly under such a heading starts with `- **`
#    and contains ` — ` (em-dash + spaces). The .checks.sh script
#    walks each section's body and counts violations.

# 4) No `### ` sub-heading inside any `What's New` block.
```

The auto-script bundles checks 1–4 and reports which bullets fail
the lead-phrase / em-dash pattern.

**Pass:** 1 or 2 canonical headings present; every bullet under
them matches the `- **…** — …` pattern; no `### ` sub-headings
inside the section.

**Failure mode:** Each release ends up advertised in a different
format — some sections use plain bullets, some use `### Added` /
`### Fixed` sub-headers lifted from CHANGELOG, some use emoji
prefixes, some skip the bold lead phrase. Readers comparing two
component READMEs side-by-side see inconsistent voices; the
publish slash-command's draft step has no canonical target to
aim for.

**Exception:** D-RS-5 = C (no "What's new" section at all — see
the decision in `readme-structure.decisions.md`) — mark N/A and
confirm the CHANGELOG link has moved to "Demos & docs" instead.

**Tag:** D-RS-5.

---

## Summary checklist (paste into PR description)

```
[ ] C-RS-1  [auto]   README.md exists at package root
[ ] C-RS-2  [auto]   README.md ≤ 400 lines (target 200)
[ ] C-RS-3  [auto]   docs/ folder has usage / theming / examples / accessibility (last per D-RS-2)
[ ] C-RS-4  [auto]   README links every docs/ file at least once (relative path)
[ ] C-RS-5  [auto]   README has canonical section headings (What is it / Install / Quick start / License)
[ ] C-RS-6  [semi]   README "What is it" is tight (≤ 30 lines, 1–3 paragraphs)
[ ] C-RS-7  [semi]   README "What's new" links CHANGELOG.md (or D-RS-5 = C)
[ ] C-RS-8  [semi]   Deployed demo link present and returns 200 (or D-RS-1 = D)
[ ] C-RS-9  [manual] Quick-start snippet actually runs in a clean install
[ ] C-RS-10 [semi]   docs/usage.md covers full public surface (attributes, events, slots, methods)
[ ] C-RS-11 [semi]   docs/theming.md covers container + variable + color-scheme + layer contracts
[ ] C-RS-12 [semi]   docs/examples.md has at least one worked example beyond the README quick start
[ ] C-RS-13 [semi]   docs/accessibility.md covers keyboard + ARIA + focus (N/A if D-RS-2 = B)
[ ] C-RS-14 [auto]   README acknowledges BlissFramework guidelines + links to blissframework.dev
[ ] C-RS-15 [auto]   README has canonical ## About paragraph (KeenMate + Pure Admin + standalone + --base-*)
[ ] C-RS-16 [auto]   ## What's New in vX.Y.Z sections follow canonical format (1–2 sections, `- **…** — …` bullets, no sub-headers)
```
