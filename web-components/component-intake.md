# Component Intake — Guideline

Pre-flight rules for **starting a new component** in the KeenMate /
Bliss ecosystem. Three decisions land before any code is written:
which technology, which package identity, which CSS prefix.

This doc is the source of truth that
[`/new-component`](../.claude/commands/new-component.md) reads at
runtime — keep them in sync.

For an existing component, this doc doesn't apply: read
[css-structure.md](./css-structure.md) →
[theme-container.md](./theme-container.md) →
[base-variables.md](./base-variables.md) →
[color-scheme.md](./color-scheme.md) for the build itself.

---

## TL;DR

> **Three intake answers before code: (1) technology — vanilla web
> component, Lit, or Svelte; (2) package identity —
> `@<owner>/<tech-prefix>-<name>`, verified available on npm; (3) CSS
> prefix — derived from the component name by a fixed algorithm,
> cross-checked against the reservation table.**

---

## A — Technology

Pick one. The choice determines the container scope (per
[theme-container.md](./theme-container.md)) and the rest of the build
pipeline.

| Option | Container | When to pick |
|--------|-----------|--------------|
| **Vanilla web component** (`HTMLElement` + `attachShadow`) | `:host` | Cross-framework primitive consumed by HTML pages, React, Vue, Svelte, etc. No runtime dependency. Default for low-level UI. |
| **Lit-based web component** | `:host` | Same use case as vanilla but the templating gets unwieldy (lots of state, reactive bindings, slotted children). Lit is a thin wrapper around `HTMLElement` — same container rules, same theming. |
| **Svelte component** | `.<prefix>-container` | Component is consumed primarily inside SvelteKit / Svelte apps. Light DOM, no shadow boundary. Theming follows the Svelte branch of [theme-container.md](./theme-container.md). |

**Don't mix.** A Svelte component that also defines a custom element is
two components; build them as two packages. The intake is per package.

**Future:** React, Vue, Blazor, LiveView are not currently in the
suite. If we add them, this table grows; the rest of the guideline
shape stays the same.

---

## B — Package identity

### Naming

Project name follows `<tech-prefix>-<component-name>` where:

- `<tech-prefix>` is `web` for vanilla/Lit web components, `svelte`
  for Svelte components.
- `<component-name>` is kebab-case and describes what the component
  *does*, not how it looks.

Examples in the wild:

```
web-grid              web-multiselect    web-daterangepicker    web-player
svelte-treeview       svelte-switch
```

If unsure between `web-foo` and `web-foos`, prefer the singular —
short, scans cleanly in imports.

### Package name

```
@<owner>/<project-name>
```

**Default owner: `@keenmate`** — every existing component uses this.
Override only if there's a deliberate org separation; ask the team
first.

### npm availability check

Before reserving the name, confirm it's free:

```bash
npm view @keenmate/<project-name>
```

- **Returns metadata** → the name is taken. Pick a different one.
- **Returns `npm error 404`** → the name is available. Reserve by
  publishing a `0.0.0` placeholder or by adding the entry to the
  prefix table in [base-variables.md](./base-variables.md) so it can't
  be claimed twice internally.

(The intake slash command runs this check automatically.)

---

## C — CSS prefix derivation

Every component owns a short CSS prefix (`wg`, `ms`, `drp`, …) used
throughout its `--<prefix>-*` variables, BEM class names, and the
`.<prefix>-container` selector for Svelte components.

The prefix is **derived from the component name** by a fixed rule, so
there's no bikeshedding. The team can override the derivation in rare
cases (e.g. the existing `ltree` for `svelte-treeview`) — that's an
exception, not the pattern.

### The algorithm

Strip the `web-` / `svelte-` tech prefix. Look at what remains.

1. **Multiple logical words** (counted by English meaning, not by
   hyphens — `daterangepicker` is three words even though kebab-case
   would write it as one):

   → prefix = initials of each word, lowercased.

   ```
   daterangepicker  → d + r + p = drp
   multiselect      → m + s     = ms
   ```

2. **Single logical word** (`player`, `grid`, `switch`):

   → prefix = first letter of the tech (`w` for web, `s` for svelte)
   + first letter of the component name.

   ```
   web-player   → w + p = wp
   web-grid     → w + g = wg
   svelte-player→ s + p = sp
   svelte-switch→ s + s = ss   ← collision warning, see below
   ```

### Tie-breakers

The algorithm produces a unique prefix in most cases, but watch for:

- **Collision with an existing reservation** — see the table in
  [base-variables.md](./base-variables.md) → "Component prefix
  convention". If the derived prefix is taken, append one more letter
  or pick a different mnemonic (e.g. `svelte-switch` → `sw` instead of
  `ss`, both because `ss` reads badly and to leave room).
- **Ambiguous word count** — is "datepicker" one word or two? Is
  "treeview" one or two? Ask before deciding; the intake command does.
  When in doubt, pick the choice that yields a more mnemonic prefix
  (`tv` for treeview reads cleanly; `t` does not).
- **The result must be 2–4 lowercase letters**, mnemonic, and
  greppable. Reject single-letter prefixes outright; they collide
  with everything.

### Existing reservations (do not reuse)

Authoritative list lives in [base-variables.md](./base-variables.md).
Current snapshot:

| Component | Prefix |
|-----------|--------|
| `@keenmate/web-grid` | `wg` |
| `@keenmate/web-multiselect` | `ms` |
| `@keenmate/web-daterangepicker` | `drp` |
| `@keenmate/web-player` | `wp` |
| `@keenmate/svelte-treeview` | `ltree` *(legacy, predates the rule)* |
| `@keenmate/svelte-switch` | `sw` |

When adding a new component, **update both this table and the
authoritative one in `base-variables.md`** — they must stay in sync.

### Legacy exceptions

`ltree` for `svelte-treeview` predates the derivation rule and stays
as-is — renaming would force a breaking change on every consumer's
override CSS. New components do *not* get to choose arbitrary
mnemonics; follow the algorithm or justify in the PR.

---

## Intake summary block

After running the intake (manually or via `/new-component`), record
the answers in the new repo's `README.md` under "Component metadata"
and in its first `CHANGELOG.md` entry. Paste this template:

```markdown
## Component metadata

- **Technology:** vanilla web component / Lit / Svelte
- **Package:** @<owner>/<tech-prefix>-<name>
- **CSS prefix:** <prefix>
- **Container selector:** :host  (web) / .<prefix>-container  (Svelte)
- **npm availability checked:** YYYY-MM-DD
- **Reserved in guidelines repo:** base-variables.md (commit <sha>)
```

The intake summary also belongs in the **decisions** part of the PR
that introduces the package — every reviewer should be able to see
the three answers without grepping.

---

## After intake — what to read next

The intake hands off to the brand-new-component reading order from
[README.md](./README.md):

1. [css-structure.md](./css-structure.md) — file layout.
2. [theme-container.md](./theme-container.md) — `:host` vs
   `.<prefix>-container`, default background, per-instance
   `data-theme`.
3. [base-variables.md](./base-variables.md) — variable taxonomy, the
   manifest format, the prefix reservation step.
4. [color-scheme.md](./color-scheme.md) — dark-mode signals.
5. [example-web-player.md](./example-web-player.md) — worked example.

The intake decisions feed forward: the chosen technology determines
which branch of the theme-container guideline applies, the chosen
prefix lands in every `--<prefix>-*` declaration, and the package name
appears in the manifest's `component` field.
