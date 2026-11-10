# Release notes — Pre-Implementation Decisions

Answer these when you **adopt release notes in a repo** (or scaffold a
new package). Each has a recommended default; deviating requires a
one-line justification in the PR description.

Read [release-notes.md](./release-notes.md) first if any of these
questions don't make sense.

Settled for every repo — not decisions: **every npm-published version
gets a notes file** (rc and final; a fix-only patch gets a short one),
and **a final after rcs gets a consolidated guide** from the previous
final. See release-notes.md → "Which versions get notes".

---

## D-RN-1 — Where the notes live

**Question:** Which folder holds `release-notes/<version>.md`?

**Options:**

- **A — `release-notes/` at the publishable package root (default).**
  The repo root for a single-package repo; `packages/<name>/` in a
  monorepo, next to that package's `package.json`, so the folder can
  ship in the tarball.
- **B — `release-notes/` at the workspace root of a monorepo** that
  publishes one package. Only when the package directory is generated
  or wiped by the build; the notes then don't ship (D-RN-2 = B).

**Default:** A.

**Don't:** put notes under `docs/` — `docs/` is the API reference
(readme-structure.md), versioned with the code, not with releases.

**Your pick:** ____________

---

## D-RN-2 — Ship the notes in the npm tarball

**Question:** Is `release-notes` listed in `package.json` `files`?

**Options:**

- **A — Yes (default).** The upgrade guide is in `node_modules` next to
  the code it describes; agents and offline readers find it without a
  network round-trip.
- **B — No.** Notes live in the repo only. Requires D-RN-1 = B or a
  stated size constraint.

**Default:** A. The whole folder is text, typically < 100 KB.

**Your pick:** ____________

---

## D-RN-3 — Adopting in a repo with published history

**Question:** The repo already has published versions without notes.
What gets written first?

**Options:**

- **A — Start with the next publish (default).** That file's baseline
  is the last version on npm; nothing older is backfilled. C-RN-1 checks
  for gaps only from the oldest notes file onward.
- **B — Backfill the current major.** Write notes for every published
  version of the current major first — worth it when consumers are
  still upgrading across those versions (e.g. a major in rc with users
  on early rcs).

**Default:** A.

**Your pick:** ____________

---

## Decision summary (paste into PR description)

| Decision | Pick | Justification (if not default) |
|---|---|---|
| D-RN-1 — Notes folder | | |
| D-RN-2 — Ship in tarball | | |
| D-RN-3 — Adoption start | | |
