---
description: Validate a web-component package against base-variables.checks.md (C-BV-1 through C-BV-12).
argument-hint: <path-to-component-package>
allowed-tools: Read, Glob, Grep, Bash
---

You are validating the web-component at `$ARGUMENTS` against the
**base-variables** guideline. Be exhaustive and concrete — file paths and
line numbers, not vague summaries. Read-only: do not edit any files in the
target.

## Step 1 — Load the guidelines (live, every run)

Read these files end-to-end before doing anything else:

1. `C:\Git\BlissFramework\guidelines\web-components\base-variables.md` —
   rationale + the **canonical `--base-*` taxonomy table** (the source of
   truth for which `--base-*` variables exist, and what their typical
   fallbacks are).
2. `C:\Git\BlissFramework\guidelines\web-components\base-variables.checks.md`
   — the 12 checks C-BV-1 through C-BV-12. Each check has a "What", "How to
   verify", and "Failure mode" section.
3. `C:\Git\BlissFramework\guidelines\CLAUDE.md` → the **Non-negotiable
   invariants** section (cross-references most of these checks).

Extract:

- The canonical `--base-*` set (from base-variables.md → "The canonical
  `--base-*` set" tables). Keep this list in mind for the deviation report
  in Step 4.
- The reserved component prefixes table — to verify the target's prefix
  matches one of the reservations (or is a justified new one).
- The four canonical chain patterns (dropdown / tooltip / hover / active).

## Step 2 — Locate the component

The argument `$ARGUMENTS` is the path to a component package. Use Glob/Read
to find:

- `package.json` at the root → confirm the component name and exports.
- CSS source folder — typically `src/css/` but may differ. Use
  `Glob: <path>/**/*.css` to discover the actual layout.
- `component-variables.manifest.json` at the package root.
- `README.md` at the package root.

If the layout is unfamiliar (no `src/css/`, no manifest), report what you
found and continue with best-effort path mapping. Do not abort — many checks
can still run.

## Step 3 — Run every check (C-BV-1 through C-BV-12)

For each check, execute the "How to verify" steps from
`base-variables.checks.md` **adapted to this component's actual paths** (the
snippets in the guideline use placeholder paths like `src/css/` and
`<prefix>` — replace with what you found in Step 2).

Notes per check:

- **C-BV-1** (no color literals in feature files): use the dedicated Grep
  tool with a regex on `(background|color|border|box-shadow|fill|stroke):\s*(#[0-9a-f]|rgb)`,
  excluding the variables and dark-mode files. Inspect each match — false
  positives include `:host` blocks and comments.
- **C-BV-2** (every `var(--base-*)` read has a fallback): regex
  `var\(--base-[a-z-]+\)` without a comma. **Only flag `--base-*`
  reads**, never `--<prefix>-*` reads — the two-layer pattern
  guarantees `--<prefix>-*` is always defined on the container with its
  own chain, so a bare `var(--wp-control-bg)` at the call site is
  correct, not a violation. See base-variables.md → "Fallbacks live at
  the definition site, not at every read".
- **C-BV-3** (`:host` declares every consumed `--<prefix>-*`): build two
  sets — variables consumed in any rule vs. variables defined on `:host` or
  `:host(...)`. The consumed set must be a subset of the defined set.
- **C-BV-4** (prefix is reserved): cross-check the component's prefix
  against the reservations table in base-variables.md.
- **C-BV-5** + **C-BV-6** (manifest exists & matches code): read the
  manifest, compare `baseVariables[].name` to actual `--base-*` reads in
  CSS, compare `componentVariables[].name` to actual `:host` definitions.
  Cross-check `package.json` `exports."./manifest"`.
- **C-BV-7** (canonical chain patterns): inspect the four chained
  variables in the component's variables.css. Each must match the
  documented chain verbatim or carry an inline justification comment.
- **C-BV-8** (README documents theming contract): open the component
  README, confirm a Theming section covering the three required points.
- **C-BV-9** (no `--base-*` reads outside `:host` blocks / variables.css):
  Grep for `var(--base-` outside the variables file.
- **C-BV-10, C-BV-11** (standalone render + theme override end-to-end):
  these require a browser. Mark as ⚠️ **Manual** and explain what the
  human needs to verify. Do **not** mark them ✅ from static analysis.
- **C-BV-12** (CHANGELOG entry): read `CHANGELOG.md`, look for an entry
  describing the variable work.

If a check's bash snippet uses tools not available on Windows (`jq`,
`diff`), use the Read tool to load the files and reason about them directly
instead of failing the check.

## Step 4 — Canonical-taxonomy alignment

Beyond the 12 checks, produce a deviation report:

- Enumerate every `--base-*` the component consumes (from its CSS).
- For each, mark whether it appears in the canonical taxonomy table in
  base-variables.md.
- Non-canonical reads are not automatic failures — they may indicate a new
  variable that needs to be added to the taxonomy, or a typo. Flag them
  for human review.
- Also report `--base-*` variables in the canonical set that the component
  does *not* read (informational, not a failure).

## Step 5 — Produce the report

Output to the conversation (no file writes) a markdown report:

```
# Base-Variables Validation — <component name>

**Target:** `$ARGUMENTS`
**Package:** <name from package.json>
**Prefix:** <wg / ms / drp / wp / ...>
**Result:** N / 12 passing, M manual, K exceptions

## Check results

### C-BV-1 — every visible color resolves through a variable
**Status:** ✅ / ❌ / ⚠️ Manual / ⚠️ Exception
**Evidence:** <commands run, files inspected>
**Findings:**
- <file:line> — <what was found>
[...]

[repeat for all 12]

## Canonical taxonomy alignment

### `--base-*` consumed by this component
| Variable | In canonical taxonomy? | Used in (file:line) |
|----------|------------------------|---------------------|
| ...      | ✅ / ⚠️ deviation       | ...                 |

### Canonical `--base-*` NOT consumed (informational)
- <list>

## Recommended actions (priority order)
1. <concrete file:line edit to fix the highest-impact failure>
2. ...
```

End with a one-line summary the user can scan at a glance.

## Discipline

- Do not mark a check ✅ unless you actually ran the verification.
- A check that can't run (missing file, can't access tool) is ❌ with the
  reason, not silently skipped.
- A check the human must verify in a browser is ⚠️ Manual with explicit
  instructions for what to look at.
- If the component README's "Known limitations" documents an exception
  for a check, mark it ⚠️ Exception and quote the limitation.
- Prefer the Grep tool over `Bash` + `grep`; prefer Read over `cat`.
- Run independent Grep/Read calls in parallel when scanning the codebase.
