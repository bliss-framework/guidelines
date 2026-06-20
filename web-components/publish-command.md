# /publish — canonical command structure

Every component repo (web-components and Svelte components alike)
ships a `/publish` slash-command at
`.claude/commands/publish.md`. That file is what an agent reads
when the user types `/publish rc` (or `/publish release` /
`/publish patch` / etc.) in the component repo.

This file is the **source of truth** for what every component's
`/publish` MUST do. The per-repo file customizes only the
genuinely-structural sections (build / test commands, repo
layout, gotchas); the **unified sections** below must appear
byte-for-byte identical across all components, with only the
declared variables substituted.

Auto-check **C-PC-1** through **C-PC-N** in
[publish-command.checks.md](./publish-command.checks.md) verify
this convergence. If you find yourself wanting to deviate, raise
it as a change to the spec — don't fork the per-repo file.

---

## Why a canonical structure

Pre-2026-06 each component had its own `/publish` command with
subtle drift: some did `npm view` registry sanity checks, some
didn't; some drafted the What's New section, some required it
pre-written; one used `[Unreleased]` accumulator CHANGELOGs while
the rest used the `[PUBLISHED]`-tag convention; bullet-count
targets ranged from 5–7 to 5–8; the version-resolution decision
table varied. None of those differences had a reason — they were
just artifacts of each command being written separately.

Convergence pays three ways:

1. **One bug fix updates every component.** The `npm view`
   pre-check, once specified here, becomes mandatory in every
   `/publish`. If a component is missing it, C-PC-2 fails and
   the missing check is added in one PR.
2. **Reviewers know what to look for.** The PR description for
   a release is identical-shape across components; the commit
   subject is identical-shape; the report block the agent prints
   is identical-shape. Auditing a release is mechanical.
3. **New components scaffold cheap.** Adding `/publish` to a
   new component is "copy the template, fill the variables" —
   no inventing.

---

## Variables every per-repo publish.md MUST define

The per-repo file declares these in its YAML front-matter or in
a "Variables" block near the top. The canonical sections below
reference them with `{{VAR}}` markers; the per-repo file
substitutes them in.

| Variable | Meaning | Example |
|---|---|---|
| `{{PKG_NAME}}` | The npm package name | `@keenmate/web-multiselect` |
| `{{PKG_DIR}}` | Path to the publishable package root, relative to repo root | `.` (single-package) or `packages/web-grid` (monorepo) |
| `{{PKG_JSON_PATH}}` | Path to package.json | `./package.json` or `./packages/web-grid/package.json` |
| `{{PKG_JSON_RELATIVE}}` | Same as above but as a short name for prose | `package.json` or `packages/web-grid/package.json` |
| `{{CHANGELOG_PATH}}` | Path to CHANGELOG.md (workspace root in both layouts) | `./CHANGELOG.md` |
| `{{ROOT_README_PATH}}` | Path to the canonical README (workspace root) | `./README.md` |
| `{{NEXT_RC_EXAMPLE}}` | A plausible next-rc version for the inline arg-parsing example | `1.10.0-rc02` |
| `{{LAST_PUBLISHED_EXAMPLE}}` | Last-published version for the example | `1.9.0` |
| `{{ALLOWED_UNTRACKED_LIST}}` | The list of paths the repo intentionally keeps untracked / unstaged | `.claude/`, `test-results/`, `playwright-report/` |
| `{{BUILD_CMD}}` | The build command | `npm run build`, `npm run package`, or `make package` |
| `{{BUILD_DETAIL}}` | One sentence describing what the build command does | "Vite emits `dist/web-multiselect.js`…" |
| `{{TEST_CMD}}` | The test command (or "no programmatic test step" if none) | `npm run test:e2e` |
| `{{TEST_LABEL}}` | What the tests are | "e2e tests via Playwright" |
| `{{TEST_INSTALL_HINT}}` | If Playwright/similar needs install | "`npx playwright install chromium`" or empty |
| `{{TYPECHECK_CMD}}` | Type-check command if separate from build | `npm run type-check` or empty |
| `{{PACK_FILES}}` | What `npm pack --dry-run` should include | `dist/`, `src/css/`, `component-variables.manifest.json`, … |
| `{{PACK_LEAKS}}` | What it MUST NOT include | `test/`, `e2e/`, `*.spec.ts`, … |
| `{{STAGE_FILES}}` | Files to git-stage in the commit step | `./CHANGELOG.md`, `./README.md`, `./package.json` |
| `{{BUILD_GOTCHAS}}` | Per-repo build-time quirks (auto-bumped version.ts, README mirror, etc.) | "`pre-package.js` bumps `src/lib/version.ts`…" |

Per-repo files may add their own extra variables (e.g.
`{{PEER_DEP_SANITY}}` for web-switch's upstream svelte-switch
check) for repo-specific sanity checks. Those go in
repo-specific sections (Section 1 extras, Things-not-to-do
extras) — never in the unified sections.

---

## The CHANGELOG convention every repo uses

All repos use the **`[PUBLISHED]`-tag-on-WIP** convention. There
is **no `## [Unreleased]` section**. The WIP section is the
topmost `## [X.Y.Z] - YYYY-MM-DD` heading without a `[PUBLISHED]`
tag. Already-released sections carry `[PUBLISHED]` at the end of
their heading:

```
## [1.10.0] - 2026-06-18                  ← WIP, the one you're shipping
### Added
- ...

## [1.9.0] - 2026-06-09 [PUBLISHED]
### Added
- ...
```

Publishing the WIP section means **appending ` [PUBLISHED]`** to
its heading — exact format: `## [X.Y.Z] - YYYY-MM-DD [PUBLISHED]`.
The next development cycle creates a fresh
`## [next-version] - <date>` heading on its first CHANGELOG
edit; nothing in `/publish` creates an empty new WIP section.

Historical drift is tolerated: some repos' older sections may
miss the `[PUBLISHED]` tag (the convention wasn't applied
retroactively) or use legacy parenthetical markers like
`(unpublished)` / `- PUBLISHED -`. The publish flow doesn't
retro-fix those — it only finalizes the section currently being
shipped using the canonical format.

---

## Unified sections — required text

The 14 sections below appear in **every** per-repo publish.md in
**this order**, with the canonical text reproduced verbatim
modulo the `{{VAR}}` substitutions. Sections marked **[per-repo]**
have a repo-specific body that follows the rules called out below
but doesn't have a single canonical text.

### Section 1 — Argument

Canonical text (substitute `{{NEXT_RC_EXAMPLE}}`,
`{{LAST_PUBLISHED_EXAMPLE}}` etc. in the examples):

```markdown
## Argument

The release type: **$ARGUMENTS**

Must be one of:

- `rc` — ship the WIP rc as-is. The topmost CHANGELOG heading (e.g. `## [{{NEXT_RC_EXAMPLE}}] - 2026-06-18`) gets ` [PUBLISHED]` appended.
- `release` — promote a WIP rc to a final release. `X.Y.Z-rcN` → `X.Y.Z`. CHANGELOG heading is renamed to match the new version.
- `patch` — SemVer patch bump. Drops any `-rc` suffix.
- `minor` — SemVer minor bump. Drops `-rc`. Resets patch.
- `major` — SemVer major bump. Drops `-rc`. Resets minor and patch.

If missing or invalid, stop and ask the user which one to use (don't guess).
```

### Section 2 — Repo layout [per-repo]

This is **per-repo** because the layout is the structural fact
each file documents. The section MUST list, at minimum:

- The publishable package path (`{{PKG_DIR}}`) and whether it's a monorepo
- Where `CHANGELOG.md` lives (workspace root in both layouts; spell it out)
- Where `README.md` lives (workspace root; for monorepos, note that the package README is auto-synced from the root if applicable)
- The build output path (`dist/` location)
- Any per-repo gotcha file (auto-bumped `version.ts`, mirrored package README, etc.) — list one bullet per gotcha

### Section 3 — CHANGELOG convention

Canonical text:

```markdown
## CHANGELOG convention in this repo

There is **no `## [Unreleased]` section**. The WIP section is the topmost `## [X.Y.Z] - YYYY-MM-DD` heading without a `[PUBLISHED]` tag. Already-released sections carry `[PUBLISHED]` at the end of their heading:

\`\`\`
## [{{NEXT_RC_EXAMPLE}}] - 2026-06-18                  ← WIP, the one you're shipping
### Added
- ...

## [{{LAST_PUBLISHED_EXAMPLE}}] - 2026-06-09 [PUBLISHED]
### Added
- ...
\`\`\`

Publishing the WIP section means **appending ` [PUBLISHED]`** to its heading — exact format: `## [X.Y.Z] - YYYY-MM-DD [PUBLISHED]`. The next development cycle creates a fresh `## [next-version] - <date>` heading on its first CHANGELOG edit.
```

If the repo has historical drift, append a short paragraph after
the canonical text describing the specific legacy markers
(`(unpublished)`, `- PUBLISHED -`, missing tag on early
sections, etc.) and stating that they're **not** retro-fixed by
this flow. That paragraph is per-repo.

### Section 4 — Resolve versions

Canonical text:

```markdown
## Resolve versions

Read `{{PKG_JSON_PATH}}` `version` as `CURRENT_VERSION`.
Read the topmost `## [X.Y.Z...]` heading from `{{CHANGELOG_PATH}}` as `WIP_VERSION` (the version the latest WIP section is tagged for).

Compute `NEW_VERSION`:

| Argument | Logic |
|---|---|
| `rc` | If `CURRENT_VERSION` matches `X.Y.Z-rcN`, `NEW_VERSION = CURRENT_VERSION` (no bump — we're shipping what's already in package.json). If `CURRENT_VERSION` is not an rc, stop and ask the user (they probably wanted `release`/`patch`/etc.). |
| `release` | If `CURRENT_VERSION` matches `X.Y.Z-rcN`, `NEW_VERSION = X.Y.Z`. Otherwise stop. |
| `patch` | Strip any `-rcN`, then bump patch. |
| `minor` | Strip any `-rcN`, then bump minor, reset patch. |
| `major` | Strip any `-rcN`, then bump major, reset minor and patch. |

If `WIP_VERSION` ≠ `NEW_VERSION` (e.g. the WIP is `X.Y.Z-rcN` but the user asked for `release`), the CHANGELOG heading rename in step 3 also re-tags the section to `NEW_VERSION` — call this out in the report so the user notices.
```

### Section 5 — Step 1: Sanity checks

Canonical text (substitute `{{ALLOWED_UNTRACKED_LIST}}` and
`{{PKG_NAME}}`):

```markdown
### 1. Sanity checks

- Run `git status`. The repo intentionally keeps {{ALLOWED_UNTRACKED_LIST}} untracked — those are fine. If there are **other** uncommitted changes that aren't `CHANGELOG.md`, `README.md`, or `{{PKG_JSON_RELATIVE}}`, list them and ask the user before continuing. (Typical case: substantive source changes belonging in this release that haven't been committed yet — confirm they're intended for this version before bumping.)
- **Verify the new version isn't already on npm.** Run `npm view {{PKG_NAME}}@<NEW_VERSION> version 2>/dev/null` — if it returns the version string, that version is already published and **stop**: bumping over it would fail at publish time and pollute the commit.
- **Verify the registry hasn't drifted past you.** Run `npm view {{PKG_NAME}} version` to fetch the latest published version on the `latest` tag; if it's higher than `NEW_VERSION` (e.g. someone shipped from another machine, or there's a registry-vs-local mismatch from before the [PUBLISHED] convention landed), warn the user and ask before continuing.
- Confirm the WIP CHANGELOG section has at least one bullet of substantive content under `### Added`, `### Changed`, `### Removed`, `### Fixed`, or `### Internal`. If empty, stop — there's nothing meaningful to release.
- Confirm `{{ROOT_README_PATH}}` has a `## What's New in vWIP_VERSION` section. If it's missing, draft one from the CHANGELOG and present it to the user for approval before continuing:
  - Read the WIP CHANGELOG section, distill it to 5–8 scannable bullets covering the Added/Changed themes (paraphrase, don't copy CHANGELOG bullets verbatim — those are exhaustive; What's New is the highlight reel). Pure internal refactors and Fixed-only entries don't need coverage, though headline bug fixes worth advertising are worth a bullet.
  - **Follow the canonical "What's New" format** defined in the BlissFramework component guidelines (`web-components/readme-structure.md` → "`## What's New in vX.Y.Z` — canonical format"). Auto-check **C-RS-16** in `readme-structure.checks.sh` enforces it. Concretely:
    - **Heading:** `## What's New in vNEW_VERSION` — lowercase `v`, no backticks around the version, no date.
    - **Each bullet:** `- **<area or component> — <one-line headline>** — <engineer-level prose, 3–8 sentences>`. Bold-wrapped lead phrase, then a true em-dash (` — `, U+2014 with surrounding spaces), then a prose body explaining *what changed*, *why* (regression history / motivation), *what surface is affected* (concrete component / prop / file names listed inline), and *the mechanism* (the technique used). Plain hyphens or en-dashes fail the check.
    - **No `### ` sub-headings** inside a What's New section — no `### Added` / `### Fixed` lifted from the CHANGELOG. It's a flat bullet list.
    - **Reference implementation:** the `## What's New in v1.3.3` / `v1.3.2` sections at the top of `svelte-fluentui/README.md` are the canonical shape — mirror that voice and structure.
  - Show the user the proposed draft as plain markdown in your reply. Ask whether to (a) insert as-is, (b) edit, or (c) abort so they can write it themselves.
  - Only proceed past step 1 once the user approves the draft (or supplies their own). On approval, insert the section directly above the current top `## What's New in vX.Y.Z` heading in `{{ROOT_README_PATH}}`, then continue.
  - Do not silently insert the draft without confirmation — release highlights are a writing call and the user owns the voice.
```

Per-repo files MAY append extra bullets at the end of Section 1
for repo-specific sanity checks — e.g. web-switch's "verify the
`@keenmate/svelte-switch` dependency version is consistent with
the CHANGELOG mentions", web-grid's package-README mirror sanity
check. These extras go *after* the canonical bullets above; they
never replace them.

### Section 6 — Step 2: Bump version

Canonical text:

```markdown
### 2. Bump version (if needed)

If `NEW_VERSION` ≠ `CURRENT_VERSION`, edit `{{PKG_JSON_PATH}}` and change `"version": "CURRENT_VERSION"` to `"version": "NEW_VERSION"`.

For `rc` arg this is normally a no-op — version was bumped earlier in the development cycle.
```

If the repo has an auto-synced `version.ts` (or similar) that's
bumped during build, mention it here in one extra sentence —
otherwise this section is exactly three lines.

### Section 7 — Step 3: Finalize CHANGELOG

Canonical text:

```markdown
### 3. Finalize CHANGELOG

In `{{CHANGELOG_PATH}}`:

- If `WIP_VERSION` ≠ `NEW_VERSION` (e.g. promoting `X.Y.Z-rcN` → `X.Y.Z`), rename the WIP heading from `## [WIP_VERSION] - <date>` to `## [NEW_VERSION] - <today>` (today's date from system context).
- If `WIP_VERSION` == `NEW_VERSION`, leave the bracketed version alone but update the date to today **if** the existing date is stale (more than a few days old). The WIP date is usually whatever day the section was opened; refresh it so the changelog reflects the actual ship date.
- In either case, **append ` [PUBLISHED]`** to the heading so it reads exactly: `## [NEW_VERSION] - YYYY-MM-DD [PUBLISHED]`.
- Leave all bullet content untouched.
- **Do not** create an empty new WIP section — the next dev cycle's first CHANGELOG edit will create one.
```

### Section 8 — Step 4: Update README "What's New"

Canonical text:

```markdown
### 4. Update README "What's New" — only if version changed

In `{{ROOT_README_PATH}}`:

- If the existing `## What's New in vWIP_VERSION` section's version differs from `NEW_VERSION` (e.g. promoting `X.Y.Z-rcN` → `X.Y.Z`), rename its heading to `## What's New in vNEW_VERSION`. (No content rewrites — the text was already curated for this release.)
- Then count the `## What's New in vX.Y.Z` headings. If there are more than **two**, delete the oldest ones so only the **two most recent** remain (the just-finalized one plus the one before it).

For `rc` arg this is normally a no-op on the heading itself — only trims if someone left an extra-old section behind.
```

For monorepos that mirror the root README into the package
directory, append one bullet here describing the mirror step.
For svelte-fluentui's `post-package.js` auto-sync, append one
bullet noting the sync runs during build, not here.

### Section 9 — Step 5: Validate README reflects the release

Canonical text:

```markdown
### 5. Validate README reflects the release

Read both the finalized CHANGELOG section and the matching `What's New in vNEW_VERSION` section. Every **Added** or **Changed** bullet in the CHANGELOG that represents a user-facing feature or behavior change should have a corresponding hit in the What's New section (paraphrased, not verbatim). Pure internal refactors and `Fixed`-only entries don't need coverage, though headline bug fixes worth advertising (e.g. "X used to silently fail; now works") are worth a bullet.

If you find a significant CHANGELOG entry that isn't reflected in What's New, add a bullet for it. If the section ends up with more than ~8 bullets after this pass, condense — What's New should be scannable, not exhaustive.
```

### Section 10 — Step 6: Validate CHANGELOG entries match recent work

Canonical text:

```markdown
### 6. Validate CHANGELOG entries match recent work

Find the previous `[PUBLISHED]` tag in CHANGELOG (the version just before NEW_VERSION) and locate the commit that bumped to it — usually a commit whose subject starts with `v<previous-version>` or `- v<previous-version>`. Run `git log --oneline <previous-publish-commit>..HEAD` to list commits since.

Also check `git diff` (or `git status`) for any uncommitted source/test work outside the files you're editing in this command.

For every substantive commit or uncommitted change, verify the WIP CHANGELOG section mentions it. If something significant is missing, **stop and ask the user** before finalizing — don't invent entries on their behalf. Pure example/doc tweaks and trivial typo fixes don't need entries.
```

### Section 11 — Step 7: Run tests [per-repo]

This is **per-repo** because the test command and label vary.
The section MUST:

- Name the test command (`{{TEST_CMD}}`) and what it runs (`{{TEST_LABEL}}`).
- State that all specs must pass before the flow continues.
- If a test runner needs setup (`npx playwright install chromium`, etc.), include the hint.
- If the repo has **no** programmatic test step, the section still exists and explicitly says so — "this repo has no e2e harness; type-check is the only programmatic gate" or similar. Don't omit the section.

### Section 12 — Step 8: Build [per-repo]

Per-repo. MUST:

- Name the build command (`{{BUILD_CMD}}`) and what it does (`{{BUILD_DETAIL}}`).
- List the expected dist artifacts for a smoke check after build.
- Note any per-repo build-time gotchas (`{{BUILD_GOTCHAS}}`).

### Section 13 — Step 9: Verify package contents [per-repo]

Per-repo because the file list varies. MUST:

- Run `npm pack --dry-run`.
- List the files that MUST be in the tarball (`{{PACK_FILES}}`).
- List the files that MUST NOT leak in (`{{PACK_LEAKS}}`).
- Reference the `files` field in `package.json` as the control surface.

### Section 14 — Step 10: Commit

Canonical text:

```markdown
### 10. Commit

Stage:

{{STAGE_FILES}}

Do **not** stage `dist/` — it's gitignored.

Commit message format:

\`\`\`
vNEW_VERSION - <one-line summary of the headline change>

<grouped bullets paraphrased from the CHANGELOG section — split into the same
groups the CHANGELOG used: Added, Fixed, Changed, Internal, etc. Keep bullets
terse; full prose lives in the CHANGELOG.>

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
\`\`\`
```

`{{STAGE_FILES}}` is a per-repo bulleted list of paths
(`./CHANGELOG.md`, `./README.md`, `{{PKG_JSON_PATH}}`, etc.) —
plus any auto-generated files that need staging in this repo
(version.ts, mirrored package README, etc.).

### Section 15 — Step 11: Report

Canonical text:

```markdown
### 11. Report

Report back with:

- The new version number
- The commit SHA
- The exact commands to publish. **Pick the right one for the arg type:**
  - For `rc` (publishing a pre-release):
    \`\`\`
    {{CD_TO_PKG_DIR}}
    npm login          # if not already logged in
    npm publish --tag rc
    \`\`\`
    The `--tag rc` is critical — without it npm assigns the `latest` dist-tag, which would make the pre-release the default install for everyone running `npm install {{PKG_NAME}}`. With `--tag rc`, the `latest` tag stays put and consumers opt in via `@rc` or pinning the exact version.
  - For `release` / `patch` / `minor` / `major` (publishing a stable release):
    \`\`\`
    {{CD_TO_PKG_DIR}}
    npm login          # if not already logged in
    npm publish
    \`\`\`
    No `--tag` needed — it correctly lands as `latest`.
- A reminder that the CHANGELOG `[PUBLISHED]` tag is now in place — if `npm publish` fails, the user should revert both the tag (CHANGELOG heading) and the version bump (`{{PKG_JSON_RELATIVE}}`) before retrying, since the registry will refuse to re-publish the same version.
```

`{{CD_TO_PKG_DIR}}` is empty for single-package repos and
`cd {{PKG_DIR}}` for monorepos.

### Section 16 — Things not to do

Canonical text — every per-repo file ends with this section.
Extra repo-specific bullets MAY be appended at the end, but the
canonical ones MUST all be present:

```markdown
## Things not to do

- **Do not run `npm publish`.** The user publishes manually after `npm login`.
- **Do not push to git remote.** The commit stays local until the user pushes.
- **Do not create an empty `[Unreleased]` or new WIP heading** in CHANGELOG after finalizing — the next dev cycle's first edit creates the next heading.
- **Do not retro-fix older CHANGELOG sections** that are missing the `[PUBLISHED]` tag or carry legacy markers — only finalize the section you're shipping.
- **Do not silently insert a drafted What's New section.** If you draft one in Step 1 because it's missing, you must present it and wait for explicit approval (or edits) before inserting — the writing voice is the user's call, even when you're handing them a starting point.
- **Do not keep more than two `## What's New in vX.Y.Z` sections in the README.** Step 4 trims older ones; if you see three or more after Step 4, you missed one.
- **Do not skip the build step** — without it `dist/` is stale and the publish would ship outdated artifacts (or fail entirely if `dist/` was wiped by `make clean`).
- **Do not skip the test gate** if the repo has one — the gate is what catches regressions before they ship.
- **Do not invent CHANGELOG entries** to cover commits you find; ask the user if something's missing.
- **Do not bump if there's nothing meaningful in the WIP section** — stop and explain.
```

---

## What's *not* canonical

The following are deliberately left to each repo because the
underlying fact varies:

- **The test step body** — Playwright vs vitest vs none.
- **The build step body** — `npm run build` vs `make package`
  vs Vite-only vs svelte-package vs custom pre/post hooks.
- **The package contents check** — different `files` fields, different
  dist outputs (single `.js` + `.css` vs ESM + UMD + d.ts vs Svelte
  components).
- **The repo layout section** — single-package vs monorepo paths,
  CHANGELOG-at-root vs CHANGELOG-in-package, mirrored READMEs.
- **Repo-specific sanity-check bullets** (e.g. peer-dep version
  consistency for wrapper packages) — these go after the canonical
  bullets in Section 1.
- **Repo-specific "Things not to do"** bullets — these go after
  the canonical ones.

Per-repo files SHOULD also include a brief "Repo layout" section
near the top (between Argument and CHANGELOG convention)
describing the layout and any gotchas an agent needs to know.

---

## Where this gets enforced

- [publish-command.checks.md](./publish-command.checks.md) lists
  the auto-checks that detect drift in any component's publish.md.
- The checks run against a component package via
  `publish-command.checks.sh <component-package-path>`.
- The summary check **C-PC-0** is "the file exists at
  `.claude/commands/publish.md`" — components without `/publish`
  fail it, signalling the command should be scaffolded from this
  spec.

---

## When to edit this spec

When you want to change the publish flow for every component at
once. A change here is a coordination move — it touches 8+
component repos' publish.md files via subsequent edits, and the
checks ensure they stay in sync.

When you want to permit a one-off deviation for a single
component (e.g. svelte-fluentui's `pre-package.js` /
`post-package.js` hooks), DON'T modify this spec — extend the
per-repo file's per-repo section (Repo layout, Build step, etc.).
The spec governs only the unified sections; the per-repo sections
are where individuality lives.
