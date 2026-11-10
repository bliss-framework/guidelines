# BlissFramework component guidelines

The rulebook for the Keenmate / Bliss component libraries: how a
component is structured, named, styled, themed, documented and released.

It covers both families:

- **Web components** — `@keenmate/web-grid`, `@keenmate/web-multiselect`,
  `@keenmate/web-daterangepicker`, `@keenmate/web-treeview`,
  `@keenmate/web-player`, …
- **Svelte components** — `@keenmate/svelte-treeview`,
  `@keenmate/svelte-switch`, …

This repository contains **documentation and check scripts only** — no
component code, no build, no `package.json`. The components live in
their own repositories; agents and people working on them read the
rules here before they scaffold, refactor or release.

---

## Why it exists

Every component is built by a different person or agent session, months
apart. Without a shared rulebook they drift: one component's dark mode
breaks inside a dark page, another's variables can't be themed per
section, a third renames an attribute without telling anyone. These
guidelines write down the decisions once, with the reasons, and give
each one a check that can be run against any component.

The few rules that hold everywhere (full list in [CLAUDE.md](./CLAUDE.md)):

1. A component works **standalone** — without the theme designer or any
   page CSS it still renders a usable default.
2. Theming is **two layers of CSS variables**: `--base-*` (shared across
   components, set by the page) and `--<prefix>-*` (one component,
   declared on its container). Never three, never on `:root`.
3. **Dark mode is pure CSS** — no JavaScript theme detection, and never a
   bare `color-scheme` on the component container.
4. **One component, one short prefix** (`wg`, `ms`, `drp`, `wtv`, …) on
   every CSS class (BEM) and variable.
5. Every visible colour goes through a variable; colour literals live
   only in `variables.css` / `dark-mode.css`.
6. Every web component ships a **Custom Elements Manifest**.

---

## How it's organised

Everything lives in [`web-components/`](./web-components/) (a historical
name — the rules apply to Svelte components too, with per-technology
differences called out). Start with
[`web-components/README.md`](./web-components/README.md), the index: it
tells you which topic to read for the task at hand.

Each **topic** is a set of up to four files:

| File | What it's for | When you use it |
|---|---|---|
| `<topic>.md` | The rules and the reasons behind them | Read once, end to end |
| `<topic>.decisions.md` | Questions to answer before writing code (`D-XX-n`), each with a default | Before you start; record the picks in the PR |
| `<topic>.checks.md` | The verification list (`C-XX-n`) | Before you call the work done |
| `<topic>.checks.sh` | Runs the mechanical checks against a component package | With the checks list, or in CI |

Topics:

| Topic | Covers |
|---|---|
| [component-intake](./web-components/component-intake.md) | A new component: technology, package name, prefix |
| [component-structure](./web-components/component-structure.md) | Layers, files, classes, TypeScript suffixes |
| [naming-conventions](./web-components/naming-conventions.md) | Tags, attributes, callbacks, events, BEM |
| [css-structure](./web-components/css-structure.md) | CSS file layout, `@layer` order |
| [theme-container](./web-components/theme-container.md) | `:host` vs `.<prefix>-container`, per-instance `data-theme` |
| [base-variables](./web-components/base-variables.md) | The `--base-*` contract, the prefix registry, the variables manifest |
| [color-scheme](./web-components/color-scheme.md) | Dark / light mode |
| [core-adoption](./web-components/core-adoption.md) | Building web components on `@keenmate/web-components-core` |
| [responsive-overlay](./web-components/responsive-overlay.md) | Dropdowns and panels on phones vs desktop |
| [custom-elements-manifest](./web-components/custom-elements-manifest.md) | `custom-elements.json`, editor autocomplete, webcomponents.org |
| [readme-structure](./web-components/readme-structure.md) | The slim README + `docs/` folder, What's New |
| [example-pages](./web-components/example-pages.md) | Section codes (`TH07`) on example pages |
| [release-notes](./web-components/release-notes.md) | The per-version upgrade guide |
| [publish-command](./web-components/publish-command.md) | The shared `/publish` release flow |
| [example-web-player](./web-components/example-web-player.md) | A worked example applying the topics |

---

## How to use it

### Working on a component

1. Find the topics your task touches in the
   [index](./web-components/README.md) — often more than one.
2. Read each topic's `.md`.
3. Walk each `.decisions.md` and note your picks.
4. Implement in the component's repository.
5. Run each `.checks.md`: tick every box, or record the exception under
   `## Known limitations` in the component README.

A brand-new component starts with the intake (`/new-component`), then
follows the reading order in [CLAUDE.md](./CLAUDE.md).

### Running the checks

The scripts run against a component **package** directory, not this
repository:

```bash
bash web-components/css-structure.checks.sh   C:/Git/KM/web-multiselect
bash web-components/release-notes.checks.sh   C:/Git/KM/web-multiselect
```

Each prints ✅ / ❌ / ⏭ per check and exits `1` on any failure. Checks
are tagged by how much judgment they need:

- **`[auto]`** — fully mechanical; the script decides.
- **`[semi]`** — mostly mechanical, needs a bit of context.
- **`[manual]`** — needs a person or an agent to read code or look at
  the browser.

### Slash commands (Claude Code)

Opening this repository in Claude Code gives you commands that apply the
guidelines to a component:

| Command | Does |
|---|---|
| `/new-component` | Interactive intake: technology, package, prefix, npm availability |
| `/validate-web-component <path>` | Full validation across all topics; writes a `validation_<timestamp>.md` punch list into the component |
| `/validate-<topic> <path>` | One topic: `css-structure`, `theme-container`, `base-variables`, `color-scheme`, `component-structure`, `naming-conventions`, `readme-structure`, `custom-elements-manifest`, `responsive-overlay` |

A failed check is a finding to triage, not an automatic verdict: the
component may be wrong, or the rule may need to change.

---

## Changing the guidelines

- A topic's files depend on each other: a new rule usually needs a
  decision, a check and (if mechanical) a line in the script.
- Keep [`web-components/README.md`](./web-components/README.md) — the
  index and the check-count table — in sync when files are added.
- Reserving a prefix or adding a `--base-*` variable affects every
  component; update both registries in `base-variables.md` /
  `.decisions.md` and flag it as a coordination change.
- Record every change in [CHANGELOG.md](./CHANGELOG.md).

More detail for agents: [CLAUDE.md](./CLAUDE.md).
