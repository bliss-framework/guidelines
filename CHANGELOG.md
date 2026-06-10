# Changelog

All notable changes to the web-component guidelines and tooling in this
repository. Entries are grouped by date, newest first. This repository is
not versioned — date blocks replace version numbers.

Categories used: **Added**, **Changed**, **Removed**, **Fixed**.

---

## 2026-06-10

### Added

- New **component-intake** guideline
  (`web-components/component-intake.md`) covering the pre-flight
  decisions for a brand-new component: technology choice (vanilla web
  component / Lit / Svelte), package identity
  (`@<owner>/<tech-prefix>-<name>`, npm availability checked), and CSS
  prefix derivation. Encodes the algorithm: multi-word component name
  → initials of each word (`web-daterangepicker` → `drp`);
  single-word → first letter of tech + first letter of name
  (`web-player` → `wp`, `svelte-player` → `sp`). Existing reservations
  (e.g. `ltree`) override the derivation as legacy exceptions.

- `/new-component [hint]` slash command — interactive intake
  walkthrough. Asks the three questions, derives the prefix,
  cross-checks against the reservation table in `base-variables.md`,
  runs `npm view` to verify package-name availability, outputs a
  paste-ready metadata block for the new repo's README / CHANGELOG.
  Read-only: does not scaffold files or modify the guidelines repo.

- New **theme-container** guideline triad
  (`web-components/theme-container.{md,decisions.md,checks.md}`)
  covering how a component's root element anchors its CSS variables,
  default background, dark-mode overrides, and per-instance `data-theme`
  attribute. Spells out the dual shape: `:host` for web-components,
  `.<prefix>-container` for Svelte. Adds 14 checks (C-TC-1 through
  C-TC-14). Motivated by the `@keenmate/svelte-treeview` rc10
  migration that rescoped CSS variables from `:root` to
  `.ltree-container` — the `:root` scope is unreachable from consumer
  subtree wrappers and demonstrably broke `--base-*` overrides.

- `/validate-theme-container <path>` slash command — runs the 14 new
  checks. Detects component type (web-component vs Svelte) and adapts
  the verification accordingly.

- Project-level slash commands under `.claude/commands/` for validating
  component packages against the guidelines:
  - `/validate-base-variables <path>` — runs C-BV-1 through C-BV-12 plus
    a canonical `--base-*` taxonomy alignment report.
  - `/validate-color-scheme <path>` — runs C-CS-1 through C-CS-9 plus a
    JS-theme-detection invariant cross-check.
  - `/validate-css-structure <path>` — runs C-CSS-1 through C-CSS-12,
    respecting lean-strategy / underscore / no-layers decisions
    documented in the target component's README.
  - `/validate-web-component <path>` — umbrella command running all
    **47** checks (now including theme-container) plus the 10 CLAUDE.md
    invariants, with a PR-ready consolidated report.

  Commands read the live `.md` and `.checks.md` files at runtime, so
  changes to the canonical taxonomy or check definitions propagate
  automatically.

### Changed

- **Documented the unlayered-reset footgun in `css-structure.md`.**
  A consumer-side universal reset (`* { margin: 0; padding: 0; ... }`
  from Bootstrap reboot, Tailwind preflight, normalize.css, or
  hand-rolled) is unlayered and therefore beats every rule in the
  component's `@layer component` regardless of specificity, silently
  collapsing padding/margins even though the component's CSS variables
  resolved correctly. This is the cascade-layer contract working as
  designed — but it's the #1 way consumers accidentally clobber a
  layered library's defaults. We hit it concretely in the
  svelte-treeview showcase (2026-06) where the demo page's shared
  `* { padding: 0 }` reset wiped out `.ltree-node-content` padding.
  Added a new "The unlayered-reset footgun" subsection under "Consumer
  override contract" with the canonical recommendation (wrap resets in
  their own `@layer reset { ... }`); tightened **C-CSS-10** to require
  the component README warn consumers about it explicitly.

- **C-BV-2 narrowed to `--base-*` reads only.** The check previously
  flagged every `var()` without a fallback, which produced false
  positives for `var(--<prefix>-X)` reads in feature files — those
  reads are guaranteed defined because the container's `:host` /
  `.<prefix>-container` declaration always provides the chain. The
  two-layer pattern *intentionally* puts the fallback at the
  definition site, not at every read; the check now reflects that.
  Updated files: `base-variables.checks.md` (C-BV-2 rewritten),
  `base-variables.md` (new "Fallbacks live at the definition site"
  subsection making the rule explicit), `CLAUDE.md` invariant #9
  (tightened wording), `/validate-base-variables` slash command (C-BV-2
  note adjusted).

- Scope expanded: guidelines now explicitly cover both web-components
  (`:host`) and Svelte components (`.<prefix>-container`).
  `web-components/` folder name kept for backwards compatibility; the
  README and `CLAUDE.md` introduction clarify the broader applicability.
- `web-components/README.md` — added the theme-container row to the
  topic table, added a Theme-container section to the mandatory
  checklist, added theme-container to the brand-new-component reading
  order (between css-structure and base-variables).
- `web-components/base-variables.md` and `color-scheme.md` — added a
  one-line cross-reference pointing at `theme-container.md` for the
  question of *where* their rules anchor.
- `CLAUDE.md` — updated directory map to include theme-container,
  updated invariants #4 / #5 / #6 to cover both component types and
  the container-scope rule, added `ltree` and `sw` to the reserved
  prefix list.
- `/validate-web-component` umbrella command — now runs four triads
  (47 checks total) instead of three (33 checks), with the
  theme-container section threaded through the consolidated report.

- Initial web-component guidelines under `web-components/`:
  - `README.md` — index, mandatory checklist, vocabulary,
    project-wide invariants.
  - `css-structure.md` + `.decisions.md` + `.checks.md` — file
    layout, `@layer` cascade, BEM conventions.
  - `base-variables.md` + `.decisions.md` + `.checks.md` — two-layer
    `--base-*` / `--<prefix>-*` taxonomy, canonical variable set,
    manifest format.
  - `color-scheme.md` + `.decisions.md` + `.checks.md` — dark-mode
    handling, `light-dark()` fallbacks, framework-class hooks,
    per-instance overrides.
  - `example-web-player.md` — worked example applying all three topics.

- `CLAUDE.md` at repo root — agent guidance, directory map, workflow,
  ten non-negotiable cross-cutting invariants.
