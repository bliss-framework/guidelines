---
description: Validate a web-component package against base-variables.checks.md (C-BV-1 through C-BV-14).
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
   — the 14 checks C-BV-1 through C-BV-14. Each check has a "What", "How to
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

### Step 2.5 — Load accepted-deviation registers

Before evaluating any check, look for two files that record deviations
the team has already accepted. Their content downgrades matching
`❌ Fail` verdicts to `⚠️ Exception` (or `✅ Pass` per the note) and
removes the item from the "Recommended actions" section.

- **`README.md` → `## Known limitations`** (consumer-facing).
- **`$ARGUMENTS/VALIDATION-NOTES.md`** (internal-only). One section
  per accepted deviation, headed with the check ID(s):

  ```markdown
  ## C-BV-9 — Strategy A signal-override pattern
  The `var(--base-*)` reads in `src/css/dark-mode.css` are variable
  redeclarations inside `:host-context(...)` / `:host(...)`
  selectors — the canonical Strategy A pattern documented in
  `color-scheme.md`. Not feature-rule reads; the auto-script is too
  strict for Strategy A components.
  ```

Discipline: an entry that explains *why the deviation is correct*
downgrades the verdict. An entry that defers ("fix later", "low
priority") stays a Fail. See `/validate-web-component` Step 2.5 for
the full contract.

If neither file exists, proceed at face value.

## Step 3 — Run the auto checks via the script (fast path)

The triad ships a runnable bash script that handles every `[auto]`
check mechanically:

```bash
bash C:/Git/BlissFramework/guidelines/web-components/base-variables.checks.sh "$ARGUMENTS" <css-prefix>
```

The CSS prefix can be omitted if `component-variables.manifest.json`
declares it. The script runs C-BV-1, 2, 3, 5, 6, 9 — the six `[auto]`
checks. Capture its output verbatim.

Notes on script behavior worth knowing when reading its output:

- **C-BV-3** flags only **bare** `var(--<prefix>-X)` reads with no
  definition. Variables consumed with fallback chains
  (`var(--ms-X, var(--ms-Y, ...))`) are deliberate consumer-override
  hooks and exempt — the chain resolves them. This matches the
  rule's intent.
- **C-BV-6** uses `jq` if available, falls back to a regex parse of
  `component-variables.manifest.json` otherwise.
- The script uses `grep -qFx -- "$v"` for variable comparisons, so
  variable names with the leading `--` are handled correctly.

If the script fails to run, fall back to the `.checks.md` prose for
each `[auto]` check.

## Step 4 — Run the semi / manual checks (judgment path)

For the eight checks the script doesn't cover:

- **C-BV-4** `[semi]` (prefix uniqueness) — cross-check the prefix
  against the reservations table in `base-variables.md`. Search across
  KeenMate repos (or note the limit if you can't).
- **C-BV-7** `[semi]` (canonical chain patterns) — inspect the four
  chained variables (dropdown / tooltip / hover / active) in the
  component's `variables.css`. Each must match the canonical chain
  shape verbatim or carry an inline justification comment.
- **C-BV-8** `[manual]` (README documents theming contract) — open
  the component README, confirm a Theming section covering: lists or
  links to the manifest, documents `--<prefix>-rem` and how to
  override, shows at least one example of overriding a `--base-*` and
  a `--<prefix>-*`.
- **C-BV-10, C-BV-11** `[manual]` (standalone render + theme override
  end-to-end) — require a browser. Mark as ⚠️ Manual and explain what
  the human needs to verify. Do **not** mark them ✅ from static
  analysis.
- **C-BV-12** `[semi]` (CHANGELOG entry) — read `CHANGELOG.md`, look
  for an entry describing the variable work. Confirm it's concrete
  (calls out which variables changed semantics), not just "updated
  variables."
- **C-BV-13** `[semi]` (input controls consume `--base-input-size-*-height`)
  — grep the component's CSS for `height:` / `min-height:` declarations.
  For each match, classify the selector: input-like surfaces (editor
  cells, combobox triggers, autocomplete inputs, date inputs, picker
  chips) MUST resolve through `var(--base-input-size-<tier>-height, …)`
  via the `--<prefix>-input-height*` layer. Hardcoded literals on
  input-like rules are ❌. Structural chrome (headers, toolbars,
  scrollbars) is exempt — note the classification in the report.
  The manifest must list every `--base-input-size-*-height` tier the
  component reads (overlap with C-BV-6). Cite the canonical scale in
  `base-variables.md` → "Layout" table.
- **C-BV-14** `[semi]` (tooltip geometry consumes `--base-tooltip-*`
  scale) — grep for tooltip rules (`(tooltip|popover)[^{]*{`). For
  each tooltip rule, walk its properties — `padding`, `font-size`,
  `line-height`, `border-radius`, `max-width`, `box-shadow` — and
  confirm each reads `var(--<prefix>-tooltip-<knob>)` whose chain
  terminates in the matching `--base-tooltip-<knob>`. Hardcoded
  values (`padding: 0.4rem 0.8rem`, `max-width: 200px`, etc.) are
  ❌. The container must declare the `--<prefix>-tooltip-*` layer
  in `variables.css`; the manifest must list every
  `--base-tooltip-*` geometry variable the component reads
  (overlap with C-BV-6). Components with no custom tooltip rules
  (native `title=""` only) are N/A — cite the empty grep result.

If a check's bash snippet uses tools not available on Windows (`jq`,
`diff`), use the Read tool to load the files and reason about them
directly instead of failing the check.

## Step 4 — Canonical-taxonomy alignment

Beyond the 14 checks, produce a deviation report:

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
**Result:** N / 14 passing, M manual, K exceptions

## Auto checks (via base-variables.checks.sh)

<paste script output verbatim>

## Semi / manual checks

### C-BV-4 — Component prefix is unique and reserved
**Status:** ✅ / ❌ / ⚠️ Manual
**Findings:** …

### C-BV-7 — Fallback chains match canonical patterns
…

### C-BV-8 — README documents the contract
…

### C-BV-10 — Standalone render works (browser)
…

### C-BV-11 — Theme override works end-to-end (browser)
…

### C-BV-12 — CHANGELOG entry
…

### C-BV-13 — Input controls consume `--base-input-size-*-height`
…

### C-BV-14 — Tooltip geometry consumes canonical `--base-tooltip-*` scale
…

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
