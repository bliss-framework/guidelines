# /publish Command — Post-Implementation Checks

Run every check below **after** scaffolding or editing a
component's `.claude/commands/publish.md`, and **before** declaring
the work done.

Each check: what to look for, how to verify, what failure looks
like. Failing any check means the file is not aligned with the
canonical spec. Mark each as ✅ pass, ❌ fail, ⚠️ exception (with
reason), or N/A in the PR description.

Read [publish-command.md](./publish-command.md) for the canonical
structure that the per-repo files must follow.

Each check is tagged **`[auto]`**, **`[semi]`**, or **`[manual]`**
— same convention as the rest of the rulebook.

---

## C-PC-0 — `publish.md` exists at `.claude/commands/`

**Tier:** `[auto]`

**What:** The component package has a `.claude/commands/publish.md`
file (relative to the component repo root, not necessarily the
publishable package directory in a monorepo).

**How to verify:**
```bash
test -f <component-repo>/.claude/commands/publish.md && echo ok || echo missing
```

**Pass:** The file exists.

**Failure mode:** Releasing requires manual recall of all the
canonical steps (`npm view` pre-check, [PUBLISHED] tag append,
README What's New trim, etc.). Steps get skipped, mistakes ship.

**Fix:** Scaffold from [publish-command.md](./publish-command.md)
using one of the existing component publish.md files as a template
(web-multiselect for single-package, web-grid for monorepo,
svelte-fluentui for monorepo with auto-sync hooks).

**Tag:** D-PC-1 (yet to be added).

---

## C-PC-1 — Canonical section headings present in order

**Tier:** `[auto]`

**What:** The publish.md contains all canonical section headings,
in the order defined in `publish-command.md`:

1. `## Argument [canonical]`
2. `## Repo layout [per-repo]`
3. `## CHANGELOG convention in this repo [canonical]`
4. `## Resolve versions [canonical]`
5. `## Steps (in order)`
   - `### 1. Sanity checks [canonical]`
   - `### 2. Bump version (if needed) [canonical]`
   - `### 3. Finalize CHANGELOG [canonical]`
   - `### 4. Update README "What's New" — only if version changed [canonical]`
   - `### 5. Validate README reflects the release [canonical]`
   - `### 6. Validate CHANGELOG entries match recent work [canonical]`
   - `### 7. Run tests [per-repo]`
   - `### 8. Build the package [per-repo]`
   - `### 9. Verify the package contents [per-repo]`
   - `### 10. Commit [canonical]`
   - `### 11. Report [canonical]`
6. `## Things not to do [canonical]`

**How to verify:** the auto-script greps for each heading and
records line numbers. Missing or out-of-order headings fail.

**Pass:** All headings present in order with the correct
`[canonical]` / `[per-repo]` tag.

**Failure mode:** Drift from the canonical structure. New
contributors looking at the file can't compare flows side-by-side
because the order varies; checks that pattern-match on heading
numbers break.

**Tag:** D-PC-1.

---

## C-PC-2 — `npm view` registry pre-check present

**Tier:** `[auto]`

**What:** Step 1 (Sanity checks) contains both `npm view` calls:

- `npm view <PKG_NAME>@<NEW_VERSION> version 2>/dev/null` — stop if the version is already published
- `npm view <PKG_NAME> version` — warn if the registry-latest version is higher than `NEW_VERSION`

This is the single most important pre-check — without it, an `rc`
re-publish over an already-published version only fails at the
`npm publish` step itself, by which point a redundant
`[PUBLISHED]`-tagged commit is already on `HEAD`.

**How to verify:**
```bash
grep -E "npm view <PKG_NAME>@<NEW_VERSION>|npm view .+@<NEW_VERSION>" <publish.md>
grep -E "npm view .+ version" <publish.md>
```

Both must match.

**Pass:** Both `npm view` calls appear in Step 1.

**Failure mode:** Same as svelte-fluentui's pre-2026-06-18 state —
re-publishing an existing rcN proceeds through the entire flow,
fails only at `npm publish`, leaves a bogus commit behind.

**Tag:** D-PC-1.

---

## C-PC-3 — Version resolution table is byte-identical to canonical

**Tier:** `[auto]`

**What:** The `## Resolve versions` section's decision table
(`| Argument | Logic |`) is byte-identical to the canonical table
in `publish-command.md` Section 4, modulo no substitutions (the
table itself has no variables — only the prose around it
substitutes `{{PKG_JSON_PATH}}` / `{{CHANGELOG_PATH}}`).

**How to verify:** the auto-script extracts the table block from
each publish.md and the canonical spec, and compares md5 hashes.

**Pass:** md5 of the table block matches across all components.

**Failure mode:** Subtle bumping-logic drift. One component's `rc`
behavior differs from another's — e.g. one stops on
"non-rc CURRENT_VERSION with `rc` arg", another silently bumps to
a fresh rc01.

**Tag:** D-PC-1.

---

## C-PC-4 — Canonical "Things not to do" block byte-identical

**Tier:** `[auto]`

**What:** The first 10 bullets of `## Things not to do` are
byte-identical across all component publish.md files (matching
the canonical text in `publish-command.md` Section 16). Per-repo
extras MAY appear after as a `### Repo-specific don'ts`
sub-section.

**How to verify:** md5 of the bullets-only portion.

**Pass:** md5 matches across all components.

**Failure mode:** Different components forbid different things —
e.g. one says "Do not push to git remote" and another silently
omits it. Reviewers lose the cross-component contract that the
list provides.

**Tag:** D-PC-1.

---

## C-PC-5 — Canonical "What's New" format reference present in Step 1

**Tier:** `[auto]`

**What:** Step 1's draft-What's-New block references the canonical
format at `web-components/readme-structure.md → '## What's New in
vX.Y.Z — canonical format'` AND mentions auto-check **C-RS-16**.

This is the bridge between the publish flow and the README
structure rule. Without it, `/publish` agents might draft a
non-canonical What's New section that then fails C-RS-16 at the
README check.

**How to verify:**
```bash
grep -E "readme-structure\.md.*canonical format" <publish.md>
grep -E "C-RS-16" <publish.md>
```

Both must match.

**Pass:** Both references appear in Step 1.

**Failure mode:** A component's `/publish` drafts a What's New
section in some other format (the old loose `## What's new` from
pre-2026-06, or a `### Added` / `### Fixed` lift from CHANGELOG).
The next run of `readme-structure.checks.sh` fails C-RS-16 and the
user has to rewrite the section by hand.

**Tag:** D-PC-1.

---

## C-PC-6 — Commit message format declared

**Tier:** `[auto]`

**What:** Step 10 (Commit) contains the canonical commit message
template (`vNEW_VERSION - <one-line summary>` subject, grouped
bullets body, `Co-Authored-By: Claude Opus 4.7 (1M context)`
trailer).

**How to verify:**
```bash
grep -E "^vNEW_VERSION - <one-line summary" <publish.md>
grep -E "Co-Authored-By: Claude Opus 4.7" <publish.md>
```

Both must match.

**Pass:** Both lines appear in Step 10.

**Failure mode:** Commit subjects vary across components — one says
`v1.10.0 - ...`, another says `release 1.10.0`, another uses
`vX.Y.Z:` with a colon. Cross-component `git log` becomes
inconsistent and `/babysit-prs`-style audit scripts can't grep for
release commits reliably.

**Tag:** D-PC-1.

---

## C-PC-7 — Publish-command reference present at top

**Tier:** `[auto]`

**What:** The publish.md's intro paragraph (between the title and
`## Argument`) references the canonical spec at
`web-components/publish-command.md`. This anchors the file —
readers know where to look for the source of truth on every
unified section.

**How to verify:**
```bash
grep -E "web-components/publish-command\.md" <publish.md>
```

**Pass:** Reference present.

**Failure mode:** The per-repo file looks like a standalone
artifact; future contributors edit it without realizing they're
changing canonical text and need to update the spec.

**Tag:** D-PC-1.

---

## C-PC-8 — Section tags consistent with canonical spec

**Tier:** `[auto]`

**What:** Each section heading carries the correct
`[canonical]` / `[per-repo]` tag matching the spec. A `[canonical]`
section MUST NOT be a `[per-repo]` section in one file and vice
versa.

The expected tags:

| Section | Tag |
|---|---|
| Argument | `[canonical]` |
| Repo layout | `[per-repo]` |
| CHANGELOG convention | `[canonical]` |
| Resolve versions | `[canonical]` |
| Step 1 Sanity checks | `[canonical]` |
| Step 2 Bump version | `[canonical]` |
| Step 3 Finalize CHANGELOG | `[canonical]` |
| Step 4 Update README "What's New" | `[canonical]` |
| Step 5 Validate README | `[canonical]` |
| Step 6 Validate CHANGELOG | `[canonical]` |
| Step 7 Run tests | `[per-repo]` |
| Step 8 Build the package | `[per-repo]` |
| Step 9 Verify the package contents | `[per-repo]` |
| Step 10 Commit | `[canonical]` |
| Step 11 Report | `[canonical]` |
| Things not to do | `[canonical]` |

**How to verify:** the auto-script reads each heading line and
checks the trailing tag against the table.

**Pass:** Every heading carries the correct tag.

**Failure mode:** A `[canonical]` section gets edited as if it
were `[per-repo]`, drift sets in unnoticed.

**Tag:** D-PC-1.

---

## C-PC-9 — README "What's New" draft block uses 5–8 bullet count

**Tier:** `[auto]`

**What:** The Step 1 draft-What's-New sub-bullet specifies a
5–8 bullet count target. Earlier drift had some components saying
5–7, some 5–8 — the canonical target is 5–8.

**How to verify:**
```bash
grep -E "5.{1,3}8 scannable bullets" <publish.md>
```

**Pass:** The 5–8 phrase appears.

**Failure mode:** Components diverge on how big a What's New
section should be; trim decisions vary.

**Tag:** D-PC-1.

---

## C-PC-10 — Step 10 stage-list mentions CHANGELOG + README + package.json

**Tier:** `[auto]`

**What:** Step 10's stage list includes (at minimum):

- The repo's CHANGELOG
- The canonical README
- The publishable package's `package.json`

For monorepos and repos with auto-generated tracked files
(`version.ts`, `constants.generated.ts`, mirrored package READMEs)
the list grows — but the three above are always present.

**How to verify:**
```bash
grep -E "CHANGELOG\.md" <publish.md>      # somewhere in Step 10
grep -E "README\.md"    <publish.md>      # somewhere in Step 10
grep -E "package\.json" <publish.md>      # somewhere in Step 10
```

**Pass:** All three appear under the Step 10 heading.

**Failure mode:** A publish flow forgets to stage the CHANGELOG
or README; the `[PUBLISHED]` tag never lands in git.

**Tag:** D-PC-1.

---

## Summary checklist (paste into PR description)

```
[ ] C-PC-0  [auto]   publish.md exists at .claude/commands/
[ ] C-PC-1  [auto]   Canonical section headings present in order
[ ] C-PC-2  [auto]   npm view registry pre-check present in Step 1
[ ] C-PC-3  [auto]   Version-resolution table byte-identical to canonical
[ ] C-PC-4  [auto]   "Things not to do" first-10 bullets byte-identical to canonical
[ ] C-PC-5  [auto]   What's New canonical-format + C-RS-16 references present in Step 1
[ ] C-PC-6  [auto]   Commit message format declared in Step 10
[ ] C-PC-7  [auto]   Reference to publish-command.md present at top
[ ] C-PC-8  [auto]   Section [canonical] / [per-repo] tags match the spec table
[ ] C-PC-9  [auto]   What's New draft uses 5–8 bullet count target
[ ] C-PC-10 [auto]   Step 10 stage-list mentions CHANGELOG + README + package.json
```
