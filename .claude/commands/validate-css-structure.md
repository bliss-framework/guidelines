---
description: Validate a web-component package against css-structure.checks.md (C-CSS-1 through C-CSS-12).
argument-hint: <path-to-component-package>
allowed-tools: Read, Glob, Grep, Bash
---

You are validating the web-component at `$ARGUMENTS` against the
**css-structure** guideline. Be exhaustive and concrete — file paths and
line numbers, not vague summaries. Read-only: do not edit any files in
the target.

## Step 1 — Load the guidelines (live, every run)

Read these files end-to-end before doing anything else:

1. `C:\Git\BlissFramework\guidelines\web-components\css-structure.md` —
   the canonical file set (Tier-1 + Tier-2), `@layer` cascade
   conventions, BEM rules, section-banner format.
2. `C:\Git\BlissFramework\guidelines\web-components\css-structure.checks.md`
   — the 12 checks C-CSS-1 through C-CSS-12.
3. `C:\Git\BlissFramework\guidelines\web-components\css-structure.decisions.md`
   — to know what decisions the team should have made (canonical vs lean
   strategy at D-CSS-1, @layer choice at D-CSS-3, naming convention at
   D-CSS-4, BEM choice at D-CSS-6, banner threshold at D-CSS-7).
4. `C:\Git\BlissFramework\guidelines\CLAUDE.md` → Non-negotiable
   invariants #7 (`@layer variables, component, overrides;`) and #10 (BEM).

## Step 2 — Locate the component

Use Glob to discover the layout under `$ARGUMENTS`:

- `package.json`, `README.md` at the root.
- CSS source folder — typically `src/css/`. List every `.css` file in it.
- The entry CSS file — usually `main.css` (or the file referenced from
  `package.json`'s `style` / `exports.style` field).

If the README documents a "lean strategy" (D-CSS-1 option B), some checks
(C-CSS-1, C-CSS-4) become N/A. Identify this up front so you don't
spuriously fail the component.

Identify the component's **prefix** from the README / variables.css /
manifest — most BEM checks need it.

### Step 2.5 — Load accepted-deviation registers

Before evaluating any check, look for two files that record deviations
the team has already accepted. Their content downgrades matching
`❌ Fail` verdicts to `⚠️ Exception` (or `✅ Pass` per the note) and
removes the item from the "Recommended actions" section.

- **`README.md` → `## Known limitations`** (consumer-facing).
- **`$ARGUMENTS/VALIDATION-NOTES.md`** (internal-only). One section
  per accepted deviation, headed with the check ID(s):

  ```markdown
  ## C-CSS-7 / C-NC-8 — Consumer-data discriminator classes
  `.holiday`, `.event`, `.badge-{count,number,text}` are not
  component-emitted classes — they're consumer-data values applied
  via `dayClassMember` / `badgeClassMember`. Compound selectors
  (`.drp__day.holiday`) ship default styling for common conventions.
  Backing CSS variables (`--drp-holiday-color`, etc.) are a
  documented public theming surface.
  ```

Discipline: an entry that explains *why the deviation is correct*
downgrades the verdict. An entry that defers ("fix later", "low
priority") stays a Fail. See `/validate-web-component` Step 2.5 for
the full contract.

If neither file exists, proceed at face value.

## Step 3 — Run the auto checks via the script (fast path)

The triad ships a runnable bash script that handles every `[auto]`
check mechanically. Invoke it first:

```bash
bash C:/Git/BlissFramework/guidelines/web-components/css-structure.checks.sh "$ARGUMENTS" <css-prefix>
```

The CSS prefix can be omitted if `component-variables.manifest.json`
declares it. The script runs C-CSS-1, 2, 3, 4, 5, 6, 7, 8, 11 — the
nine `[auto]` checks — and prints PASS / FAIL / SKIP per check.
Capture its output verbatim in your report.

If the script fails to run, fall back to the `.checks.md` prose for
each `[auto]` check.

## Step 4 — Run the semi / manual checks (judgment path)

For the three checks the script doesn't cover (per `css-structure.checks.md`
tier tags):

- **C-CSS-9** `[manual]` (no mixed-bag files): inspect each Tier-3 file
  (or any feature file) and confirm its rules all relate to one
  feature. This is a judgment call — flag any file whose name does not
  describe its actual content.
- **C-CSS-10** `[semi]` (README documents layer contract): Read the
  README, find a Theming or Code-structure section, confirm it covers:
  the layer names, the override contract, how to set `--base-*` and
  `--<prefix>-*`, **and** warns about the unlayered-reset footgun.
- **C-CSS-12** `[semi]` (bundle size sanity): ⚠️ Manual — requires
  running the build. List the command the human should run
  (`npm run build` then `ls -lh dist/*.css`). Don't run the build
  yourself; just instruct.

## Step 5 — Produce the report

Output to the conversation:

```
# CSS-Structure Validation — <component name>

**Target:** `$ARGUMENTS`
**Package:** <name from package.json>
**Prefix:** <wg / ms / drp / wp / ...>
**Strategy:** canonical / lean (per D-CSS-1)
**Result:** N / 12 passing, M manual, K exceptions

## Auto checks (via css-structure.checks.sh)

<paste script output verbatim>

## Semi / manual checks

### C-CSS-9 — No mixed-bag files
**Status:** ✅ / ❌ / ⚠️ Manual
**Evidence:** <files inspected>
**Findings:** <what was found>

### C-CSS-10 — README documents layer contract
...

### C-CSS-12 — Bundle size sanity
...

## Recommended actions (priority order)
1. <concrete file:line edit to fix the highest-impact failure>
2. ...
```

End with a one-line summary the user can scan at a glance.

## Discipline

- Never mark ✅ without actually running the verification.
- A check that's N/A because of a documented decision (lean strategy,
  underscore convention, no-layers strategy) gets N/A with a citation of
  the README section that documents it. Do not silently pass.
- Documented exceptions in `## Known limitations` of the component README
  are ⚠️ Exception (quote the limitation), not failures.
- Prefer Grep over `Bash` + `grep`; prefer Read over `cat`. Prefer Glob
  over `Bash` + `ls`.
- Run independent Grep/Read calls in parallel.
