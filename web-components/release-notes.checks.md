# Release notes — Post-Implementation Checks

Run every check below **before publishing** a version (the `/publish`
flow runs them in Step 5), and when adopting the convention in a repo.
Mark each as ✅ pass, ❌ fail, ⚠️ exception (with reason), or N/A in
the PR description.

Read [release-notes.md](./release-notes.md) for rationale and
[release-notes.decisions.md](./release-notes.decisions.md) for the
matching decision tags.

Each check is tagged **`[auto]`**, **`[semi]`**, or **`[manual]`** —
see [css-structure.checks.md](./css-structure.checks.md) for the
meaning of each tier. `release-notes.checks.sh` runs C-RN-1 … C-RN-9.

> **Applicability.** Every package published to npm. Before adoption
> (no `release-notes/` folder yet) the script reports the triad as not
> adopted and fails C-RN-1 — see D-RN-3 for where to start.

---

## C-RN-1 — Every published version since adoption has notes

**Tier:** `[auto]`

**What:** Walking the CHANGELOG top-down, every `## [X.Y.Z…] - … [PUBLISHED]`
heading down to (and including) the version of the oldest notes file has
`release-notes/<version>.md`. The WIP section (no `[PUBLISHED]` tag) is
reported as "pending" when it has no notes yet — not a failure until
`/publish` runs.

A version tagged `[PUBLISHED]` that never actually reached npm (its
changes folded into the next notes file) is a legitimate exception —
mark it ⚠️ with the version that folds it in.

**Pass:** No published version since adoption is missing its notes.

**Failure mode:** A reader on `3.0.0-rc01` looking for what changed in
`rc02` finds nothing and has to diff the CHANGELOG by hand.

**Tag:** D-RN-3.

---

## C-RN-2 — File names are exact versions

**Tier:** `[auto]`

**What:** Every file in `release-notes/` matches
`<major>.<minor>.<patch>[-rc<NN>].md` — no `v` prefix, nothing else in
the folder.

**Pass:** All file names are versions.

**Failure mode:** `v3.0.0.md`, `3.0.0-notes.md`, a stray `draft.md` —
links from the README and between notes files stop being predictable,
and C-RN-1 can't find them.

---

## C-RN-3 — Header: title, status line, CHANGELOG link

**Tier:** `[auto]`

**What:** In every notes file:

1. Line 1 is `# <Display Name> <version> — Release Notes`, with
   `<version>` equal to the file name.
2. A `**Released:** YYYY-MM-DD · ` status line follows. It says
   `**Pre-release**` with an `@rc` install command for an `-rc`
   version, and `**Stable**` for a final.
3. The header links `CHANGELOG.md` with an absolute `https://` URL.

**Pass:** All three hold in every file.

**Failure mode:** A copied file still says the previous version in its
title; a final release says "Pre-release"; the CHANGELOG link is
relative and dead in `node_modules`.

---

## C-RN-4 — Required sections present, canonical order

**Tier:** `[auto]`

**What:** `## Contents`, `## Requirements` and `## Upgrade checklist`
are present. Every `##` heading is one of the canonical sections, in
this order (each optional one may be absent):

`Contents` → `Requirements` → `Upgrade checklist` → `Breaking changes`
→ `Behaviour changes` → `New features` (or several `New features — <area>`)
→ `New API` → `Visible changes without a migration` → `Fixes` →
`Internal`.

**Pass:** Required sections present; no unknown `##` heading; order
holds.

**Failure mode:** A reader who learned the shape from one component
can't find the checklist in the next; `## What's new` / `## Changes`
reinvent sections the template already has.

---

## C-RN-5 — Contents lists every section

**Tier:** `[auto]`

**What:** The numbered list under `## Contents` links every `##`
section that follows it, in order, by its anchor.

**Pass:** Contents and headings match one-to-one.

**Failure mode:** A section added late isn't in Contents; a reader
scanning the list misses the breaking change.

---

## C-RN-6 — Every in-file anchor resolves

**Tier:** `[auto]`

**What:** Every `](#anchor)` link (Contents, `[details](#…)`,
`[table](#…)`) matches a heading in the same file, using GitHub's slug
rules (lowercase; punctuation dropped; spaces → `-`; an em-dash between
spaces yields `--`).

**Pass:** No dangling anchor.

**Failure mode:** The checklist's `[details]` link jumps nowhere — the
reader loses the explanation exactly where they needed it.

---

## C-RN-7 — Upgrade-checklist items are task boxes

**Tier:** `[auto]`

**What:** Every top-level bullet under `## Upgrade checklist` starts
with `- [ ] `, and the section has at least one.

**Pass:** All items are task boxes.

**Failure mode:** A plain bullet list can't be pasted into an issue and
ticked off; an empty section leaves the reader unsure whether there's
nothing to do — write `- [ ] Nothing required: <why>`.

---

## C-RN-8 — `release-notes` ships in the tarball

**Tier:** `[auto]`

**What:** `package.json` `files` contains `release-notes` (or
`release-notes/`). If there's no `files` field, everything ships — pass.

**Pass:** Listed, or no `files` field. N/A if D-RN-2 = B.

**Failure mode:** The upgrade guide exists on GitHub but not in
`node_modules`, where agents and offline readers look.

**Tag:** D-RN-2.

---

## C-RN-9 — README What's New sections link their notes

**Tier:** `[auto]`

**What:** Every `## What's New in vX.Y.Z` section in the README links
`release-notes/X.Y.Z.md` (the upgrade-guide line), for every version
that has a notes file.

**Pass:** Each What's New section with notes links them.

**Failure mode:** The landing page shows the highlights and never says
there's an upgrade guide.

---

## C-RN-10 — Requirements match `package.json`

**Tier:** `[semi]`

**What:** For the version being published, every `@keenmate/*`
dependency in `package.json` appears in the Requirements table with the
version range's base (`^1.0.0-rc21` → `1.0.0-rc21`); optional packages
the component reads (`@keenmate/base-css-variables`) are listed; the
browser floor matches the README / docs.

**How to verify:**
```bash
node -e "const p=require('./package.json');console.log({...p.dependencies,...p.peerDependencies})"
sed -n '/^## Requirements/,/^---/p' release-notes/<version>.md
```

**Pass:** Table and `package.json` agree.

**Failure mode:** Notes say core rc18 while the package needs rc21; a
reader pinning core by the notes gets runtime errors.

---

## C-RN-11 — Baseline is right

**Tier:** `[semi]`

**What:** The opening paragraph's baseline follows release-notes.md →
"The baseline": the last version on npm for an rc or a straight final,
the **previous final** for a final after rcs (a consolidated guide that
links the rc notes). Unpublished versions in between are named as
folded in.

**How to verify:**
```bash
npm view <pkg> versions --json | tail -5
grep -m1 -E 'changes since' release-notes/<version>.md
```

**Pass:** The named baseline is the version the rules call for.

**Failure mode:** A `3.0.0` final whose notes cover only "since rc03" —
the reader on `2.6.0` is told almost nothing changed.

---

## C-RN-12 — Notes cover the CHANGELOG

**Tier:** `[manual]`

**What:** Read the CHANGELOG sections between the baseline and this
version. Every Removed / breaking Changed entry has a `### ` under
Breaking changes **and** an Upgrade-checklist item; every changed
default or interaction has a Behaviour change; user-visible Added
entries appear under New features / New API; consumer-observable fixes
appear under Fixes. Each breaking / behaviour change says why, and a
changed default names the setting that restores the old behaviour.

**Pass:** A reader on the baseline can upgrade with this file alone.

**Failure mode:** The one rename nobody listed is the one that breaks
the consumer's form in production.

---

## Summary checklist (paste into PR description)

```
[ ] C-RN-1  [auto]   Every published version since adoption has release-notes/<version>.md
[ ] C-RN-2  [auto]   File names are exact versions (no v, nothing else in the folder)
[ ] C-RN-3  [auto]   Header: title with version, Released/status line, absolute CHANGELOG link
[ ] C-RN-4  [auto]   Contents + Requirements + Upgrade checklist present; sections canonical and in order
[ ] C-RN-5  [auto]   Contents lists every ## section in order
[ ] C-RN-6  [auto]   Every #anchor link resolves to a heading in the file
[ ] C-RN-7  [auto]   Upgrade-checklist items are `- [ ]` task boxes (at least one)
[ ] C-RN-8  [auto]   package.json files includes release-notes (or D-RN-2 = B)
[ ] C-RN-9  [auto]   README What's New sections link their notes files
[ ] C-RN-10 [semi]   Requirements table matches package.json dependencies
[ ] C-RN-11 [semi]   Baseline follows the rules (consolidated for a final after rcs)
[ ] C-RN-12 [manual] Notes cover every breaking / behaviour change in the CHANGELOG
```
