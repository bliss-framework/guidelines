# Release notes — the per-version upgrade guide

**Applies to every published component package** (web-components,
Svelte components, and libraries such as `web-components-core`). Every
version that reaches npm — rc or final — ships a
`release-notes/<version>.md`: the document a consumer reads to move
their code from the version they have to this one.

Walk [release-notes.decisions.md](./release-notes.decisions.md) when you
adopt the convention in a repo, and run
[release-notes.checks.md](./release-notes.checks.md) (C-RN-1 … C-RN-12)
before every publish. The `/publish` flow drafts and verifies the notes
([publish-command.md](./publish-command.md) → Step 1, Step 5, Step 10).

**Reference implementation:** `@keenmate/web-multiselect` —
`release-notes/2.6.0-rc02.md`, `2.6.0-rc03.md`, `3.0.0-rc01.md`,
`3.0.0-rc02.md` (`C:\Git\KM\web-multiselect\release-notes\`). When in
doubt about tone or depth, read `3.0.0-rc01.md` (a major) and
`2.6.0-rc03.md` (a small rc).

---

## Three artifacts, three jobs

A release is described in three places. Each has one job; don't make
one do another's.

| Artifact | Job | Reader | Shape |
|---|---|---|---|
| `CHANGELOG.md` section | **Complete record** — every Added / Changed / Removed / Fixed / Internal change | Maintainers, auditors, "was X fixed in this version?" | Keep-a-Changelog, per version, terse |
| README `## What's New in vX.Y.Z` | **Highlights** — what's worth knowing, at a glance | Someone landing on the package page | 1–8 bullets, flat ([readme-structure.md](./readme-structure.md) → canonical format) |
| `release-notes/<version>.md` | **Upgrade guide** — what you must change, and why, with before → after | Someone upgrading an existing app | The template below |

The release notes are the **only** one written for the person who
already uses the component. The CHANGELOG tells them *what* changed; the
notes tell them *what to do about it*, in the order they'd do it, with
the old and new code side by side.

---

## Which versions get notes

**Every version published to npm**, rc and final alike. No exceptions
for size: a patch with two fixes gets a short file (header, Requirements,
an Upgrade checklist saying "Nothing required", Fixes). A short file
costs five minutes; a missing one leaves the reader guessing whether
there's nothing to do or nobody wrote it down.

A version that was committed but **never reached npm** gets no file of
its own. Its changes are folded into the next published version's
notes, and that file says so ("2.6.0-rc04 was never published; its
changes are folded in here").

### The baseline — "since what?"

Every notes file states its baseline in the opening paragraph: the
version the reader is assumed to be on.

| Version being published | Baseline | Example |
|---|---|---|
| An rc (`X.Y.Z-rcN`) | The **last version on npm** — whatever it was | `3.0.0-rc02` covers changes since `3.0.0-rc01` |
| The first rc after a final | The last version on npm (that final) | `3.1.0-rc01` covers changes since `3.0.0` |
| A final after rcs (`X.Y.Z` after `X.Y.Z-rc01 … rcN`) | The **previous final** — a **consolidated guide** | `3.0.0` covers `2.6.0` → `3.0.0` in one file |
| A final with no rcs (`patch` / `minor` / `major` straight to final) | The last version on npm (the previous final) | `2.4.0` covers changes since `2.3.0` |

The **consolidated guide** for a final after rcs is a fresh document,
not a concatenation of the rc notes. Someone on `2.6.0` moving to
`3.0.0` reads one file with one upgrade checklist; they don't chain
through three rcs, two of which renamed the same attribute twice. The
rc notes stay in the folder as history; the final's opening paragraph
links them for anyone who followed the rcs ("Coming from an rc? The
[3.0.0-rc03 notes](3.0.0-rc03.md) list what changed since the last
rc.").

An rc's notes link back to the notes for earlier steps a reader may
still need: "Upgrading from 2.5? Read the [2.6.0-rc02](2.6.0-rc02.md)
and [2.6.0-rc03](2.6.0-rc03.md) notes first."

---

## Location and shipping

- **Folder:** `release-notes/` at the root of the **publishable
  package** (`{{PKG_DIR}}` in `/publish` terms — the repo root for a
  single-package repo, `packages/<name>/` in a monorepo). D-RN-1.
- **File name:** the exact `package.json` version, no `v`, `.md`:
  `3.0.0-rc02.md`, `2.4.0.md`. One file per published version; nothing
  else in the folder.
- **Shipped in the tarball:** `"release-notes"` is listed in
  `package.json` `files`, so the guide is in `node_modules` next to the
  code it describes. D-RN-2.
- **Linked from the README:** every `## What's New in vX.Y.Z` section
  opens with an upgrade-guide line pointing at its notes file, and an
  "Earlier releases" line after the retained sections links the older
  notes (see "README integration" below).

---

## The template

Copy this skeleton. Sections run in the order shown; **drop a section
that would be empty** (except Requirements and Upgrade checklist, which
are always present). Never reorder, never rename.

````markdown
# <Display Name> <version> — Release Notes

**Released:** YYYY-MM-DD · **Pre-release** (`npm install <pkg>@rc`)

These notes cover the changes since **<baseline>**, the last version on npm. <Links to
earlier notes a reader may still need.>

<One short paragraph: what this release is about — its one to three themes. For a major:
"This is a **major release: breaking, with no aliases.** … A `^2.x` range will not pull this
version.">

The exhaustive, per-change list is in
[`CHANGELOG.md`](https://github.com/<org>/<repo>/blob/<branch>/CHANGELOG.md) (section
<version>); this document is the upgrade guide and the highlights.

---

## Contents

1. [Requirements](#requirements)
2. [Upgrade checklist](#upgrade-checklist)
3. [Breaking changes](#breaking-changes)
…

---

## Requirements

| Package / platform | Version |
|---|---|
| `@keenmate/web-components-core` | `1.0.0-rc18` (dependency, installed for you) |
| `@keenmate/base-css-variables` | optional; `2.0.0` |
| Browsers | Chrome/Edge 119+, Firefox 128+, Safari 18+ (unchanged) |

---

## Upgrade checklist

**<Audience>**

- [ ] <What to change, imperative, with the old → new names inline.>
      ([details](#anchor-of-the-section-that-explains-it))

**<Another audience>**

- [ ] Nothing required: <why — e.g. "multi-select defaults are unchanged">.

---

## Breaking changes

### <One change per ###>

<What it was, what it is now, why. A Before → Now table when there's more than one pair.>

---

## Behaviour changes

## New features            (or: ## New features — <area>, repeatable)

## New API                 (optional: a table of new events / methods / exports)

## Visible changes without a migration

## Fixes

## Internal
````

For a final release the status line reads
`**Released:** YYYY-MM-DD · **Stable** (\`npm install <pkg>\`)`.

### Header

- **Title:** `# <Display Name> <version> — Release Notes` — the
  component's display name (`Web MultiSelect`, `Svelte Treeview`), the
  exact version from the file name, a true em-dash.
- **Status line:** `**Released:**` + ISO date + ` · ` + `**Pre-release**`
  with the `@rc` install command, or `**Stable**` with the plain one.
  The date is the publish date (the same as the `[PUBLISHED]` CHANGELOG
  heading).
- **Baseline paragraph** — see "The baseline" above. Name the baseline
  version in bold. Fold in unpublished versions explicitly.
- **Theme paragraph** — what the release is *about*, in 2–5 sentences.
  For a major, say it's breaking and whether aliases exist, and spell
  out the semver consequence (`A ^2.x range will not pull this
  version.`).
- **CHANGELOG link** — the fixed sentence above, with an **absolute**
  GitHub URL. The notes are read from `node_modules`, the npm tarball
  and GitHub; a relative `../CHANGELOG.md` only resolves on GitHub.
  Links between notes files are relative (`[2.6.0-rc03](2.6.0-rc03.md)`)
  — they always sit side by side.

### Contents

A numbered list linking every `##` section that follows, in order.
Present in every file, even a short one — it's the shape a reader
learns once.

### Requirements

Always present. A two-column table: `Package / platform` | `Version`.
Rows:

- every `@keenmate/*` **dependency** with the exact version this release
  was built and tested against, plus "(dependency, installed for you)";
  add a few words when the bump brings something the reader should know
  ("adds the `/search` module");
- every **optional / peer** package the component reads (typically
  `@keenmate/base-css-variables`) with "optional;" and the version whose
  names are read;
- **Browsers** — the supported floor, with "(unchanged)" when it didn't
  move. A raised floor gets a paragraph under the table explaining why.

### Upgrade checklist

Always present. **This is the section most readers use** — everything
else explains it.

- **Grouped by audience**, each group a bold line: `**Everyone (HTML
  attributes)**`, `**JS API users**`, `**Callback authors**`,
  `**Event listeners**`, `**Form users**`, `**Theme authors**`,
  `**Page CSS / \`custom-styles\`**`, `**Single-select users**`, … Pick
  the groups that fit the release; a reader skips the groups that
  aren't them.
- **Every item is a task box** — `- [ ] …` — so it can be pasted into
  an issue and ticked off.
- **Imperative, with the names inline** — "Rename `mobile-presentation`
  → `presentation`", not "The attribute was renamed".
- **Every item that has an explanation links to it** —
  `([details](#anchor))` or `([table](#anchor))`. The link targets a
  heading in the same file.
- **"Nothing required" is an item** — `- [ ] Nothing required: <why>`.
  Say it explicitly for an audience that might worry; that's an
  answer, not an omission.
- Every Breaking change and every Behaviour change that can bite
  (changed default, changed timing, changed event detail) has **at least
  one checklist item**. A breaking change without a checklist item is a
  bug in the notes.

### Breaking changes / Behaviour changes

- **Breaking changes** — code written for the baseline stops working or
  stops compiling: removed / renamed attributes, properties, methods,
  events, CSS classes, variables, types; changed signatures.
- **Behaviour changes** — the code still runs, but does something
  different: a new default, a changed interaction, a value read from a
  different place.
- **One `###` per change.** Say what it was, what it is now, and *why*
  — a reader who understands the reason makes the right call in the
  cases the notes didn't foresee.
- **Before → Now tables** whenever there's more than one pair. Column
  headers name the versions (`| Before (rc01) | rc02 |`, `| Was | Now
  |`).
- **Code** for anything that's easier to show than to describe — the
  attribute that restores the old behaviour, the new callback shape.

### New features / New API

- `## New features` — or several `## New features — <area>` sections
  when the release has distinct themes (`— search`, `— theming`,
  `— keyboard`). One `###` per feature, with a short example.
- `## New API` — optional, right after New features: a `| Surface |
  What |` table of new events, methods, exports and types, when listing
  them is clearer than prose.

### Visible changes without a migration

What looks or feels different although no code needs changing: colours,
sizes, spacing, focus rings, timings. Readers compare screenshots; this
section stops them filing it as a regression. Name the old and new
values (`16px (was 12.5px)`).

### Fixes

The fixes a consumer may have hit or worked around, written as the
symptom they saw ("`form.reset()` while deferred was ignored"), not the
internal cause. Long releases group them under `###` (`### Visible
fixes`, `### Data and security`, `### Smaller`). Fixes nobody outside
the repo could observe stay in the CHANGELOG.

### Internal

Optional. Dependency bumps, refactors onto core, new build gates, test
coverage — anything a reader might see in a diff or a lockfile and
wonder about. One short bullet each; "No API or behaviour change" when
that's the point.

---

## Writing rules

- **Engineer to engineer.** Real names in backticks, concrete values,
  old and new side by side. No marketing ("powerful", "seamless").
- **Explain the why.** Every breaking or behaviour change carries one
  sentence of reason. Readers forgive breaking changes they understand.
- **Name the escape hatch.** When a default changes, show the setting
  that restores the old behaviour (`search-behavior="case-insensitive"`
  "keeps 2.5 matching").
- **Self-contained for the baseline.** A reader on the baseline version
  must be able to upgrade with this file alone (plus the earlier notes
  it explicitly links). Don't write "see the CHANGELOG for the renamed
  attributes" — put the table here.
- **Paraphrase, don't paste** the CHANGELOG. The CHANGELOG entry is the
  source of facts; the notes reorganise them by what the reader must do.
- **No internal history.** The reader doesn't care that a fix took
  three attempts across rc01–rc03; for a consolidated final, describe
  the `2.6.0` → `3.0.0` delta only.

---

## README integration

Each `## What's New in vX.Y.Z` section in the README (see
[readme-structure.md](./readme-structure.md) → canonical format) opens
with one line linking its notes, before the bullets:

```markdown
## What's New in v3.0.0-rc02

Upgrade guide: the [3.0.0-rc02 release notes](release-notes/3.0.0-rc02.md); full list: the
[CHANGELOG 3.0.0-rc02 section](CHANGELOG.md).

- **Inputs — strict values (core rc18)** — …
```

After the (at most two) retained What's New sections, one line links
the notes the README no longer shows:

```markdown
Earlier releases: [2.6.0-rc03](release-notes/2.6.0-rc03.md), [2.6.0-rc02](release-notes/2.6.0-rc02.md), [CHANGELOG](CHANGELOG.md).
```

When `/publish` trims a What's New section (Step 4), its notes link
moves to the front of the "Earlier releases" line.

---

## Adopting in an existing repo

Start with the next publish (D-RN-3 = A): write the notes for that
version with the last npm version as baseline, and add `release-notes`
to `files`. Older versions don't need retroactive notes; the CHANGELOG
already covers them. C-RN-1 only checks for gaps from the oldest notes
file onward.
