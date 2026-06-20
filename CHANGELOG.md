# Changelog

All notable changes to the web-component guidelines and tooling in this
repository. Entries are grouped by date, newest first. This repository is
not versioned — date blocks replace version numbers.

Categories used: **Added**, **Changed**, **Removed**, **Fixed**.

---

## 2026-06-18

### Added

- **New canonical `## What's New in vX.Y.Z` format and check `C-RS-16` —
  every component's README release-highlights section follows the same
  shape across the suite.** Before this, each component's README
  invented its own "What's new" section: `web-multiselect`,
  `web-daterangepicker`, and `web-grid` used lowercase `## What's new`
  with a one-line summary + CHANGELOG link; `svelte-treeview` used
  `## What's New in vX.Y.Z` with bullets but used `:` as the lead-phrase
  separator; only `svelte-fluentui` (`README.md` v1.3.3 / v1.3.2 at the
  workspace root) had the polished engineer-to-engineer format the team
  actually wanted to standardize on. The canonical format codifies that
  voice: heading `## What's New in v<semver>` (lowercase `v`, no
  backticks around the version, no date); each bullet `- **<area or
  component> — <one-line headline>** — <engineer-level prose>`; the prose
  body is 3–8 sentences explaining *what* changed, *why* (regression
  history / motivation), *what surface* is affected (concrete component
  / prop / file names listed inline, not vaguely "several wrappers"),
  and *the mechanism* (the CSS / JS / DOM technique used); a true
  em-dash (` — `, U+2014 with surrounding spaces) separates the bold
  lead phrase from the prose; no `### Added` / `### Fixed` sub-headings
  inside the section; at most two `## What's New in vX.Y.Z` sections in
  the README at any time. The `/publish` slash-command in each
  component repo drafts new sections in this shape and C-RS-16 enforces
  it on every release.
  - Tier: `[auto]`. The check verifies four things: (1) at least one
    canonical-shape heading is present, (2) at most two sections live in
    the README (older release notes belong in `CHANGELOG.md`),
    (3) every bullet directly under a `What's New` heading starts with
    `- **` and contains ` — ` (true em-dash + surrounding spaces) between
    the bold lead phrase and the prose body, (4) no `### ` sub-headers
    appear inside a section. Loose `## What's new` headings without a
    semver version fail with a "non-canonical heading" diagnostic
    pointing at the offending line. A `D-RS-5 = C` exception (no
    What's-new section, CHANGELOG.md linked from Demos & docs instead)
    skips the check.
  - Files touched: `readme-structure.md` (new "## `## What's New in
    vX.Y.Z` — canonical format" section after the canonical About-text
    block; canonical-layout table's What's-new row now points at it),
    `readme-structure.checks.md` (new C-RS-16 entry; summary checklist
    extended), `readme-structure.checks.sh` (heading regex, section-count
    cap, awk-based bullet scan with em-dash byte-match `\xe2\x80\x94`,
    sub-header detection), `README.md` index (readme-structure row bumps
    from 7/7/1 = 15 to 8/7/1 = 16).

- **New `publish-command` triad — canonical `/publish` slash-command
  structure unifying release flows across every component repo.**
  Each component (`web-multiselect`, `web-grid`,
  `web-daterangepicker`, `svelte-fluentui`, `svelte-treeview`,
  `web-treeview`, `svelte-switch`, `web-switch`) ships a
  `.claude/commands/publish.md` that an agent reads when the user
  types `/publish rc` (or `release` / `patch` / `minor` / `major`).
  Before this triad, every component's `/publish` had subtle drift:
  some did an `npm view` registry pre-check ("is this version already
  published?") and some didn't (`svelte-fluentui` notably — so a
  re-publish over an already-published rcN ran the entire flow,
  failed only at `npm publish`, and left a bogus `[PUBLISHED]`-tagged
  commit on HEAD); the version-resolution decision table for rc /
  release / patch / minor / major varied; the bullet-count target for
  What's-new drafts ranged from 5–7 to 5–8; `svelte-treeview`
  uniquely used the `## [Unreleased]` accumulator convention while
  everyone else used `[PUBLISHED]`-tag-on-WIP. None of those
  differences had a reason — they were artifacts of each command being
  scaffolded separately. The canonical spec defines 14 sections in
  order: Argument → Repo layout → CHANGELOG convention → Resolve
  versions → Steps (1 Sanity checks → 2 Bump version → 3 Finalize
  CHANGELOG → 4 Update README "What's New" → 5 Validate README →
  6 Validate CHANGELOG → 7 Run tests → 8 Build → 9 Verify pack
  contents → 10 Commit → 11 Report) → Things not to do. Sections tagged
  `[canonical]` must appear byte-identical across every per-repo file
  (modulo declared variable substitutions: `{{PKG_NAME}}`,
  `{{PKG_JSON_PATH}}`, `{{NEXT_RC_EXAMPLE}}`, etc.); sections tagged
  `[per-repo]` (Repo layout, Tests, Build, Verify pack) carry the
  genuinely-structural differences (monorepo vs single-package paths,
  `make package` vs `npm run build` vs `npm run package` with custom
  pre/post hooks, Playwright vs vitest vs type-check-only).
  - Tier: 11 checks, all `[auto]`. **C-PC-0** verifies the file
    exists at `.claude/commands/publish.md`. **C-PC-1** verifies all
    17 canonical section headings appear in the correct order with
    the right `[canonical]` / `[per-repo]` tag. **C-PC-2** verifies
    Step 1 contains both `npm view <pkg>@<version>` (the
    "already published?" stop) and `npm view <pkg> version` (the
    "registry drifted past you?" warn) — the single most important
    pre-check, missing from `svelte-fluentui` before this triad
    landed. **C-PC-3** md5-compares the version-resolution decision
    table against the reference (web-multiselect by default; override
    via `PUBLISH_REFERENCE` env var). **C-PC-4** md5-compares the
    first ~10 bullets of the "Things not to do" block (per-repo extras
    after a `### Repo-specific don'ts` sub-heading don't count).
    **C-PC-5** verifies Step 1's draft-What's-New block references
    `readme-structure.md → 'canonical format'` and names auto-check
    `C-RS-16` — the bridge between the publish flow and the README
    structure rule. **C-PC-6** verifies the canonical commit message
    template (`vNEW_VERSION - <one-line summary>` subject + grouped
    bullets body + `Co-Authored-By: Claude Opus 4.7 (1M context)`
    trailer) appears in Step 10. **C-PC-7** verifies the file's
    intro paragraph references `web-components/publish-command.md`
    (anchors the per-repo file to the spec for future contributors).
    **C-PC-8** verifies every heading carries the correct
    `[canonical]` / `[per-repo]` tag from a 15-entry expected-tags
    table. **C-PC-9** verifies Step 1's draft block uses the canonical
    "5–8 scannable bullets" target (catches the historical 5–7 drift).
    **C-PC-10** verifies Step 10's stage list mentions `CHANGELOG.md`,
    `README.md`, and `package.json` at minimum.
  - Files added: `publish-command.md` (canonical spec — 14 sections of
    required text plus the variable-contract table), `publish-command.checks.md`
    (C-PC-0 through C-PC-10 with verification commands, pass / fail /
    failure-mode prose, and the summary checklist), `publish-command.checks.sh`
    (executable `[auto]` runner — takes a component repo path, locates its
    publish.md, runs all 11 checks; md5 comparisons use a configurable
    reference file). `README.md` index gains a new triad row
    (11 auto / 0 semi / 0 manual = 11) and a "When to consult" entry;
    totals 55 auto / 31 semi / 15 manual = 101 checks (was 90).
  - Verification: ran `publish-command.checks.sh` against all 8
    components — each scores 11/11 PASS after the per-repo
    `.claude/commands/publish.md` files were rewritten against the spec
    (those file rewrites live in the component repos, not here). md5 of
    the canonical "Things not to do" block
    (`730308ed1be73a99d5944fb085323630`), the version-resolution
    decision table (`df919fa505f2a5c9b2946e5c85a54dbc`), and Step 5
    "Validate README reflects the release"
    (`6b98d4e0df7c6c00d6515a5298ccf757`) is identical across every
    component.

---

## 2026-06-16

### Added

- **New canonical `## About` paragraph and check `C-RS-15` — README
  carries the same authorship + Pure Admin auto-theming statement
  in every component.** Today's component READMEs say different and
  factually wrong things: `web-multiselect` claims "Created by
  KeenMate as part of the Pure Admin design system" and
  `web-daterangepicker` claims "Extracted from the Pure Admin design
  system". Both are wrong — the components live independently of
  Pure Admin, weren't extracted from it, and several KeenMate
  components predate the Pure Admin integration entirely. The
  canonical paragraph fixes four things at once: (1) authorship is
  unambiguous ("Authored and maintained by KeenMate" — no "as part
  of", no "extracted from"); (2) standalone is the default
  ("ships standalone with sensible light/dark defaults"); (3) Pure
  Admin theming is opt-in, not a dependency ("There is no runtime
  dependency on Pure Admin; the integration is opt-in via CSS
  variables"); (4) the integration mechanism is named
  (`--base-*` taxonomy + `@keenmate/theme-designer`). Canonical
  placement is a new `## About` section between *Browser support*
  and *Built with BlissFramework*. C-RS-15 is independent of C-RS-14
  (BlissFramework attribution) — About answers *who built it and
  what it integrates with*; Built with BlissFramework answers *what
  rulebook it follows*. The check accepts `## Credits` as the
  heading during the transition period, but the canonical layout
  shows `## About` so new components and rewrites converge.
  - Tier: `[auto]`. Tier totals updated to 43 auto / 31 semi / 15
    manual = 89 total; readme-structure row bumps from 6/7/1 = 14
    to 7/7/1 = 15. The auto check is five greps — heading
    (`## About` or `## Credits`), KeenMate attribution, Pure Admin
    reference, "standalone" wording, `--base-*` taxonomy reference
    — failing with a "missing: <X>" message that names whichever
    piece is absent.
  - Files touched: `readme-structure.md` (canonical-layout table
    gets a new "About" row + new `## About — canonical text`
    section with the paragraph, the rationale for each clause, and
    the placement guidance; worked example shows the section
    between Browser support and Built with BlissFramework),
    `readme-structure.checks.md` (C-RS-15 spec with five-grep
    verification + transition note about `## Credits` heading +
    white-label exception via `VALIDATION-NOTES.md` + summary
    checklist), `readme-structure.checks.sh` (mechanical check
    with five greps + named-token failure messages),
    `web-components/README.md` (tier-totals table),
    `/validate-readme-structure` (frontmatter description, Step 1
    + Step 3 prose, Step 5 "Result: N / 15 passing"),
    `/validate-web-component` (Step 3 prose + table, Step 7 + Step 8
    result tables, Step 5 invariant prose count, Step 7
    readme-structure semi/manual header, PR-ready checklist,
    Discipline footer).

- **New canonical `--base-tooltip-*` geometry scale and check `C-BV-14`
  — tooltip geometry consumes the canonical scale.** Today's KeenMate
  components paint tooltips with independently invented sizing:
  web-multiselect uses padding `0.8rem 1.2rem`, font-size `sm` (1.4),
  border-radius `lg` (0.8), line-height `relaxed` (1.75), max-width
  32 rem, and a soft shadow; web-daterangepicker uses `0.4rem 0.8rem`,
  font-size `xs` (1.2), border-radius `sm` (0.4), line-height `1.4`,
  max-width 20 rem, and no shadow. Same Floating UI engine, ~2× the
  density difference. Mounted on the same page they look like they
  come from different libraries. The fix is a canonical scale in the
  `--base-*` taxonomy — seven knobs (`padding-block`, `padding-inline`,
  `font-size`, `line-height`, `border-radius`, `max-width`,
  `box-shadow`) with compact-middle-ground defaults that sit between
  drp's tight numbers and ms's loose ones (`padding 0.6/1.0`, `xs`
  font, `1.5` line-height, `sm` radius, `28` rem max-width, soft
  shadow). Every component reads the same defaults; consumers wanting
  divergent looks override the `--<prefix>-tooltip-*` layer locally.
  C-BV-14 enforces consumption: every tooltip-geometry property in
  every tooltip rule must resolve through a `--base-tooltip-*` chain;
  hardcoded literals fail. C-BV-14 is the geometry companion to
  C-CS-10 (which covers tooltip *color* / theme propagation) — cross-
  linked in both directions.
  - Tier: `[semi]`. Tier totals updated to 42 auto / 31 semi / 15
    manual = 88 total; base-variables row bumps from 6/3/3 = 12 to
    6/5/3 = 14.
  - Files touched: `base-variables.md` (new "Layout — tooltips"
    sub-table with the seven knobs and compact-middle-ground
    defaults), `base-variables.decisions.md` (D-BV-2 gains a row
    pointing at the new variables and C-BV-14), `base-variables.checks.md`
    (C-BV-14 spec + summary checklist), `base-variables.checks.sh`
    (skip-list mentions C-BV-14), `color-scheme.checks.md` (C-CS-10
    gains a "companion check (geometry, not contrast)" pointer at
    C-BV-14), `web-components/README.md` (tier-totals table),
    `/validate-base-variables` (frontmatter description, Step 1 +
    Step 4 prose, Step 4 canonical-taxonomy header, Step 5 report
    template, "Result: N / 14 passing"), `/validate-web-component`
    (Step 3 prose, Step 4 base-variables prose, Step 5 invariant
    prose count, Step 7 + Step 8 result tables, Step 7 base-variables
    semi/manual header, PR-ready checklist).

- **New check `C-BV-13` — input controls consume the canonical
  `--base-input-size-*-height` scale.** The five-tier input height
  scale (`xs` 3.1 / `sm` 3.3 / `md` 3.5 / `lg` 3.8 / `xl` 4.1) has
  been in the canonical taxonomy and the Theme Designer for months,
  but D-BV-2 carried it as an opt-in checkbox ("if the component has
  multiple input size variants") and no check enforced consumption.
  Components could — and did — hardcode `height: 32px`. C-BV-13
  closes the loop: any rule that paints a form-control surface
  (editor cell, combobox trigger, autocomplete input, date input,
  picker chip) MUST resolve its height through
  `var(--base-input-size-<tier>-height, …)` via the
  `--<prefix>-input-height*` layer. The D-BV-2 row gets stronger
  language ("required for any component with input controls — at
  minimum `md`"). Inline editors whose height tracks the row height
  are exempt; structural chrome (headers, toolbars, scrollbars) is
  exempt. The manifest's `baseVariables` must list every tier the
  component reads (overlap with C-BV-6).
  - Tier: `[semi]`. Counted in the same totals bump as C-BV-14
    above.
  - Files touched: same five locations as C-BV-14 — the additions
    are co-located.

- **New check `C-RS-14` — README acknowledges the BlissFramework
  guidelines and links to `blissframework.dev`.** Today a consumer
  landing on a component's npm page has no breadcrumb back to the
  shared rulebook: they assume the structure / theming / a11y
  contracts are one-off conventions and either reinvent them in their
  own integration or miss the deeper docs entirely. The new check
  requires both an absolute link to `https://blissframework.dev/`
  *and* a "BlissFramework" / "guidelines" mention somewhere in the
  README. Recommended placement: a short "Built with BlissFramework"
  section between *Browser support* and *License* (one paragraph,
  one link). White-label / forked builds may swap the URL with a
  `VALIDATION-NOTES.md` entry citing the brand-equivalent home.
  - Tier: `[auto]`. Tier totals updated to 42 auto / 29 semi / 15
    manual = 86 total; readme-structure row bumps from 5/7/1 = 13
    to 6/7/1 = 14. The auto check is two greps — one for the URL,
    one for the prose — failing with a "missing: <X>" message that
    names whichever piece is absent so the fix is unambiguous.
  - Files touched: `readme-structure.md` (canonical-layout table
    gets a "Built with BlissFramework" row + worked-example shows
    the recommended paragraph), `readme-structure.checks.md`
    (C-RS-14 spec + summary checklist), `readme-structure.checks.sh`
    (mechanical check), `web-components/README.md` (tier-totals
    table), `/validate-readme-structure` (frontmatter description,
    Step 3 lists C-RS-14 among the six auto checks, report header
    "/ 14"), `/validate-web-component` (Step 3 prose + table,
    Step 7 + Step 8 result tables, Step 5 invariant prose,
    Step 8 section header, PR-ready checklist, Discipline footer).

### Changed

- **`/validate-web-component` Step 8 punch-list — new "About this
  report" preamble.** Anyone reading `validation_<timestamp>.md`
  cold (a developer who didn't run the validator, a reviewer
  triaging the PR) had no signal that some "Fixes to apply" entries
  might be false positives that belong as `VALIDATION-NOTES.md`
  acknowledgments rather than code edits. The preamble now sits
  right under the report header and (1) explains that the punch-list
  is a snapshot, (2) names `VALIDATION-NOTES.md` as the register
  that downgrades a flag from `❌ Fail` to `✅ Pass` / `⚠️ Exception`
  on subsequent runs, (3) gives a three-step "before treating an
  entry as a developer task" decision tree (fix it / document it /
  acknowledge it), and (4) re-states the discipline that deferrals
  are not valid register entries — they get re-promoted to Fails on
  every run by design.
- **`/validate-web-component` — new Step 9 interactive follow-up.**
  After the chat report and punch-list file are written, the
  validator now walks two prompts so the user can act on findings
  while the context is fresh, instead of leaving the developer to
  manually append `VALIDATION-NOTES.md` entries on a future round.
  - **9a — Offer to record undocumented exceptions.** Collect every
    item the punch-list flagged as "⚠️ Exception that is not yet
    documented" (the bucket-2 entries where the validator already
    drafted the exact `VALIDATION-NOTES.md` paragraph). List them
    in chat with the proposed paragraph and ask which to append
    now. For accepted items, `Edit` `VALIDATION-NOTES.md` to
    append (creating the file with a `# Validation notes —
    accepted deviations` header if it doesn't exist) and prompt
    the user to re-run validation to see the downgraded verdicts.
    Declined items stay in the punch-list to re-surface next round.
  - **9b — Offer to tackle deferred entries already in
    `VALIDATION-NOTES.md`.** Surface the running list of deferral
    entries collected during Step 2.5 (entries whose body is
    "we'll fix this later" rather than an architectural reason).
    Per policy these are already re-promoted to ❌ Fail every run,
    but developers often don't realize an old deferral is still
    counting against them. The validator lists each with its
    check ID and quoted deferral note, asks whether to tackle any
    this round, and echoes accepted ones under a "Deferrals
    promoted to this round" heading in chat so the developer has
    one consolidated list of what to do next.
  - Skips the entire Step 9 with a one-liner if both buckets are
    empty.
- **`/validate-web-component` Step 2.5 — capture deferrals for
  Step 9b.** The Discipline subsection now tells the validator to
  keep a running list (check ID + one-line title from the heading +
  file:line of the deferral note) of every deferral entry it
  encounters in `VALIDATION-NOTES.md`. Without this, Step 9b had
  no source data to enumerate.

---

## 2026-06-15

### Added

- **New `readme-structure` triad — slim README + `docs/` folder
  layout.** Today's component READMEs (multiselect ~2,000 lines,
  daterangepicker / grid / treeview similar) are everything-in-one-
  file walls that bury the value proposition on npm landing pages
  and rot internally. The new triad prescribes a slim
  ~150–300 line `README.md` (hard cap 400, soft target 200) that
  covers only title + tagline / "what is it" / "what's new" /
  demos & docs links / install / one quick-start snippet / browser
  support / license, with deep docs split into a `docs/` subfolder:
  `usage.md` (full API reference, ATTRIBUTE_TABLE, events, slots,
  methods), `theming.md` (single home of the four theming
  contracts; see "Changed" below), `examples.md` (worked examples
  beyond the quick start), `accessibility.md` (keyboard / ARIA /
  focus). Files added:
  - **`readme-structure.md`** — rationale (npm-landing-page burial
    + catch-all rot), canonical layout tree, README section
    inventory with size budgets, per-`docs/`-file content
    requirements, worked example showing what
    `web-multiselect`'s slim README would look like (~50 lines vs
    today's ~2,000), cross-references to the four moved checks.
  - **`readme-structure.decisions.md`** — six decisions
    (D-RS-1 demo location with default A
    `demos.keenmate.com/<component>`, D-RS-2 accessibility-doc
    applicability with B exit for purely display components,
    D-RS-3 single file vs `docs/examples/` folder, D-RS-4
    framework-integration guide location, D-RS-5 "What's new"
    section shape, D-RS-6 migration strategy for existing
    oversized READMEs with default A one-PR-per-file).
  - **`readme-structure.checks.md`** — thirteen checks
    (C-RS-1 README exists, C-RS-2 ≤ 400 lines, C-RS-3 `docs/` has
    four files, C-RS-4 README links every `docs/` file via
    relative path, C-RS-5 canonical section headings, C-RS-6
    intro is tight, C-RS-7 "What's new" links CHANGELOG, C-RS-8
    deployed demo link works, C-RS-9 quick-start runs in clean
    install, C-RS-10/11/12/13 each `docs/` file covers its
    contract). Tier split: 5 auto, 7 semi, 1 manual.
- **`readme-structure.checks.sh`** — runnable bash for the five
  `[auto]` checks (C-RS-1, 2, 3, 4, 5). C-RS-3 treats a missing
  `docs/accessibility.md` as a SKIP rather than an outright fail
  to leave room for the D-RS-2 = B exemption; the slash command
  resolves the SKIP per the decision tag. C-RS-4's link match
  accepts either `(./docs/<file>.md)` or `(docs/<file>.md)` —
  both render correctly on GitHub / npm. C-RS-5 treats
  "Quick start" / "Quick demo" / "Usage" as equivalent intent for
  the install-then-snippet section.
- **`/validate-readme-structure`** — new slash command. Loads the
  three readme-structure files plus the README-related checks
  referenced from the other triads, invokes
  `readme-structure.checks.sh`, then runs the eight `[semi]` /
  `[manual]` checks (C-RS-6 intro tightness, C-RS-7
  "What's new" linkage, C-RS-8 demo URL, C-RS-9 quick-start runs,
  C-RS-10 `docs/usage.md` coverage cross-referencing the source
  ATTRIBUTE_TABLE, C-RS-11 `docs/theming.md` four-contract
  coverage cross-referencing C-TC-11/C-BV-8/C-CS-8/C-CSS-10,
  C-RS-12 worked examples, C-RS-13 accessibility coverage with
  D-RS-2 = B handling). Read-only.
- **New check `C-CS-10` — tooltips render correct contrast in dark
  mode.** Driven by a real `@keenmate/web-grid` symptom: dark-themed
  grid, tooltip rendered with a dark background and dark text in
  dark mode — unreadable. The variables and dark-mode strategy
  looked correct on inspection (`--wg-tooltip-bg` chains through
  `light-dark()`; dark-mode.css flips `color-scheme` on
  `:host([data-theme="dark"])`), so the bug is subtle: a hardcoded
  literal hiding in a shared CSS file, a chain anchored on a
  non-`light-dark()` fallback, or a tooltip element that doesn't
  inherit the host's `color-scheme` flip (typically because it's
  portaled out for stacking-context reasons). The check covers
  three tooltip kinds and forces each one the component actually
  uses to be walked back to a verified theme-propagation path:
  - **A — in-shadow-DOM / in-container custom tooltip** — CSS chains
    through `var(--<prefix>-tooltip-*, var(--base-tooltip-*,
    light-dark(...)))`. No hardcoded color literals in tooltip
    rules.
  - **B — tooltip portaled outside the container** (to
    `document.body`, `<dialog>`, the Popover API, etc.) — needs one
    of three propagation mechanisms: (1) mirror `data-theme` from
    the container onto the portal root at open time with matching
    `[data-theme="dark"]` / `[data-theme="light"]` selectors in the
    tooltip CSS; (2) read `--base-tooltip-*` directly with the
    limitation documented in `docs/theming.md`; (3) put a
    conditional `color-scheme: dark` block on the portal root
    parallel to the host's signal selectors.
  - **C — browser-native `title=""` tooltips** — passes if C-CS-1 is
    green; the browser handles native tooltips honoring the page's
    `color-scheme`.
  - Tier: `[semi]`. Tier totals updated to 41 auto / 29 semi / 15
    manual = 85 total. The check's "Worked example" section walks
    the three bug shapes (hardcoded literal in tooltip rule, chain
    anchored on non-`light-dark()` fallback, theme signal not
    reaching the tooltip DOM) so the developer who runs the check
    on a failing component knows which dimension to investigate.
- **`color-scheme.md` anti-pattern #6 — portaled tooltip with stale
  colors.** Added to "Anti-patterns we've actually seen" alongside
  the bare `:host { color-scheme }` and `@media`-hardcoded entries.
  Cross-referenced from C-CS-7 (visual smoke) so the human-eye
  step explicitly looks at portaled tooltips.
- **`color-scheme.checks.sh` partial auto-check for C-CS-10.** The
  script now scans any file matching `*tooltip*.css` in the CSS
  folder (excluding `variables.css` and `dark-mode.css`, which are
  the only files allowed color literals per C-CSS-8) for
  hardcoded `background:` / `color:` / `border-color:` hex
  literals. Catches the smoking-gun pattern without false positives.
  No dedicated tooltip CSS file → SKIP (the full [semi] check still
  runs via `/validate-color-scheme`).
- **`/validate-color-scheme` extended.** Step 4 now lists C-CS-10
  with concrete instructions for classifying each tooltip code
  path (Kind A / B / C) and verifying its propagation mechanism.
  The Step 5 report template includes a "Tooltip kinds detected"
  line so the validator surfaces *what* the component uses
  alongside *whether* it's wired correctly.

### Changed

- **Four existing checks now point at `docs/theming.md` instead of
  `README.md`.** With the readme-structure triad establishing
  `docs/theming.md` as the single home of the theming contract,
  the checks that previously required README coverage move to
  the deeper doc:
  - **C-TC-11** (theme-container) — "README documents the
    container contract" → "`docs/theming.md` documents the
    container contract". Verification path updated; the five
    contract points stay the same. Documented exception added for
    components that pre-date the triad and still carry the
    content in `README.md` — flag for the readme-structure
    migration per D-RS-6 rather than failing.
  - **C-BV-8** (base-variables) — "Component README documents the
    contract" → "`docs/theming.md` documents the variable
    contract". Same content (manifest reference, `--<prefix>-rem`
    override, at least one `--base-*` and one `--<prefix>-*`
    example), new file. Same migration exception.
  - **C-CS-8** (color-scheme) — "README documents the theming
    contract" → "`docs/theming.md` documents the color-scheme
    contract". Five-point coverage stays the same; new file.
    Same migration exception.
  - **C-CSS-10** (css-structure) — "Layer contract documented in
    README" → "Layer contract documented in
    `docs/theming.md`". The unlayered-reset footgun warning is
    now scoped — required only when the component actually ships
    `@layer component` rules and is therefore at risk (per the
    "Fixes to apply" tightening from 2026-06-14, where
    unrelated-to-this-component warnings stop being valid fixes).
  - **Slash command updates** — `/validate-theme-container`
    Step 4's C-TC-11 prose now reads `docs/theming.md`'s
    container section and recognizes the legacy-README exception.
    The other affected slash commands inherit the new check
    wording verbatim from `.checks.md` and need no source change.
  - **Summary checklists** in all four `.checks.md` files updated
    to match.
- **`/validate-web-component` extended from six triads to seven,
  then from /84 to /85 with C-CS-10.** Frontmatter description now
  lists `readme-structure` as the seventh triad. Step 1 loads
  `readme-structure.md` and `readme-structure.checks.md`. Step 3
  invokes `readme-structure.checks.sh` (and lists its auto checks
  C-RS-1..5 in the per-triad table); the color-scheme row of the
  per-triad table now notes "plus C-CS-10 (partial)". Step 4
  references the new `/validate-readme-structure` for the eight
  `[semi]` / `[manual]` checks and updates the color-scheme count
  from seven to eight `[semi]` / `[manual]` (now including
  C-CS-10). Headline result table grew from 6 rows / `/71` total to
  7 rows / `/85` total (color-scheme row bumped from `/9` to `/10`).
  PR-ready checkbox template grew by 13 (readme-structure) + 1
  (C-CS-10) boxes. Punch-list file template's "See also" list now
  includes `readme-structure.checks.sh` and
  `/validate-readme-structure`.
- **`web-components/README.md` index updated.** New row in the
  "When to consult which file" table (writing or restructuring a
  component's external documentation → readme-structure triad).
  Canonical reading order for brand-new components extended with
  `readme-structure.md` between `color-scheme.md` and
  `example-web-player.md`. Mandatory checklist's Documentation
  section rewritten — the old "README documents which variables
  it consumes…" bullet is replaced by six bullets covering the
  slim-README cap, the `docs/` folder existence, `docs/theming.md`
  as the single home of the four theming contracts,
  `docs/usage.md` coverage, `docs/accessibility.md` coverage
  (with D-RS-2 = B exemption), and the CHANGELOG entry. The
  Dark-mode section gains a tooltip-rendering bullet citing
  C-CS-10. Check tier totals updated to 41 auto / 29 semi / 15
  manual = 85.
- **`CLAUDE.md` directory map** includes the readme-structure
  triad. Canonical reading order extended to match the README's.

### Why this round, in one paragraph

The validator's "Fixes to apply" tightening on 2026-06-14 made
clear that "optional polish" framing in the punch-list was
producing chaos for downstream developers — the team was being
told to add general guidance to their READMEs that wasn't tied to
anything specific in their component. The reason that kept
happening was structural: the rulebook had four separate checks
("README documents X contract") that all forced everything-in-
README, so the validators kept reaching for the README as the
catch-all destination for any contract not yet covered. Splitting
the deep docs into a `docs/` folder and making `docs/theming.md`
the single home for the four contracts removes both problems at
once — the README becomes a landing page consumers can actually
read, and the validators have a precise, scoped destination for
each contract instead of one bloated file to keep nudging at.

Same round picked up C-CS-10 because `@keenmate/web-grid` shipped a
real symptom — tooltip rendering with dark background + dark text
in dark mode — that fell through every existing check.
`variables.css` declares the variables correctly, `dark-mode.css`
flips `color-scheme` correctly, and the tooltip CSS reads
`var(--wg-tooltip-*)` correctly — yet the user still gets unreadable
text. C-CS-2 only looks at fallbacks inside `variables.css`, not
feature CSS rules; C-CS-7 (visual smoke) is the catch-all and
would have caught it eventually, but only if someone explicitly
opened a tooltip while looking at dark mode. C-CS-10 makes the
verification structural: enumerate tooltip code paths (custom
in-shadow / portal-escaped / browser-native), classify each,
verify each has a theme-propagation mechanism, walk each variable
chain back to a `light-dark()` literal. The same exposure pattern
applies to popovers and dropdowns rendered to `document.body` —
any surface that escapes the container's variable scope.

---

## 2026-06-14

### Added

- **Check tiers — every check in every `.checks.md` now carries a tier
  tag (`[auto]`, `[semi]`, `[manual]`)** identifying whether it can be
  mechanically verified or needs context / judgment. Tags applied across
  all six triads:
  - `css-structure.checks.md` — 9 auto, 2 semi, 1 manual.
  - `theme-container.checks.md` — 5 auto, 6 semi, 4 manual.
  - `base-variables.checks.md` — 6 auto, 3 semi, 3 manual.
  - `color-scheme.checks.md` — 2 auto, 4 semi, 3 manual.
  - `component-structure.checks.md` — 7 auto, 2 semi, 2 manual.
  - `naming-conventions.checks.md` — 7 auto, 4 semi, 1 manual.
  - **Total: 36 auto, 21 semi, 14 manual across 71 checks (51% / 30% / 19%).**
  Each check's tier appears immediately under its heading as
  `**Tier:** [auto]` / `[semi]` / `[manual]` with a short note explaining
  what part is mechanical and what part needs context. Each
  `## Summary checklist` block also shows the tier inline. The intro of
  each `.checks.md` references the README for the meaning of the tags.
  `web-components/README.md` gained a "Check tiers" section explaining
  the three levels and tabulating the totals.
- **`component-structure.checks.sh`** — runnable bash script that
  executes the seven `[auto]` checks from
  `component-structure.checks.md` against a target component directory.
  Takes the package path as its single argument; auto-detects
  web-component vs Svelte from filesystem signals; skips per-host checks
  cleanly on the wrong host; runs C-CST-1, C-CST-2, C-CST-3, C-CST-4,
  C-CST-5, C-CST-8, C-CST-11; prints PASS/FAIL with check ID; returns
  exit code 0 if all pass, 1 if any fail, 2 on bad usage. Skipped semi /
  manual checks are listed at the bottom of the output with their
  reasons. Smoke-tested against `@keenmate/web-multiselect` — 6/6 pass.
  One regex refinement was needed during the smoke test: `extends`
  target broadened from literal `HTMLElement` to `[A-Z]\w+` so the
  SSR-safe `BaseElement = HTMLElement || class {}` intermediary pattern
  is accepted.
- **`naming-conventions.checks.sh`** — runnable bash script that
  executes the seven `[auto]` checks from
  `naming-conventions.checks.md`. Takes the package path plus an
  optional CSS-prefix argument (auto-detected from
  `component-variables.manifest.json` if omitted); auto-detects host;
  runs C-NC-1, C-NC-2, C-NC-3, C-NC-6, C-NC-8, C-NC-9, C-NC-11; same
  exit-code shape and skipped-check footer. Smoke-tested against
  `@keenmate/web-multiselect` (CSS prefix `ms`) — 7/7 pass after
  three refinements during testing:
  - **C-NC-8 BEM regex** broadened to accept all four valid BEM shapes
    (`.<prefix>`, `.<prefix>--mod`, `.<prefix>__elem`,
    `.<prefix>__elem--mod`) plus `.<prefix>-container`, not just
    `.<prefix>__elem--mod`. The original regex incorrectly flagged
    `.ms` (bare block), `.ms--open` (block modifier), and the like.
  - **C-NC-8 input pre-processing** now strips CSS block comments,
    `url(...)` strings, single-quoted and double-quoted string
    literals, and `:host-context(...)` / `:host([...])` selector
    arguments before scanning for class names — those contain
    filenames, theme classes like `.dark` / `.light`, and other
    non-component-emitted strings that were producing false positives.
  - **C-NC-3 data-model exemption** added: an awk-based context tracker
    skips boolean fields inside interfaces whose name ends in `Option`,
    `Node`, `Item`, `Row`, `Entry`, `Record`, `Model`, or `Result` —
    those are data-shape interfaces where HTML / DOM convention
    (`disabled`, `selected`, `checked`, etc., without prefix) applies,
    not Config / Props. This change paired with a rule clarification
    in both `naming-conventions.md` (rulebook + public manifesto) and
    `naming-conventions.checks.md` calling out the data-model
    exception explicitly, with `@keenmate/web-multiselect`'s
    `MultiSelectOption.disabled` cited as the canonical example (the
    field was originally `isDisabled` and renamed to `disabled` to
    align with HTML's `<option disabled>`).
- **`css-structure.checks.sh`** — runnable bash for the nine `[auto]`
  checks of `css-structure.checks.md` (C-CSS-1, 2, 3, 4, 5, 6, 7, 8,
  11). Takes the package path plus optional CSS prefix; auto-detects
  Svelte vs web-component to pick `src/css/` vs `src/lib/styles/`.
  Smoke-tested against `@keenmate/web-multiselect` — 9/9 pass. One
  refinement during testing: **C-CSS-11** ("main.css has no rules")
  initially false-positived on multi-line block-comment continuation
  lines; pre-stripping block comments before the non-`@`-line scan
  resolved it. Skipped checks: C-CSS-9 (mixed-bag — requires reading
  files), C-CSS-10 (README accuracy), C-CSS-12 (bundle-size sanity).
- **`theme-container.checks.sh`** — runnable bash for the five `[auto]`
  checks of `theme-container.checks.md` (C-TC-1, 3, 5, 7, 15). Detects
  web-component vs Svelte and switches container selector accordingly
  (`:host` vs `.<prefix>-container`). Smoke-tested against
  `@keenmate/web-multiselect` — **2 pass, 2 fail, 1 skip**. **Both
  fails are real bugs**, not false positives:
  - C-TC-7 fails because `:host` in `variables.css` declares no
    `display:` — the browser defaults custom elements to `inline`,
    which is wrong for a block-level component. The wrapper-host
    pattern (D-TC-3 option C) compensates via `.ms__wrapper { display:
    flex }`, but the host itself should still declare its display
    intent.
  - C-TC-15 fails because `base.css:13` has
    `multi-select:not(:defined)` while `src/web-component.ts:1154`
    registers `customElements.define('web-multiselect', ...)`. This
    is the canonical FOUC-tag-trap bug — the exact case that motivated
    creating C-TC-15 in the first place.
  - C-TC-3 skipped because multiselect uses the wrapper-host pattern
    (`--ms-bg` is not declared on `:host`; `--ms-input-bg` is on
    `.ms__input` instead — legitimate per D-TC-3 = C).
- **`base-variables.checks.sh`** — runnable bash for the six `[auto]`
  checks of `base-variables.checks.md` (C-BV-1, 2, 3, 5, 6, 9). Uses
  `jq` if available for manifest parsing, falls back to regex otherwise.
  Smoke-tested against `@keenmate/web-multiselect` — 6/6 pass after
  two refinements during testing:
  - **`grep -qx "$v"`** broke on variable names starting with `--` —
    grep interpreted `--ms-foo` as a command-line option. Switched to
    `grep -qFx -- "$v"` (fixed-string + explicit option separator).
  - **C-BV-3** ("every consumed `--<prefix>-*` var is defined")
    tightened to only require definition for *bare* `var(--ms-X)`
    reads. Variables consumed with fallback chains
    (`var(--ms-X, var(--ms-Y, ...))`) are deliberate consumer-override
    hooks and don't need a default declaration — the chain resolves
    them. The original strict reading produced 12 false positives on
    multiselect's hover / focused-hover override variables that are
    intentionally chained to their non-hover counterparts.
- **`color-scheme.checks.sh`** — runnable bash for the two `[auto]`
  checks of `color-scheme.checks.md` (C-CS-2, 5). Smoke-tested against
  `@keenmate/web-multiselect` — 2/2 pass after a refinement:
  **C-CS-2** ("color fallbacks use `light-dark()`") now exempts the
  documented exception names — `--base-accent-color*`,
  `--base-text-color-on-accent` — that the rule explicitly carves out
  ("intentional exceptions OK if documented, e.g. `text-on-accent` is
  `#ffffff` in both modes"). Without this, multiselect's brand-color
  variables produced four false-positive fails.

### Slash commands updated to invoke the scripts

- **`/validate-component-structure`** (new) — companion to the new
  component-structure triad. Loads the four `.md` / `.checks.md` /
  `.decisions.md` files, detects host technology (web-component vs
  Svelte), invokes `component-structure.checks.sh` for the seven
  `[auto]` checks, then runs the `.checks.md` prose for the four
  `[semi]` / `[manual]` checks (C-CST-6 Element-business-state,
  C-CST-7 no-Manager, C-CST-9 no-premature-interfaces, C-CST-10
  folder-layout). Produces a report with the script output verbatim
  followed by per-check verdicts for the judgment half. Registered
  as the `validate-component-structure` skill.
- **`/validate-naming-conventions`** (new) — companion to the new
  naming-conventions triad. Loads the four reference docs, invokes
  `naming-conventions.checks.sh` (autodetects CSS prefix from manifest
  or accepts it as arg 2) for the seven `[auto]` checks, then runs the
  prose for the five `[semi]` / `[manual]` checks (C-NC-4 notification
  shape, C-NC-5 interceptors, C-NC-7 ATTRIBUTE_TABLE, C-NC-10
  validate/check semantics, C-NC-12 magic strings). Notes the
  script's data-model exemption for C-NC-3 and the BEM input-
  preprocessing for C-NC-8 so the agent doesn't second-guess the
  script's view. Registered as the `validate-naming-conventions`
  skill.
- **`/validate-css-structure`** (updated) — Step 3 now invokes
  `css-structure.checks.sh` instead of running each `[auto]` check
  by hand. Step 4 runs the three `[semi]` / `[manual]` checks
  (C-CSS-9 mixed-bag, C-CSS-10 README layer contract, C-CSS-12
  bundle size). Step 5 report format includes the script output
  verbatim then per-check verdicts only for the judgment half.
- **`/validate-theme-container`** (updated) — bumped from C-TC-1..14
  to C-TC-1..15. Step 4 invokes `theme-container.checks.sh` for the
  five `[auto]` checks; Step 5 runs the ten `[semi]` / `[manual]`
  checks. The C-TC-2 default-background prose now explicitly
  recognizes the three D-TC-3 patterns (self-paint / transparent /
  wrapper-host) and tells the agent what to look for in each case.
  C-TC-4 prose calls out the verdict table for bare vs conditional
  `color-scheme` so the agent doesn't fail Strategy-B implementations.
  C-TC-8 prose recognizes the fixed-floating-UI exception with the
  required dual-condition check (every floating panel fixed AND every
  absolute descendant anchored to an internal positioned wrapper).
- **`/validate-base-variables`** (updated) — Step 3 invokes
  `base-variables.checks.sh` for the six `[auto]` checks. Step 4 runs
  the six `[semi]` / `[manual]` checks (C-BV-4 prefix uniqueness,
  C-BV-7 canonical chains, C-BV-8/10/11 README/standalone/end-to-end,
  C-BV-12 CHANGELOG). Notes the script's C-BV-3 fallback-chain
  exemption (bare-read-only checking) so the agent doesn't re-flag
  the override-hook variables the script intentionally allowed.
- **`/validate-color-scheme`** (updated) — Step 3 invokes
  `color-scheme.checks.sh` for the two `[auto]` checks (C-CS-2, 5).
  Step 4 runs the seven `[semi]` / `[manual]` checks. The C-CS-1
  prose now uses the bare-vs-conditional verdict table from the
  rule. Notes the script's C-CS-2 accent/on-accent exemption.
- **`/validate-web-component`** (updated, umbrella) — significant
  expansion:
  - Frontmatter description updated to list all six triads.
  - Step 1 loads all six pairs of `.md` + `.checks.md` plus all six
    `.decisions.md` files.
  - Step 3 rewritten — invokes all six `.checks.sh` scripts in
    sequence (one block of six commands), captures each script's
    output verbatim. Includes a per-triad table of which check IDs
    the script handles.
  - Step 4 (new — was previously part of the old Step 3) runs all
    35 `[semi]` / `[manual]` checks across the six triads, cross-
    referencing each individual validator command for the discipline.
  - Step counts shifted: cross-cutting invariants is now Step 5,
    taxonomy alignment Step 6, the consolidated report Step 7, and
    the punch-list file write Step 8.
  - **Headline table grew from 4 rows to 6** — added Component
    structure (/11) and Naming conventions (/12). Total bumped from
    `/48` to `/71`.
  - **PR-ready checklist template grew accordingly** — added
    Component structure (11 boxes) and Naming conventions (12 boxes)
    sections, each box tagged with its `[auto]` / `[semi]` /
    `[manual]` tier. CSS structure / theme container / base
    variables / color scheme sections retagged inline too.
  - **Auto-check script outputs section** added to the report
    template — six verbatim blocks, one per script, before the
    per-check semi/manual judgments.
  - Punch-list file template (`validation_<timestamp>.md` in the
    target folder) updated to match — headline table grew to 6
    rows / `/71` total; "See also" section now lists all six
    auto-check scripts with copy-pasteable commands plus all six
    individual `/validate-*` commands.
  - "Batch independent file reads" hint now says 71 checks instead
    of 33.

### Overall script status

All six `.checks.sh` scripts now exist:
`component-structure.checks.sh`, `naming-conventions.checks.sh`,
`css-structure.checks.sh`, `theme-container.checks.sh`,
`base-variables.checks.sh`, `color-scheme.checks.sh`. Combined, they
mechanize 32 of the 36 `[auto]` checks across the six triads
(theme-container C-TC-7 fails legitimately on multiselect — see above
— but the check itself runs correctly; some checks skip cleanly per
documented decisions like D-TC-3 = C, D-TC-9 = B, etc.). Smoke-test
roll-up against `@keenmate/web-multiselect`:

| Triad | Auto checks | Pass | Fail | Skip |
|-------|------------:|-----:|-----:|-----:|
| css-structure | 9 | 9 | 0 | 0 |
| theme-container | 5 | 2 | 2* | 1 |
| base-variables | 6 | 6 | 0 | 0 |
| color-scheme | 2 | 2 | 0 | 0 |
| component-structure | 7 | 6 | 0 | 0 (C-CST-1 + C-CST-2 ran as one entry; the seventh check, C-CST-7 No-Manager, is `[semi]` not `[auto]`) |
| naming-conventions | 7 | 7 | 0 | 0 |
| **Total** | **36** | **32** | **2** | **1** |

*Both theme-container fails are documented real bugs in multiselect
(missing `:host { display: block }` and the `multi-select` →
`web-multiselect` FOUC tag drift), not script defects.

### Edge cases the scripts surfaced

Two rule-as-written edge cases came out of the smoke tests and have
been added to the rulebook:

1. **C-NC-3 data-model exception** (above) — bare HTML-attribute names
   on data-model interfaces are not violations.
2. **C-BV-3 fallback-chain exception** (above) — consumer-override
   variables with fallback chains don't need explicit definitions.

Both edge cases now live in the `.checks.sh` regex logic and in the
human-readable `.checks.md` text. The rule's "Pass:" criteria were
loosened to match — the underlying intent (the component must work
standalone) is unchanged.

- **Two new triads — `component-structure` and `naming-conventions` —
  formalize the JavaScript / TypeScript half of the rulebook.** Until
  now the rulebook covered only CSS concerns (structure, theme
  container, base variables, color scheme). The JS / web-component
  conventions lived only in the public manifesto site
  (`BlissFramework/web/docs/coding-guidelines-javascript/`). These two
  triads pull the rulebook half into the component-library rulebook
  proper, where validation commands and `.checks.md` files can
  reference them. Files added:
  - **`component-structure.md`** — internal architecture:
    Element / Logic class / Service classes / Side layer split, with
    strict import-direction rules; folder layout (`src/web-component.ts`
    / `src/<feature>.ts` / `src/types.ts` / `src/logger.ts` /
    `src/<service>.ts` / `src/css/` for web-components, with the Svelte
    `src/lib/components/` / `src/lib/core/` / `src/lib/<data>/` shape
    documented alongside); class-naming summary (`Element` suffix for
    the wrapper, `Web<Feature>` for web-component-hosted Logic,
    `<Feature>Controller` for Svelte-hosted Logic, bare PascalCase for
    Services); closed-set TS suffixes (`Config` / `Options` /
    `EventDetail` / `Context` / `Spec` / none); "when (not) to
    introduce a Manager" and "when (not) to introduce interfaces"
    sections applying the Bliss "use only what you need" rule.
  - **`component-structure.decisions.md`** — nine decisions
    (D-CST-1 host technology, D-CST-2 Logic class name,
    D-CST-3 Element class / file, D-CST-4 Service classes,
    D-CST-5 Side-layer files, D-CST-6 Manager layer, D-CST-7 TS
    interface suffix policy, D-CST-8 premature interfaces, D-CST-9
    Logic-class framework-runtime imports).
  - **`component-structure.checks.md`** — eleven checks
    (C-CST-1 Element class with `Element` suffix, C-CST-2 tag agrees
    with `customElements.define`, C-CST-3 Logic class is framework-
    agnostic, C-CST-4 Service classes don't import each other,
    C-CST-5 Side layer has no upward imports, C-CST-6 Element layer
    holds no business state, C-CST-7 no premature Manager, C-CST-8 TS
    interface suffixes match closed set, C-CST-9 no premature
    interfaces, C-CST-10 folder layout matches convention, C-CST-11
    Logic-class framework imports respect D-CST-9).
  - **`naming-conventions.md`** — public API names: casing summary
    table, custom-element tag rules (hyphen mandatory, family prefix),
    `CustomEvent` naming (bare, short, HTML-standard-aligned), HTML
    attribute ↔ config key mapping with `ATTRIBUTE_TABLE` single-
    source-of-truth pattern, boolean attribute semantics
    (`bool-default-true` vs `bool-default-false`), the full consumer
    callback hierarchy (`on*` for Svelte / `*Callback` for plain-JS
    config / `before*Callback` for interceptors / `get*Callback` paired
    with `*Member` for data extractors / plain `*Callback` for behavior
    providers), the parallel-APIs pattern for web-components
    (`CustomEvent` + `*Callback` field for the same notification),
    boolean predicate naming (`is*` / `has*` / `can*` / `should*` for
    properties; `check*` for verb-style methods), the Bliss verb
    registry plus DOM-specific verbs (`render` / `handle` / `dispatch`
    / `attach` / `mount` / `observe` / `compute` / `position` /
    `commit` / `reconcile`), CSS BEM-with-prefix cross-link,
    TypeScript notes (no `I`-prefixed interfaces, lowercase tags for
    discriminated unions, sparing branded types), vocabulary-collision
    table for UI work (`options` / `value` / `target` / `data` /
    `name` / `key` / `index`).
  - **`naming-conventions.decisions.md`** — ten decisions
    (D-NC-1 custom-element tag, D-NC-2 CSS prefix cross-referencing
    D-BV-1, D-NC-3 Logic class name cross-referencing D-CST-2,
    D-NC-4 boolean attribute defaults per attribute, D-NC-5 public
    notification surface, D-NC-6 `CustomEvent` name list, D-NC-7
    `*Member` + `get*Callback` pair adoption, D-NC-8 interceptor
    adoption, D-NC-9 `ATTRIBUTE_TABLE` as single source of truth,
    D-NC-10 TS interface suffixes cross-referencing D-CST-7).
  - **`naming-conventions.checks.md`** — twelve checks
    (C-NC-1 custom-element tag hyphenated + prefixed, C-NC-2
    `CustomEvent` names bare and short, C-NC-3 boolean config fields
    use prefix, C-NC-4 notification callbacks match host shape, C-NC-5
    interceptors use `before*Callback`, C-NC-6 data extractors use
    `get*Callback` + `*Member` pair, C-NC-7 `ATTRIBUTE_TABLE` single
    source of truth, C-NC-8 CSS classes match BEM with prefix, C-NC-9
    internal `handle*` methods and `*Handler` stored refs, C-NC-10
    `validate*` vs `check*` used per their semantics, C-NC-11 TS
    interface suffixes from closed set, C-NC-12 no magic strings
    inline).
  - **`README.md`** — index updated: two new rows in the "When to
    consult which file" table, canonical reading order now begins
    `component-structure.md` → `naming-conventions.md` → … →
    `example-web-player.md`. The mandatory checklist grew two new
    sections (Component structure with seven boxes, Naming conventions
    with ten boxes).
  - **`CLAUDE.md`** — directory map and canonical reading order
    updated to reflect the new triads.
- **FOUC-prevention pattern formalized for web-components.** Until now
  the guidelines were silent on what to do about the
  flash-of-unstyled-content window between page parse and
  `customElements.define(...)`. A pre-upgrade `<web-foo>` is
  `:not(:defined)`, defaults to `display: inline`, has no height, and
  renders any child text unstyled — so on a slow connection the
  consumer sees a flash, and on a fast connection the page still
  reflows when the component upgrades and reserves its real
  footprint. Three docs added:
  - **`theme-container.md`** — new "FOUC prevention — handling the
    pre-upgrade window" section with the canonical light-DOM rule
    pattern (`<tag>:not(:defined) { display: block; min-height: …;
    color: transparent !important; background: transparent }`),
    rationale for each declaration, an explanation of why the rule
    must be a light-DOM rule (because `:host` doesn't exist
    pre-upgrade) and how it reaches the host via the side-effect
    `import './css/main.css'` in the entry point, and a "tag-name
    trap" warning citing the two known failure modes (post-rename
    stale selector and CSS-prefix-mistaken-for-tag).
  - **`theme-container.checks.md`** → **C-TC-15** — greps the tag from
    `<tag>:not(:defined)` rules in `base.css`, greps every
    `customElements.define('<tag>', …)` call in the TS source, and
    confirms they match. N/A for Svelte components and for
    web-components that opted out via D-TC-9 = B. Worked example
    cites the `@keenmate/web-multiselect` 1.12.0-rc01 bug
    (`multi-select:not(:defined)` in `base.css:13` paired with
    `customElements.define('web-multiselect', …)` in
    `src/web-component.ts:1154` — silent rename trap, FOUC
    prevention dead since the rename).
  - **`theme-container.decisions.md`** → **D-TC-9** — "ship FOUC
    prevention?" with default A (yes) for components with visible
    chrome reserving > ~16px of layout, B (no) for inline atoms.
    N/A for Svelte. Summary-table line added.

  Surfaced by the `/validate-web-component` runs of the past two
  days: the multiselect's broken FOUC selector was the only real
  component issue both runs flagged, but the guideline carried no
  language about FOUC at all — neither the rule itself, the
  rename trap, nor a check to catch it. Now it does.

### Changed

- **`/validate-web-component` now writes a punch-list file to the
  target component folder.** Previously the umbrella validator
  emitted only a chat-transcript report. The report stays — but the
  command now also writes `validation_<YYYY-MM-DD_HHMM>.md` to the
  root of the target component package (next to `package.json`),
  containing only the action-oriented bits: result table, numbered
  fix blocks with concrete `diff` patches per failure, pending
  manual-check instructions, and the PR-ready checkbox status.
  Reason: the full per-check report is verbose and lives only in the
  chat session that generated it, which a future developer (or
  Claude session) reopening the component repo can't see. The
  punch-list file lands in the component repo with everything needed
  to actually do the work, indexed by timestamp so a series of runs
  forms an audit trail (`.gitignore` the pattern if you don't want
  it committed). New Step 7 in the command instructions; `Write`
  added to `allowed-tools`. Frontmatter description updated to
  reflect the dual output.

- **Validator total count bumped 47 → 48** (Step 3, Step 6 headline
  table) reflecting yesterday's C-TC-15 addition. PR-ready checklist
  template in Step 6 gains the C-TC-15 line.

## 2026-06-11

### Changed

- **`color-scheme` rule split into bare vs conditional.** The
  long-standing "no `color-scheme` on the container" rule turned out
  to be too coarse. A *bare* `:host { color-scheme: ... }` (or bare
  `.<prefix>-container { color-scheme: ... }`) is the real footgun —
  it shadows the page's inherited `color-scheme` for *every*
  instance, which is the multiselect v1.10 bug. But a *conditional*
  declaration on `:host([data-theme="dark"])`,
  `:host-context([data-bs-theme="dark"])`,
  `.<prefix>-container[data-theme="dark"]`, etc. fires only when the
  consumer has explicitly signalled their theme intent — it amplifies
  the signal rather than fighting page inheritance. The new framing
  formalizes this distinction across `color-scheme.md` (new "Two
  strategies for framework-class & per-instance signals" section
  contrasting Strategy A "override variables" with Strategy B "flip
  color-scheme"), `theme-container.md`, `CLAUDE.md` invariant #4,
  the README mandatory checklist, and checks C-CS-1 / C-TC-4
  (rewritten with a verdict table per selector shape; both worked
  examples cite `@keenmate/web-multiselect` v1.12.0-rc01 as the
  Strategy B reference). New decision **D-CS-7** lets each component
  pick A or B explicitly; default B for components whose color
  fallbacks all chain through `light-dark()`.

- **D-TC-3 grew option C — "wrapper-host with painted chrome."** The
  guideline previously modeled two background patterns: (A)
  container paints `background: var(--<prefix>-bg)`, or (B)
  intentionally transparent inline atoms. Form-control components
  (multiselect, future combobox, date picker, …) are a third case —
  the host is a layout wrapper; the visible surface is *one*
  internal element (typically `.<prefix>__input`) which paints. The
  component is *not* invisible standalone — the chrome paints
  itself — but the host doesn't double-paint. C-TC-2 was rewritten
  to recognize all three patterns; passing C requires the README to
  identify the component as form-control and name the painted
  element. Worked examples in C-TC-2 cover all three: A
  (svelte-treeview), B (svelte-switch), C (web-multiselect).

- **C-TC-8 (`position: relative` on container) gained the
  fixed-floating-UI exception.** Components whose every floating
  panel uses `position: fixed` (via Floating UI) and whose in-flow
  `position: absolute` descendants anchor to an internal
  `position: relative` wrapper (`.<prefix>__input-wrapper`,
  `.<prefix>__viewport`, …) never need `:host` to be the
  offsetParent — declaring `position: relative` on the container
  becomes harmless but unnecessary. D-TC-6 documents the exception;
  C-TC-8 splits into two pass paths (default and fixed-floating).
  Reference: `@keenmate/web-multiselect`.

- **Canonical `--base-*` taxonomy expanded with 14 entries** (a
  coordination move per `base-variables.md` → "Adding a new
  `--base-*` variable"). Additions are driven by patterns already
  shipping in `@keenmate/web-multiselect` 1.12.0-rc01 and likely to
  recur across other form-control / list-rendering components:
  - **Accent/text/surface table:**
    `--base-accent-color-light-hover` (hover state paired with
    `--base-accent-color-light`), `--base-text-color-4` (placeholder
    / quaternary text for components with a 4-level hierarchy).
  - **Inputs table:** `--base-input-bg-disabled` (disabled input
    surface).
  - **Semantic table:** `--base-dropdown-border` (full-shorthand
    dropdown border).
  - **Typography table:** `--base-font-size-lg`,
    `--base-font-size-xl`, `--base-font-weight-medium`,
    `--base-line-height-tight`, `--base-line-height-relaxed`.
  - **Layout table:** `--base-input-size-{xs,sm,md,lg,xl}-height` —
    the five-tier input-height scale that KeenMate's Theme Designer
    publishes and that every consuming form-control component reads
    through. Documented as the canonical cross-component sizing
    axis.
  - **Renamed:** `--base-tooltip-color` → `--base-tooltip-text-color`
    for consistency with the `*-text-color` naming pattern
    (`--base-text-color-on-accent`, etc.). Components migrating
    SHOULD keep reading the legacy name as a deprecated alias for one
    release.
  - **D-BV-2's "common additions" checklist** in
    `base-variables.decisions.md` mirrors all of the above so new
    components see them when picking variables to consume.

### Why this round, in one paragraph

Running `/validate-web-component` against `@keenmate/web-multiselect`
v1.12.0-rc01 surfaced four cases where the component was doing
something sensible that the guidelines didn't yet describe —
conditional `color-scheme` flipping as a cleaner alternative to
variable-overriding, the wrapper-host background pattern that fits
form controls better than self-painted host, `position: relative`
becoming redundant when all floating UI uses `position: fixed`, and
~13 cross-component variables the canonical taxonomy was missing.
None of these were component bugs; they were guideline gaps. The
component was treated as a working artifact and the docs were
updated to match what it had already validated through practice.

## 2026-06-10

### Added

- New **component-intake** guideline
  (`web-components/component-intake.md`) covering the pre-flight
  decisions for a brand-new component: technology choice (vanilla web
  component / Lit / Svelte), package identity
  (`@<owner>/<tech-prefix>-<name>`, npm availability checked), and CSS
  prefix derivation. Encodes the algorithm: multi-word component name
  → initials of each word (`web-daterangepicker` → `drp`);
  single-word → first letter of tech + first letter of name
  (`web-player` → `wp`, `svelte-player` → `sp`). Existing reservations
  (e.g. `ltree`) override the derivation as legacy exceptions.

- `/new-component [hint]` slash command — interactive intake
  walkthrough. Asks the three questions, derives the prefix,
  cross-checks against the reservation table in `base-variables.md`,
  runs `npm view` to verify package-name availability, outputs a
  paste-ready metadata block for the new repo's README / CHANGELOG.
  Read-only: does not scaffold files or modify the guidelines repo.

- New **theme-container** guideline triad
  (`web-components/theme-container.{md,decisions.md,checks.md}`)
  covering how a component's root element anchors its CSS variables,
  default background, dark-mode overrides, and per-instance `data-theme`
  attribute. Spells out the dual shape: `:host` for web-components,
  `.<prefix>-container` for Svelte. Adds 14 checks (C-TC-1 through
  C-TC-14). Motivated by the `@keenmate/svelte-treeview` rc10
  migration that rescoped CSS variables from `:root` to
  `.ltree-container` — the `:root` scope is unreachable from consumer
  subtree wrappers and demonstrably broke `--base-*` overrides.

- `/validate-theme-container <path>` slash command — runs the 14 new
  checks. Detects component type (web-component vs Svelte) and adapts
  the verification accordingly.

- Project-level slash commands under `.claude/commands/` for validating
  component packages against the guidelines:
  - `/validate-base-variables <path>` — runs C-BV-1 through C-BV-12 plus
    a canonical `--base-*` taxonomy alignment report.
  - `/validate-color-scheme <path>` — runs C-CS-1 through C-CS-9 plus a
    JS-theme-detection invariant cross-check.
  - `/validate-css-structure <path>` — runs C-CSS-1 through C-CSS-12,
    respecting lean-strategy / underscore / no-layers decisions
    documented in the target component's README.
  - `/validate-web-component <path>` — umbrella command running all
    **47** checks (now including theme-container) plus the 10 CLAUDE.md
    invariants, with a PR-ready consolidated report.

  Commands read the live `.md` and `.checks.md` files at runtime, so
  changes to the canonical taxonomy or check definitions propagate
  automatically.

### Changed

- **Documented the unlayered-reset footgun in `css-structure.md`.**
  A consumer-side universal reset (`* { margin: 0; padding: 0; ... }`
  from Bootstrap reboot, Tailwind preflight, normalize.css, or
  hand-rolled) is unlayered and therefore beats every rule in the
  component's `@layer component` regardless of specificity, silently
  collapsing padding/margins even though the component's CSS variables
  resolved correctly. This is the cascade-layer contract working as
  designed — but it's the #1 way consumers accidentally clobber a
  layered library's defaults. We hit it concretely in the
  svelte-treeview showcase (2026-06) where the demo page's shared
  `* { padding: 0 }` reset wiped out `.ltree-node-content` padding.
  Added a new "The unlayered-reset footgun" subsection under "Consumer
  override contract" with the canonical recommendation (wrap resets in
  their own `@layer reset { ... }`); tightened **C-CSS-10** to require
  the component README warn consumers about it explicitly.

- **C-BV-2 narrowed to `--base-*` reads only.** The check previously
  flagged every `var()` without a fallback, which produced false
  positives for `var(--<prefix>-X)` reads in feature files — those
  reads are guaranteed defined because the container's `:host` /
  `.<prefix>-container` declaration always provides the chain. The
  two-layer pattern *intentionally* puts the fallback at the
  definition site, not at every read; the check now reflects that.
  Updated files: `base-variables.checks.md` (C-BV-2 rewritten),
  `base-variables.md` (new "Fallbacks live at the definition site"
  subsection making the rule explicit), `CLAUDE.md` invariant #9
  (tightened wording), `/validate-base-variables` slash command (C-BV-2
  note adjusted).

- Scope expanded: guidelines now explicitly cover both web-components
  (`:host`) and Svelte components (`.<prefix>-container`).
  `web-components/` folder name kept for backwards compatibility; the
  README and `CLAUDE.md` introduction clarify the broader applicability.
- `web-components/README.md` — added the theme-container row to the
  topic table, added a Theme-container section to the mandatory
  checklist, added theme-container to the brand-new-component reading
  order (between css-structure and base-variables).
- `web-components/base-variables.md` and `color-scheme.md` — added a
  one-line cross-reference pointing at `theme-container.md` for the
  question of *where* their rules anchor.
- `CLAUDE.md` — updated directory map to include theme-container,
  updated invariants #4 / #5 / #6 to cover both component types and
  the container-scope rule, added `ltree` and `sw` to the reserved
  prefix list.
- `/validate-web-component` umbrella command — now runs four triads
  (47 checks total) instead of three (33 checks), with the
  theme-container section threaded through the consolidated report.

- Initial web-component guidelines under `web-components/`:
  - `README.md` — index, mandatory checklist, vocabulary,
    project-wide invariants.
  - `css-structure.md` + `.decisions.md` + `.checks.md` — file
    layout, `@layer` cascade, BEM conventions.
  - `base-variables.md` + `.decisions.md` + `.checks.md` — two-layer
    `--base-*` / `--<prefix>-*` taxonomy, canonical variable set,
    manifest format.
  - `color-scheme.md` + `.decisions.md` + `.checks.md` — dark-mode
    handling, `light-dark()` fallbacks, framework-class hooks,
    per-instance overrides.
  - `example-web-player.md` — worked example applying all three topics.

- `CLAUDE.md` at repo root — agent guidance, directory map, workflow,
  ten non-negotiable cross-cutting invariants.
