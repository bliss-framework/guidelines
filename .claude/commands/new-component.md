---
description: Interactive intake for a new component. Asks technology, package identity, and CSS prefix; verifies npm availability; outputs a summary block.
argument-hint: [optional component-name hint]
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
---

You are running the **new-component intake** for the user. The argument
`$ARGUMENTS` (if present) is a free-form hint at the component name —
treat it as a starting point, not authoritative. The intake produces a
summary block; it does **not** scaffold files or create the new repo.
Scaffolding happens separately.

## Step 0 — Load the rules (live)

Read these end-to-end before asking the first question:

1. `C:\Git\BlissFramework\guidelines\web-components\component-intake.md`
   — the canonical intake rules. The questions below mirror this file;
   if it diverges, trust the file.
2. `C:\Git\BlissFramework\guidelines\web-components\base-variables.md`
   — the **authoritative** prefix reservation table. You will
   cross-check the derived prefix against it.
3. `C:\Git\BlissFramework\guidelines\web-components\theme-container.md`
   → just the "container by component type" table — so you can show
   the consequences of the technology choice.

## Step 1 — Ask the three intake questions

Use the `AskUserQuestion` tool. Ask in a single call where possible so
the user sees all three decisions up front. If a downstream question
depends on an earlier answer (e.g. project-name default depends on
technology), split the call.

### Q1 — Technology

Options (label / description):

- **Vanilla web component** — `HTMLElement` + `attachShadow`. Container
  is `:host`. Default for cross-framework primitives.
- **Lit-based web component** — Same container as vanilla; pick when
  template/state complexity warrants Lit's reactivity.
- **Svelte component** — Light DOM, container `.<prefix>-container`.
  Pick for Svelte/SvelteKit-internal components.

### Q2 — Project name + owner

Default owner: `@keenmate`. Pre-fill the project name as
`web-<hint>` or `svelte-<hint>` based on Q1's answer and the
`$ARGUMENTS` hint, but let the user override.

Ask as two sub-questions if the AskUserQuestion structure makes that
cleaner; otherwise present a single confirmation with the assembled
default package name and an "Other" escape hatch.

Encourage kebab-case, no leading articles, singular form.

### Q3 — CSS prefix (derived + confirmed)

**Derive first, then ask the user to confirm or override.** Apply the
algorithm from `component-intake.md`:

1. Strip `web-` / `svelte-` from the project name.
2. Count the English words in the remainder. If unclear (e.g.
   `datepicker`, `treeview`, `tabset`), **ask the user before counting** —
   wrong count produces a wrong prefix.
3. If multi-word: prefix = initials of each word. Lowercase.
4. If single-word: prefix = first letter of tech (`w` / `s`) + first
   letter of the component name. Lowercase.
5. If the derived prefix is already reserved (cross-check against the
   table in `base-variables.md`), show the collision and ask the user
   to pick an alternative.
6. If the derived prefix is a single letter, fail and ask the user to
   provide a 2–4 letter mnemonic — the algorithm shouldn't produce
   one-letter results from valid inputs, so this means the input is
   degenerate.

Present the derived prefix to the user with one-sentence reasoning
("`drp` from initials of date-range-picker"), then ask: accept /
override.

## Step 2 — Cross-check the prefix against existing reservations

Read the prefix table inside
`C:\Git\BlissFramework\guidelines\web-components\base-variables.md`
(section "Component prefix convention") AND the matching table in
`component-intake.md`. If the derived/chosen prefix appears in
either, flag the collision before continuing and loop back to Q3.

## Step 3 — Verify npm availability

Run:

```bash
npm view <package-name>
```

Interpret:

- Exit 0 with metadata → the name is **taken**. Show the version and
  publish date, then loop back to Q2 to pick a new name.
- Exit 1 / "code E404" → the name is **available**. Proceed.
- Network error / other → report it; ask the user whether to retry,
  skip the check, or abort. Don't silently proceed.

If `npm` is not on the PATH, mention it once and ask whether to skip
the check (with a note that the user should run it manually).

## Step 4 — Produce the intake summary

Output to the conversation (no file writes) a markdown block the user
can paste into the new repo's README and CHANGELOG:

```markdown
## Component metadata

- **Technology:** <vanilla / Lit / Svelte>
- **Package:** @<owner>/<project-name>
- **CSS prefix:** <prefix>
- **Container selector:** :host  (or .<prefix>-container)
- **npm availability checked:** <YYYY-MM-DD> — <available / taken @ vX.Y.Z>
- **Reserved in guidelines repo:** TODO — add row to
  `web-components/base-variables.md` "Component prefix convention" and
  `web-components/component-intake.md` "Existing reservations".
```

Follow it with a **next-steps** list:

```
Next:
1. Add the prefix row to both tables in the guidelines repo (PR).
2. Reserve @<owner>/<project-name> on npm (publish a 0.0.0 placeholder
   or claim through the org's dashboard).
3. Read the brand-new-component order:
   css-structure.md → theme-container.md → base-variables.md →
   color-scheme.md → example-web-player.md
4. Scaffold the package: src/css/{main,variables,base,...}.css per
   css-structure.md, container per theme-container.md, manifest per
   base-variables.md.
```

End with a single-sentence verdict reminding the user that this intake
does **not** create the new repo or modify the guidelines — the prefix
table updates and the npm reservation are explicit follow-up steps.

## Discipline

- Never assume an answer. Every choice goes through AskUserQuestion or
  is derived from a previously-confirmed answer.
- Never claim a prefix as available without grepping both reservation
  tables.
- Never claim a package name as available without running `npm view`.
- Never write files in the guidelines repo or anywhere else from this
  command — only output the summary.
- If the user types `/new-component` with no arguments, ask for the
  component name as the very first question (before technology, since
  the project-name default depends on the chosen tech).
- When showing options, list the recommended option first labeled
  `(Recommended)` only if there's a clear default; otherwise present
  them neutrally.
