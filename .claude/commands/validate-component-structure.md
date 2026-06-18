---
description: Validate a component package against component-structure.checks.md (C-CST-1 through C-CST-11). Works for web-components and Svelte components.
argument-hint: <path-to-component-package>
allowed-tools: Read, Glob, Grep, Bash
---

You are validating the component at `$ARGUMENTS` against the
**component-structure** guideline (internal architecture: layers, file
organization, class suffixes, TypeScript interface suffixes). Be
exhaustive and concrete — file paths and line numbers, not vague
summaries. Read-only: do not edit any files in the target.

## Step 1 — Load the guidelines (live, every run)

Read these files end-to-end before doing anything else:

1. `C:\Git\BlissFramework\guidelines\web-components\component-structure.md`
   — the four layers (Element / Logic / Service / Side), folder layout,
   class naming, TS interface suffixes, anti-patterns.
2. `C:\Git\BlissFramework\guidelines\web-components\component-structure.checks.md`
   — the 11 checks C-CST-1 through C-CST-11, with tier tags.
3. `C:\Git\BlissFramework\guidelines\web-components\component-structure.decisions.md`
   — D-CST-1 through D-CST-9 (host technology, Logic class name,
   Element class, Service classes, Side-layer files, Manager layer,
   TS interface suffix policy, premature interfaces, framework-runtime
   imports).
4. `C:\Git\BlissFramework\guidelines\CLAUDE.md` → Non-negotiable
   invariants (especially #4 on bare vs conditional `color-scheme`,
   though that's covered by other triads).

## Step 2 — Detect the component shape

Use Glob to discover the layout under `$ARGUMENTS`:

- `package.json`, `README.md`, `CHANGELOG.md` at the root.
- `component-variables.manifest.json` at the root (for the prefix).
- TypeScript source folder — typically `src/` (web-component) or
  `src/lib/` (Svelte).

**Detect host technology** — web-component (`customElements.define`
call in `src/**/*.ts`) or Svelte (`.svelte` files under
`src/lib/components/`). This gates C-CST-1, C-CST-2 (web-component
only), and D-CST-9 = B exception for Logic-class Svelte rune imports.

Identify the **Logic class file** (typically the package's last name
segment — `multiselect.ts`, `grid.ts`, or `TreeController.svelte.ts`)
and the **Element file** (`web-component.ts` for web-components;
top-level `.svelte` for Svelte).

If the layout is unfamiliar, report what you found and proceed with
best-effort path mapping. Do not abort — most checks can still run.

### Step 2.5 — Load accepted-deviation registers

Before evaluating any check, look for two files that record deviations
the team has already accepted. Their content downgrades matching
`❌ Fail` verdicts to `⚠️ Exception` (or `✅ Pass` per the note) and
removes the item from the "Recommended actions" section.

- **`README.md` → `## Known limitations`** (consumer-facing).
- **`$ARGUMENTS/VALIDATION-NOTES.md`** (internal-only). One section
  per accepted deviation, headed with the check ID(s):

  ```markdown
  ## C-CST-4 / C-CST-10 — Logic-class module split
  `<Logic>` is split across `<feature>.ts` + N namespace-style
  collaborators (`<feature>-{validation,rendering,...}.ts`) imported
  via `import * as Foo`. Not independent Service classes — one
  Logic class organized across files. The main class delegates
  through wrapper methods.
  ```

Discipline: an entry that explains *why the deviation is correct*
downgrades the verdict. An entry that defers ("fix later", "low
priority") stays a Fail. See `/validate-web-component` Step 2.5 for
the full contract.

If neither file exists, proceed at face value.

## Step 3 — Run the auto checks via the script (fast path)

The triad ships a runnable bash script that handles every `[auto]`
check mechanically. Invoke it first to knock out the deterministic
half:

```bash
bash C:/Git/BlissFramework/guidelines/web-components/component-structure.checks.sh "$ARGUMENTS"
```

The script auto-detects web-component vs Svelte, runs C-CST-1, C-CST-2,
C-CST-3, C-CST-4, C-CST-5, C-CST-8, C-CST-11, prints PASS / FAIL / SKIP
per check, and exits 0 if all pass / 1 if any fail / 2 on bad usage.
Capture its output verbatim in your report.

If the script fails to run (target not found, malformed structure),
fall back to running each `[auto]` check manually per the
`.checks.md` prose. Do not skip the auto checks just because the
script didn't run — the rule still applies.

## Step 4 — Run the semi / manual checks (judgment path)

For every check the script skipped (or that's tagged `[semi]` /
`[manual]` in `component-structure.checks.md`), execute the "How to
verify" prose:

- **C-CST-6** `[manual]` (Element layer holds no business state) —
  Read the Element class file. Confirm it declares only the
  Logic-class reference and lifecycle fields (AbortController,
  MutationObserver). Flag any domain state (`selectedValues`,
  `filteredOptions`, `isOpen`) on the Element class as a violation.
  Svelte bindable props are OK.
- **C-CST-7** `[semi]` (no premature Manager) — Grep `class \w+Manager`.
  If found, check whether D-CST-6 = B was justified in the PR
  description / README. Single-Logic-class Manager is a fail.
- **C-CST-9** `[manual]` (no premature interfaces) — for every
  `export interface I*` or other internal-abstraction interface,
  count the implementations. Two or more → pass. One implementation
  → fail (premature abstraction). Public-contract interfaces
  (`<Feature>Config`) are exempt.
- **C-CST-10** `[semi]` (folder layout matches convention) — `ls` the
  `src/` (or `src/lib/`) folder, compare to the canonical layout in
  `component-structure.md`. Deviations need a one-line note in the
  README's "Code structure" section. Confirm the note exists if any
  deviation is found.

## Step 5 — Produce the report

Output to the conversation:

```
# Component-Structure Validation — <component name>

**Target:** `$ARGUMENTS`
**Package:** <name from package.json>
**Component type:** web-component / Svelte
**Logic class:** <WebMultiSelect / TreeController / ...>
**Element file:** <src/web-component.ts / Tree.svelte / ...>
**Result:** N / 11 passing, M judgment / exceptions

## Auto checks (via component-structure.checks.sh)

<paste script output verbatim>

## Semi / manual checks

### C-CST-6 — Element layer holds no business state
**Status:** ✅ / ❌ / ⚠️ Manual
**Evidence:** <files inspected>
**Findings:** <what was found>

### C-CST-7 — No premature Manager
...

### C-CST-9 — No premature interfaces
...

### C-CST-10 — Folder layout matches convention
...

## Recommended actions (priority order)
1. <concrete file:line edit to fix the highest-impact failure>
2. ...
```

End with a one-line summary the user can scan at a glance:
"N pass, M fail, K manual / exception — see above."

## Discipline

- Never mark ✅ without running the script (for autos) or executing
  the "How to verify" prose (for semis / manuals).
- A check that's N/A because of a documented decision (D-CST-1 = B
  Svelte exempts C-CST-1, C-CST-2; D-CST-9 = B allows Svelte-rune
  language extensions; etc.) gets N/A with a citation of the
  decision.
- Documented exceptions in `## Known limitations` of the component
  README are ⚠️ Exception (quote the limitation), not failures.
- Prefer Grep over `Bash` + `grep`; prefer Read over `cat`. Prefer
  Glob over `Bash` + `ls`.
- Run independent Grep / Read calls in parallel.
