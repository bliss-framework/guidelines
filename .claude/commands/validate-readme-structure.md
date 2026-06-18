---
description: Validate a component package against readme-structure.checks.md (C-RS-1 through C-RS-15). Verifies the slim README + docs/ split + BlissFramework attribution + canonical About paragraph.
argument-hint: <path-to-component-package>
allowed-tools: Read, Glob, Grep, Bash
---

You are validating the component at `$ARGUMENTS` against the
**readme-structure** guideline. Be exhaustive and concrete — file
paths and line numbers, not vague summaries. Read-only: do not edit
any files in the target.

## Step 1 — Load the guidelines (live, every run)

Read these files end-to-end before doing anything else:

1. `C:\Git\BlissFramework\guidelines\web-components\readme-structure.md`
   — rationale, the canonical layout (`docs/` subfolder), per-file
   content guidelines, the 400-line README cap, the worked example.
2. `C:\Git\BlissFramework\guidelines\web-components\readme-structure.checks.md`
   — the 15 checks C-RS-1 through C-RS-15, with tier tags.
3. `C:\Git\BlissFramework\guidelines\web-components\readme-structure.decisions.md`
   — to know which decisions the team should have made (especially
   D-RS-1 demo location, D-RS-2 accessibility applicability,
   D-RS-3 examples format).

## Step 2 — Locate the component

Use Glob to discover the layout under `$ARGUMENTS`:

- `package.json`, `README.md`, `CHANGELOG.md`, `LICENSE` at the root.
- `docs/` folder — expect `usage.md`, `theming.md`, `examples.md`,
  and (per D-RS-2) `accessibility.md`.
- Read `package.json` for the package name and version.

If `docs/` is missing entirely, that's the most likely state for a
component that hasn't yet migrated — flag C-RS-3 ❌ and continue
running the other checks against whatever exists.

### Step 2.5 — Load accepted-deviation registers

Before evaluating any check, look for two files that record deviations
the team has already accepted. Their content downgrades matching
`❌ Fail` verdicts to `⚠️ Exception` (or `✅ Pass` per the note) and
removes the item from the "Recommended actions" section.

- **`README.md` → `## Known limitations`** (consumer-facing).
- **`$ARGUMENTS/VALIDATION-NOTES.md`** (internal-only). One section
  per accepted deviation, headed with the check ID(s):

  ```markdown
  ## C-RS-8 — D-RS-1 = D (no deployed demo)
  Internal-only package, never published to a public registry.
  No deployed-demo link is needed.
  ```

Discipline: an entry that explains *why the deviation is correct*
downgrades the verdict. An entry that defers ("fix later", "low
priority", "migration in progress") stays a Fail — the
readme-structure migration is itself the fix queue and shouldn't
be silenced by a deferral note. See `/validate-web-component`
Step 2.5 for the full contract.

If neither file exists, proceed at face value.

## Step 3 — Run the auto checks via the script (fast path)

The triad ships a runnable bash script:

```bash
bash C:/Git/BlissFramework/guidelines/web-components/readme-structure.checks.sh "$ARGUMENTS"
```

The script runs C-RS-1, 2, 3, 4, 5, 14, 15 — the seven `[auto]` checks.
Capture its output verbatim.

If the script fails to run, fall back to the `.checks.md` prose for
each `[auto]` check.

## Step 4 — Run the semi / manual checks (judgment path)

For the eight checks the script doesn't cover:

- **C-RS-6** `[semi]` (README "What is it" is tight) — Read the
  intro section. Count paragraphs and lines. Confirm ≤ 30 lines,
  1–3 paragraphs, focused on value/audience.
- **C-RS-7** `[semi]` (README "What's new" links CHANGELOG) — Grep
  README for `What's new` heading and a relative link to
  `CHANGELOG.md`. If D-RS-5 = C (no "What's new" section), confirm
  `CHANGELOG.md` is linked from "Demos & docs" instead.
- **C-RS-8** `[semi]` (deployed demo link works) — Find the demo
  URL in the README. Confirm it's not a placeholder. The agent
  shouldn't fetch the URL itself — mark ⚠️ Manual with the URL for
  the human to verify. If D-RS-1 = D (no deployed demo) → N/A.
- **C-RS-9** `[manual]` (quick-start snippet actually runs) —
  Always ⚠️ Manual. Give the exact steps: clean folder, run the
  install command from the README, paste the quick-start snippet,
  open in a browser.
- **C-RS-10** `[semi]` (`docs/usage.md` covers the public surface)
  — Read `docs/usage.md`. Cross-reference against
  `ATTRIBUTE_TABLE` / `customElements.define` / `dispatchEvent`
  call sites in the source. Flag missing entries.
- **C-RS-11** `[semi]` (`docs/theming.md` covers the four
  contracts) — Read `docs/theming.md`. Confirm sections for
  container, variables, color-scheme, cascade-layer. Cross-
  reference with C-TC-11 / C-BV-8 / C-CS-8 / C-CSS-10 from the
  other triads' validators.
- **C-RS-12** `[semi]` (`docs/examples.md` has at least one worked
  example beyond the README quick start) — Read the file. Confirm
  ≥ 1 distinct example.
- **C-RS-13** `[semi]` (`docs/accessibility.md` covers keyboard +
  ARIA + focus) — Read the file. Confirm sections for keyboard
  navigation, ARIA, focus management. If D-RS-2 = B (display-only)
  → N/A; confirm the README has an "Accessibility notes"
  paragraph instead.

If a check's bash snippet uses tools not available on Windows
(`wc`, `curl`), use the Read tool to load the relevant file and
reason about it directly.

## Step 5 — Produce the report

Output to the conversation:

```
# Readme-Structure Validation — <component name>

**Target:** `$ARGUMENTS`
**Package:** <name from package.json>
**Result:** N / 15 passing, M manual, K exceptions

## Auto checks (via readme-structure.checks.sh)

<paste script output verbatim>

## Semi / manual checks

### C-RS-6 — README "What is it" is tight
**Status:** ✅ / ❌ / ⚠️ Manual / ⚠️ Exception / N/A
**Evidence:** <file:line range>
**Findings:** …

### C-RS-7 — README "What's new" links CHANGELOG
…

### C-RS-8 — Deployed demo link
…

### C-RS-9 — Quick-start snippet runs
**Status:** ⚠️ Manual
**Steps:** 1. <clean folder setup>, 2. <install command>, 3. <paste snippet>, 4. <open in browser>

### C-RS-10 — docs/usage.md covers the public surface
…

### C-RS-11 — docs/theming.md covers the four contracts
…

### C-RS-12 — docs/examples.md has at least one worked example
…

### C-RS-13 — docs/accessibility.md covers keyboard + ARIA + focus
…

## Recommended actions (priority order)
1. <concrete file:line edit to fix the highest-impact failure>
2. ...
```

End with a one-line verdict ("X failures, Y manual checks pending").

## Discipline

- Never mark ✅ without actually running the verification.
- The deployed-demo HTTP check (C-RS-8) is ⚠️ Manual unless you have
  a `curl` / `WebFetch` allow.
- A documented N/A per a decision (D-RS-1 = D, D-RS-2 = B, D-RS-5 = C)
  is N/A with citation, not a failure.
- Prefer Grep over `Bash` + `grep`; prefer Read over `cat`.
- Run independent Grep/Read calls in parallel — many checks inspect
  the same handful of files.
