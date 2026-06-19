---
description: Validate a component package against naming-conventions.checks.md (C-NC-1 through C-NC-12). Works for web-components and Svelte components.
argument-hint: <path-to-component-package>
allowed-tools: Read, Glob, Grep, Bash
---

You are validating the component at `$ARGUMENTS` against the
**naming-conventions** guideline (casing, files, custom-element tags,
HTML attribute mapping, callback hierarchy, `CustomEvent` naming, BEM,
internal handler names, verb application). Be exhaustive and concrete
— file paths and line numbers, not vague summaries. Read-only: do not
edit any files in the target.

## Step 1 — Load the guidelines (live, every run)

Read these files end-to-end before doing anything else:

1. `C:\Git\BlissFramework\guidelines\web-components\naming-conventions.md`
   — casing summary, custom-element tag rules, `CustomEvent` naming,
   HTML attribute ↔ config key mapping, the consumer-callback
   hierarchy (`on*` / `*Callback` / `before*Callback` / `get*Callback`
   / plain `*Callback`), internal `handle*` / `*Handler`, BEM prefix,
   the data-model exception for HTML-shaped booleans.
2. `C:\Git\BlissFramework\guidelines\web-components\naming-conventions.checks.md`
   — the 12 checks C-NC-1 through C-NC-12, with tier tags.
3. `C:\Git\BlissFramework\guidelines\web-components\naming-conventions.decisions.md`
   — D-NC-1 through D-NC-10 (custom-element tag, CSS prefix, Logic
   class, boolean attribute defaults, notification surface, CustomEvent
   names, `*Member` adoption, interceptor adoption, ATTRIBUTE_TABLE,
   TS suffixes).
4. `C:\Git\BlissFramework\guidelines\web-components\base-variables.md`
   → the reserved CSS prefix registry (cross-reference for D-NC-2).

## Step 2 — Detect host and CSS prefix

Use Glob to discover the layout:

- `component-variables.manifest.json` at the root — read it to extract
  the CSS prefix (look for `"prefix": "ms"` or similar).
- TypeScript source folder, types file, Svelte component files.

**Detect host technology** — web-component (`customElements.define` in
TS) or Svelte (`.svelte` files). Several checks (C-NC-1, C-NC-2,
C-NC-7) are web-component-only.

Capture the **CSS prefix** explicitly — the script needs it as a second
argument, and several semi-manual checks need it as input too.

### Step 2.5 — Load accepted-deviation registers

Before evaluating any check, look for two files that record deviations
the team has already accepted. Their content downgrades matching
`❌ Fail` verdicts to `⚠️ Exception` (or `✅ Pass` per the note) and
removes the item from the "Recommended actions" section.

- **`README.md` → `## Known limitations`** (consumer-facing).
- **`$ARGUMENTS/VALIDATION-NOTES.md`** (internal-only). One section
  per accepted deviation, headed with the check ID(s):

  ```markdown
  ## C-NC-8 / C-CSS-7 — Consumer-data discriminator classes
  `.holiday`, `.event`, `.badge-{count,number,text}` are not
  component-emitted classes — they're consumer-data values applied
  via `dayClassMember` / `badgeClassMember`. The component ships
  compound-selector defaults (`.drp__day.holiday`,
  `.drp__badge-cell.badge-count`) as ready-to-use hooks for common
  consumer conventions. The BEM block names the component scope;
  the discriminator names the data convention.
  ```

Discipline: an entry that explains *why the deviation is correct*
downgrades the verdict. An entry that defers ("fix later", "low
priority") stays a Fail. See `/validate-web-component` Step 2.5 for
the full contract.

If neither file exists, proceed at face value.

## Step 3 — Run the auto checks via the script (fast path)

The triad ships a runnable bash script:

```bash
bash C:/Git/BlissFramework/guidelines/web-components/naming-conventions.checks.sh "$ARGUMENTS" <css-prefix>
```

If the CSS prefix is in the manifest, the second argument can be
omitted (the script will auto-discover it). The script runs C-NC-1,
C-NC-2, C-NC-3, C-NC-6, C-NC-8, C-NC-9, C-NC-11 mechanically; exits
0/1/2 per usual; prints PASS / FAIL / SKIP per check. Capture its
output verbatim in your report.

Notes on script behavior worth knowing when reading its output:

- **C-NC-3** uses an awk-based interface context tracker — boolean
  fields inside `*Option`, `*Node`, `*Item`, `*Row`, `*Entry`,
  `*Record`, `*Model`, `*Result` interfaces are exempt (data-model
  HTML-convention exception). This matches the rule's stated
  exception.
- **C-NC-8** strips block comments, `url(...)`, string literals, and
  `:host-context(...)` / `:host([...])` selector arguments before
  scanning for class names. Don't try to second-guess the script's
  view of "emitted classes."

If the script fails to run, fall back to the `.checks.md` prose for
every `[auto]` check. Do not skip them.

## Step 4 — Run the semi / manual checks (judgment path)

For every check the script skipped (or that's tagged `[semi]` /
`[manual]` in `naming-conventions.checks.md`), execute the "How to
verify" prose:

- **C-NC-4** `[semi]` (notification callbacks match host shape) —
  knowing the host (Step 2) is the prelude. Then:
  - Web-component: confirm every void-returning Config field ends in
    `*Callback`. Confirm every notification `CustomEvent` dispatched
    in TS code is documented in the manifest / README as an event
    the consumer can subscribe to.
  - Svelte: confirm every void-returning prop on the top-level
    `.svelte` component starts with `on*` (`onNodeClick`,
    `onSelectionChange`, …). Confirm no notification prop uses
    `*Callback`.
- **C-NC-5** `[semi]` (interceptors use `before*Callback`) — Grep
  for fields whose function-type return allows cancellation
  (`boolean | void`, `boolean | object | void`, `false | …`). For
  each match, confirm the name starts with `before` and ends with
  `Callback`. Fields with cancellation-shaped returns named
  differently (`validate*`, `check*`, `on*`, plain verb) are
  failures.
- **C-NC-7** `[semi]` (ATTRIBUTE_TABLE single source of truth, web-
  components only) — Read the Element file (`web-component.ts`).
  Confirm:
  - An `ATTRIBUTE_TABLE` (or equivalent named constant) exists.
  - `observedAttributes` is computed from it (e.g.,
    `ATTRIBUTE_TABLE.map(spec => spec.attr)`), not a hand-written
    parallel list.
  - Initial parsing in the constructor iterates the same table.
  - `attributeChangedCallback` iterates the same table.
  If any of those four uses an independent string list, fail and
  note which is drifting.
- **C-NC-10** `[manual]` (validate* vs check* used per semantics) —
  for each `validate*` and `check*` method/function found, read the
  body and judge:
  - `validate*` should throw / return Result / return errors[]. It's
    gating input from outside the trust boundary.
  - `check*` should return a boolean or detail object, no mutation,
    no throw.
  Flag any function whose name doesn't match its semantics.
- **C-NC-12** `[semi]` (no magic strings inline) — Grep for repeated
  literal strings that look like public identifiers (event names,
  attribute names, log categories). Three or more identical inline
  occurrences of `'select'`, `'multiple'`, `'show-checkboxes'`, etc.,
  is a fail — the third use should come from a constants table.
  Small literals (`'true'`, `'false'`, debug-only strings) are
  exempt.

## Step 5 — Produce the report

Output to the conversation:

```
# Naming-Conventions Validation — <component name>

**Target:** `$ARGUMENTS`
**Package:** <name from package.json>
**Component type:** web-component / Svelte
**CSS prefix:** <ms / wg / stv / wtv / ...>
**Tag:** <web-multiselect / N/A for Svelte>
**Result:** N / 12 passing, M judgment / exceptions

## Auto checks (via naming-conventions.checks.sh)

<paste script output verbatim>

## Semi / manual checks

### C-NC-4 — Notification callbacks match host shape
**Status:** ✅ / ❌ / ⚠️ Manual
**Evidence:** <files inspected>
**Findings:** <what was found>

### C-NC-5 — Interceptors use before*Callback
...

### C-NC-7 — ATTRIBUTE_TABLE single source of truth (web-component only)
...

### C-NC-10 — validate* vs check* per semantics
...

### C-NC-12 — No magic strings inline
...

## Recommended actions (priority order)
1. <concrete file:line edit to fix the highest-impact failure>
2. ...
```

End with a one-line summary the user can scan at a glance.

## Discipline

- Never mark ✅ without running the script (for autos) or executing
  the "How to verify" prose (for semis / manuals).
- A check that's N/A because of host type (C-NC-1 / C-NC-2 / C-NC-7
  are web-component-only) gets N/A.
- Documented exceptions in `## Known limitations` of the component
  README are ⚠️ Exception (quote the limitation), not failures.
- The data-model boolean exemption is built into the script and the
  rule — don't double-flag bare `disabled` / `selected` / `checked`
  on `*Option` / `*Node` / `*Item` interfaces.
- Prefer Grep over `Bash` + `grep`; prefer Read over `cat`. Prefer
  Glob over `Bash` + `ls`.
- Run independent Grep / Read calls in parallel.
