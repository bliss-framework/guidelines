# README Structure — Component Documentation Layout

How a KeenMate component library documents itself externally: what
lives in the npm-landing-page README, what gets pushed into the
`docs/` folder, what each `docs/` file owns.

This doc focuses on **documentation packaging** — *where* prose
lives, not what it says. For *what* a component's theming contract
should explain, read [theme-container.md](./theme-container.md),
[base-variables.md](./base-variables.md), and
[color-scheme.md](./color-scheme.md); this file says those
explanations belong in `docs/theming.md`, not in the main README.

---

## TL;DR

> **`README.md` is a landing page, not a manual.** It tells a visitor
> *what* the component is, *what's new*, *where the demos are*, *how
> to install*, *one quick code snippet*, *where the deep docs are*,
> and *the license*. Everything else — full API, theming contract,
> worked examples, accessibility notes — lives in `docs/`.

---

## The canonical layout

```
package-root/
├── README.md         ← slim landing page (~150–300 lines)
├── CHANGELOG.md
├── LICENSE
└── docs/
    ├── usage.md          ← full API: attributes, props, events, callbacks, slots, methods
    ├── theming.md        ← container + variable + color-scheme contracts
    ├── examples.md       ← worked examples beyond the quick start
    └── accessibility.md  ← keyboard, ARIA, focus, screen-reader notes
```

Relative links from `README.md` to `docs/<file>.md` render correctly
on GitHub, npm, jsDelivr, and most package registries. Absolute URLs
break when the package is browsed offline or vendored — **always use
relative links** between in-package docs.

---

## Why split this way

Two problems with the everything-in-README pattern that today's
component libraries (multiselect, daterangepicker, grid, treeview)
all suffer from:

1. **npm/GitHub landing pages bury the value proposition.** A visitor
   evaluating the component has to scroll past 1,500 lines of API
   reference to find out whether it does what they need. They leave.
2. **The README becomes the catch-all.** Theming, accessibility,
   integration patterns, FAQ, troubleshooting, every example — all
   pile up in one file that nobody can navigate. Internal links rot,
   sections duplicate, the table of contents becomes a wall.

The slim README + `docs/` split solves both:

- The landing page reads in 60 seconds. Visitor either bounces fast
  (good — wrong fit, no time wasted) or installs and follows links
  into `docs/` as they need them.
- Deep docs live in topically focused files. A reader looking for
  theming reads only `docs/theming.md`; a reader looking for keyboard
  shortcuts reads only `docs/accessibility.md`. No scrolling past
  unrelated prose.

---

## `README.md` — what stays in the landing page

Exactly these sections, in this order:

| Section | Purpose | Size budget |
|---|---|---|
| Title + 1-line tagline | What the component *is*, in one sentence | 2–3 lines |
| What is it | 1–3 short paragraphs — value proposition, who it's for, what makes it different | < 30 lines |
| Status badges (optional) | npm version, license, CI/build, bundle size | 1 line |
| What's new | One or two `## What's New in vX.Y.Z` sections (most-recent two) in the canonical format. See [`## What's New in vX.Y.Z` — canonical format](#-whats-new-in-vxyz--canonical-format) below. | < 80 lines combined |
| Demos & docs | Deployed-demo URL (if any) + bulleted links to each `docs/` file | < 15 lines |
| Install | `npm install …` (and CDN if applicable) | < 10 lines |
| Quick start | Minimum viable code snippet + 1-paragraph explanation | < 30 lines |
| Browser / framework support | Short list or table | < 10 lines |
| About | Canonical KeenMate authorship + Pure Admin / Theme Designer auto-theming statement — the same paragraph in every component README. See [`## About` — canonical text](#about--canonical-text) below. | 4–8 lines |
| Built with BlissFramework | One-line attribution + link to [`blissframework.dev`](https://blissframework.dev/) — the guidelines this component follows | 1–3 lines |
| License | One-line mention + link to `LICENSE` | < 5 lines |

**Hard cap: 400 lines. Soft target: 200.** If the README exceeds
400 lines, content has leaked from `docs/` back into the landing
page — move it back. (See check C-RS-2.)

What the README **does not** carry:

- ❌ Full attribute/prop tables — those live in `docs/usage.md`.
- ❌ Full event reference — `docs/usage.md`.
- ❌ Theming variables / dark-mode / framework conventions —
  `docs/theming.md`.
- ❌ More than one code example — additional snippets go in
  `docs/examples.md`.
- ❌ Keyboard / ARIA / focus discussion — `docs/accessibility.md`.
- ❌ Troubleshooting / FAQ — `docs/usage.md` or a dedicated
  `docs/troubleshooting.md` if it grows.

---

## `## About` — canonical text

Every component README carries the **same** authorship-and-theming
statement. The text below is the source of truth — paste it verbatim
into the component's `## About` section, swapping nothing but the
relative `LICENSE` link if needed.

```markdown
## About

Authored and maintained by [KeenMate](https://keenmate.com/).
The component ships standalone with sensible light/dark defaults;
when mounted inside [Pure Admin](https://pureadmin.io/) — or any
host that publishes the `--base-*` taxonomy via
[`@keenmate/theme-designer`](https://www.npmjs.com/package/@keenmate/theme-designer) — it adopts the host's colors,
typography, and sizing automatically. There is no runtime
dependency on Pure Admin; the integration is opt-in via CSS
variables.
```

### Why exactly this text

Today's component READMEs say different things — `web-multiselect`'s
"Credits" line claims the component is "Created by KeenMate as part
of the Pure Admin design system", `web-daterangepicker`'s says
"Extracted from the Pure Admin design system". Both are factually
wrong: the components live independently of Pure Admin, they were
not extracted from it, and several KeenMate components predate the
Pure Admin integration entirely.

The canonical text fixes four things in one paragraph:

1. **Authorship is unambiguous** — "Authored and maintained by
   KeenMate". No "as part of", no "extracted from".
2. **Standalone is the default** — every component renders with
   bundled light/dark defaults on a plain page. Consumers who don't
   want Pure Admin or Theme Designer don't have to load anything
   extra. (Cross-references the standalone-render invariant — #1 in
   CLAUDE.md — and check C-BV-10.)
3. **Pure Admin theming is opt-in, not a dependency** — "There is
   no runtime dependency on Pure Admin." The integration happens
   through the `--base-*` taxonomy, which Pure Admin publishes via
   Theme Designer but any consumer can publish themselves. Mounting
   the component inside Pure Admin gives the auto-theme; mounting it
   anywhere else with a `--base-*` set gives the same result.
4. **The integration mechanism is named** — `--base-*` and
   `@keenmate/theme-designer`. Readers who want to theme without
   Pure Admin know exactly which CSS variables to set; readers who
   want the Pure Admin look know which npm package to install.

### Placement

The canonical layout puts `## About` **between Browser support and
Built with BlissFramework** — both are attribution / metadata
content, and grouping them at the README tail keeps the install /
quick-start surface clean.

Components that already ship a `## Credits` section (today's
`web-multiselect`, `web-daterangepicker`) should rename it to
`## About` when adopting the canonical text. The check C-RS-15
accepts either heading during the transition period so a rename
isn't a hard gate, but new components and rewrites use
`## About`.

### What the section is *not*

- Not a "Credits" list of third-party libraries or contributors.
  Those (rarely needed for KeenMate components) belong in a
  `## Acknowledgements` section if they exist at all.
- Not the BlissFramework attribution. That's a separate section
  (`## Built with BlissFramework`) enforced by C-RS-14, with its
  own link to `https://blissframework.dev/`. About answers *who
  built it and what it integrates with*; Built with BlissFramework
  answers *what rulebook it follows*.

---

## `## What's New in vX.Y.Z` — canonical format

Every component README carries one or two `## What's New in vX.Y.Z`
sections near the top — between the one-line tagline / "What is it"
intro and the next major heading (typically `## Features`,
`## Highlights`, or `## Demos & docs`). The shape of each section
is identical across components so a reader who has skimmed one
package's release highlights knows what to expect from the next.

This is **the canonical structure**. The `/publish` slash-command
in every component repo drafts new sections in this shape; check
C-RS-16 enforces it on every release.

### Heading

```markdown
## What's New in v1.3.3
```

Exact format: `## What's New in v<semver>`. The version is unquoted
(no backticks), prefixed with a lowercase `v`, and matches the
semver in `package.json` at release time. No date in the heading —
dates belong in `CHANGELOG.md`.

### Entry shape

Each release section is a flat bulleted list. Every bullet uses
this exact pattern:

```markdown
- **`<Component or area>` — <one-line headline of the change>** — <engineer-level prose>
```

Three parts, in order:

1. **Lead phrase** — bold-wrapped, opens with the affected
   component / surface (often in backticks: `` `TextField` ``,
   `` `TopNav` ``, `` `Badge` `` — or a non-component area like
   `Demo page`, `Z-index scale`) followed by a `—` and a short
   headline of *what changed*. The whole lead phrase is one
   `**…**` bold span.
2. **Em-dash separator** — ` — ` (space, em-dash, space) between
   the bold lead phrase and the prose body. Plain hyphens (`-`) or
   en-dashes (`–`) don't satisfy the format; use a true em-dash.
3. **Prose body** — one paragraph baked into the same bullet,
   typically 3–8 sentences. Explains:
   - *what* changed (the API or visual delta),
   - *why* it was needed (history, regressions, user-facing
     motivation — e.g. "Recurring regression last fixed ~5 months
     ago, reintroduced during the structural rework"),
   - *what surface* is affected (concrete component names listed
     inline, not vaguely "several wrappers"),
   - *the mechanism* (the technique used —
     "conditional-spread pattern `{...(title ? { title } : {})}`",
     "rendered through a `--topnav-toggle-size` CSS variable"),
   - *edge-case variants* where relevant (e.g.
     `value != null` for inputs so `value=""` still renders).

No sub-bullets. No nested lists. One bullet per change, however
long the prose runs. The whole entry is a single line of markdown
broken across multiple physical lines only by editor wrap.

### Tone and content

Engineer-to-engineer. Names real symbols (`@attr`, `[readonly]`
CSS attribute-presence selector, `menuToggleSize`, `--fluent-z-*`,
`light-dark()`). Names affected components inline rather than
saying "all form fields". Explains the *why* and the *mechanism*,
not just the *what* — a release highlight a reader can act on, not
a marketing line.

Acceptable bullet types (you can mix them in one section):

- **Feature** — a new prop / attribute / API. Lead phrase ends in
  the new surface name; prose explains the gap it fills and any
  edge cases.
- **Behavior change** — visible default or interaction change.
  Prose explains the old behavior, the new behavior, and the
  rationale.
- **Bug fix worth advertising** — only for fixes consumers will
  notice or that were long-standing pain. Prose names the
  regression history if applicable and the underlying mechanism.
  Don't lift internal-only fixes into What's New; those stay in
  the CHANGELOG.
- **Demo / docs change** — new showcase page or worked example
  paired with a feature/fix bullet. Lead phrase: `Demo page — …`
  or `` `<route>` showcase — … ``.

### Worked example

From `svelte-fluentui` v1.3.3 (the reference implementation of
this format):

```markdown
## What's New in v1.3.3

- **Custom-element attribute bindings stop stringifying `undefined` / `null` / `false`** — Recurring regression (last fixed ~5 months ago, reintroduced during the structural rework) that affected 22 wrappers including `TextField`, `Textarea`, `Switch`, `Slider`, `Checkbox`, `Button`, `Anchor`, `Accordion(Item)`, `BreadcrumbItem`, `DataGrid(Row/Cell)`, `Dialog`, `Listbox`, `MenuButton`, `Option`, `TabPanel`, `Toolbar`, `NumberField`, `Combobox`, plus `Paginator` and `QuickGrid` sub-buttons. Svelte 5 sets properties on custom elements rather than attributes, and FAST's `@attr` decorators stringify whatever they receive — so unset props were rendering as `title="undefined"`, `readonly="false"`, `disabled="false"`, etc. The `readonly`/`disabled` cases were the worst symptom because `[readonly]` and `[disabled]` CSS attribute-presence selectors match regardless of value, leaving an enabled field with a not-allowed cursor. All affected wrappers converted to the conditional-spread pattern (`{...(title ? { title } : {})}`) which physically omits the attribute from the template when unset. Variants `{...(value != null ? { value } : {})}` for inputs (so `value=""` still renders) and `{...(attr !== undefined ? { attr } : {})}` for numeric props (so `0` survives) are used where falsy values are meaningful.

- **`TextField` demo page — new Readonly and Disabled example sections** — The `/components/forms/text-field` showcase previously demonstrated only the basic input and `autocomplete` variants; the readonly and disabled states (the surface that exposed the bug above) had no live example. Added Readonly with outline + filled variants and Disabled with three variants (outline + placeholder, outline + value, filled + value).
```

### Mechanics

- **Placement** — top of README, after the one-line tagline /
  "What is it" intro, before `## Features` / `## Highlights` /
  `## Demos & docs`. Newest version first; older sections stacked
  below in descending semver.
- **Retention** — **at most two** `## What's New in vX.Y.Z`
  sections live in the README at any time. The third (oldest) is
  deleted when a new release lands. Older history lives in
  `CHANGELOG.md`. The `/publish` command enforces this trim in
  its README-update step.
- **Length per section** — 1–8 bullets. Sections with > 8 bullets
  are over-stuffed; consolidate related changes into one bullet
  or drop the marginal ones (they're already in CHANGELOG).
- **No headers inside the section** — no `### Added` /
  `### Fixed` sub-headings. Use the lead-phrase verb to signal
  the change type ("Stop stringifying…" for a fix, "New `radius`
  prop…" for an addition). The CHANGELOG carries the structured
  Added/Changed/Fixed split; What's New is a curated highlight
  reel.
- **No emojis in the heading or lead phrases** — the format reads
  as prose, not as a release-card UI. Backticks for symbol names
  are the only inline decoration.

### Relationship to the CHANGELOG

The CHANGELOG section for a release is the **exhaustive** record
— every Added / Changed / Fixed / Removed / Internal bullet. The
What's New section is the **curated subset**: only entries a
consumer would care about, paraphrased to read as engineer-to-
engineer prose rather than reproduced verbatim. Pure internal
refactors and `Fixed`-only entries that aren't worth advertising
stay out of What's New entirely.

Every Added / Changed bullet in the CHANGELOG that represents a
user-facing change *should* have a corresponding What's New bullet
(check C-RS-7 covers presence, C-RS-16 covers shape). The
`/publish` command validates this coverage in its "Validate README
reflects the release" step.

---

## `docs/usage.md` — the API reference

Audience: a developer integrating the component. Owns everything the
consumer touches at runtime.

Required sections:

- **Attributes / props** — every public attribute (web-components)
  or prop (Svelte), with type, default, and a sentence of intent.
  Web-components: this is the canonical home of the `ATTRIBUTE_TABLE`
  documentation per C-NC-7.
- **Events / callbacks** — every `CustomEvent` (web-components) or
  callback prop (Svelte / JS-config consumers). Document name,
  payload shape, when it fires, and whether it's cancelable.
- **Slots / children** — what content the component accepts, where
  it lands in the rendered output, and any slot-specific contract.
- **Methods / imperative API** — if the component exposes runtime
  methods (`.open()`, `.refresh()`, etc.), document each here.
- **Lifecycle notes** — anything non-obvious about
  `connectedCallback` / `onMount` timing, SSR behavior, hydration.

Optional sections (add as needed):

- Types — exported TypeScript interfaces consumers extend.
- Troubleshooting / FAQ — common integration gotchas.

---

## `docs/theming.md` — the theming contract

Audience: a developer customizing visuals. Owns every contract the
existing theming triads currently scatter across the README.

Required sections:

- **Container contract** (C-TC-11) — which element is the theme
  container (`:host` or `.<prefix>-container`), where consumers
  attach `data-theme`, what framework conventions are honored
  (`data-bs-theme`, `.dark`, etc.).
- **Variable contract** (C-BV-8) — link to or inline the
  `component-variables.manifest.json`, document
  `--<prefix>-rem` and override patterns, show at least one
  `--base-*` override and one `--<prefix>-*` override.
- **Color-scheme strategy** (C-CS-8) — per-instance dark mode, OS
  preference handling, contrast targets, the framework-class
  selectors the component supports.
- **Cascade-layer contract** (C-CSS-10) — the
  `@layer variables, component, overrides;` order, where consumer
  overrides should land, and the unlayered-reset footgun warning
  *if* the component is at risk of that interaction.
- **BEM hooks** — the public class names consumers can target from
  outside the shadow root (web-components) or from sibling CSS
  (Svelte). One section per public part.

This file is the single home for the four old "README documents the
X contract" checks. After this triad ships, those checks point here,
not at `README.md`.

---

## `docs/examples.md` — worked examples

Audience: a developer who already knows the basics and wants to see
real patterns.

Required: at least one worked example **beyond** the README's quick
start. Suggested examples (pick what's relevant to the component):

- Framework integration — React wrapper, Vue wrapper, Svelte usage,
  Blazor interop.
- Data binding — populating from a fetch, two-way binding, async
  loading.
- Advanced configuration — multi-attribute scenarios, callback
  composition, custom rendering.
- Theming — a fully themed instance combining several `--base-*`
  and `--<prefix>-*` overrides.
- Patterns the team hits repeatedly in production.

Each example: a 1-paragraph "what this shows", a fenced code block,
and (if non-trivial) a link to a runnable demo.

If the component is simple enough that the README's quick start
covers 90% of usage, this file is still required — write a single
"common patterns" section even if short. (See D-RS-3 for the
single-file vs `examples/` folder choice.)

---

## `docs/accessibility.md` — the a11y contract

Audience: a developer or auditor verifying WCAG / Section 508 /
EN 301 549 compliance.

Required sections:

- **Keyboard navigation** — every interactive key (Tab, Shift+Tab,
  Enter, Space, Esc, arrow keys, Home/End), what it does, what
  focus state it leaves.
- **ARIA roles & states** — every `role`, `aria-*`, and `aria-live`
  the component sets, and what consumers should set on parent
  elements.
- **Screen-reader behavior** — what NVDA/JAWS/VoiceOver announce on
  key state changes, any caveats per AT.
- **Focus management** — where focus goes on open/close, when focus
  is trapped, when it's not.
- **Contrast & visual** — minimum contrast ratios honored by the
  default theme (cross-link to `docs/theming.md`).

**Exception (D-RS-2):** purely display components with no
interactive surface (a read-only icon renderer, a static badge) can
mark this file N/A and document the reasoning in a single
"Accessibility notes" paragraph in the README. Anything with a
keyboard surface needs the file.

---

## Worked example — what `web-multiselect`'s slim README looks like

```markdown
# @keenmate/web-multiselect

> A framework-agnostic multi-select web component. Themeable, keyboard-friendly, no dependencies.

## What is it

`@keenmate/web-multiselect` is a custom element (`<web-multiselect>`)
that turns a list of options into a searchable, themeable multi-
select dropdown. It works in any HTML page or framework that can
render a custom element — React, Vue, Svelte, Blazor, plain HTML.

Designed to drop into existing design systems: it reads `--base-*`
variables from the page if `@keenmate/theme-designer` is present,
falls back to sensible defaults otherwise, and ships with first-class
dark-mode and per-instance theming.

## What's new

**v3.4.0** — Native HTML `disabled` attribute on options, new
`onChange` callback shape, dark-mode contrast improvements. See
[CHANGELOG.md](./CHANGELOG.md).

## Demos & docs

- 🚀 [Live demo](https://demos.keenmate.com/web-multiselect)
- 📘 [Usage / API reference](./docs/usage.md)
- 🎨 [Theming contract](./docs/theming.md)
- 📚 [Examples / cookbook](./docs/examples.md)
- ♿ [Accessibility](./docs/accessibility.md)

## Install

\`\`\`bash
npm install @keenmate/web-multiselect
\`\`\`

## Quick start

\`\`\`html
<script type="module">
  import '@keenmate/web-multiselect';
</script>

<web-multiselect placeholder="Pick a country">
  <option value="cz">Czech Republic</option>
  <option value="sk">Slovakia</option>
  <option value="at">Austria</option>
</web-multiselect>
\`\`\`

That's it — the component renders a styled dropdown, handles
keyboard navigation, and dispatches `select` / `change` events you
can listen to. See [usage.md](./docs/usage.md) for the full API.

## Browser support

Modern evergreen browsers (Chrome, Edge, Firefox, Safari) — anything
with native `customElements` and CSS `@layer` support. No polyfills
shipped.

## About

Authored and maintained by [KeenMate](https://keenmate.com/).
The component ships standalone with sensible light/dark defaults;
when mounted inside [Pure Admin](https://pureadmin.io/) — or any
host that publishes the `--base-*` taxonomy via
[`@keenmate/theme-designer`](https://www.npmjs.com/package/@keenmate/theme-designer) — it adopts the host's colors,
typography, and sizing automatically. There is no runtime
dependency on Pure Admin; the integration is opt-in via CSS
variables.

## Built with BlissFramework

Follows the [BlissFramework component guidelines](https://blissframework.dev/)
for structure, theming, color-scheme, and accessibility.

## License

MIT — see [LICENSE](./LICENSE).
```

That's ~60 lines. Today's `web-multiselect/README.md` is ~2,000.
The slim version doesn't lose information — it relocates it to
`docs/`, where readers find it when they need it.

---

## Cross-references

- [readme-structure.decisions.md](./readme-structure.decisions.md)
  — scoping decisions (demo hosting, accessibility applicability,
  examples format).
- [readme-structure.checks.md](./readme-structure.checks.md) —
  post-implementation checks (file presence, README size cap,
  required sections, deep-doc coverage).

When this triad ships, the four "README documents the X contract"
checks elsewhere (C-TC-11, C-BV-8, C-CS-8, C-CSS-10) are updated to
point at `docs/theming.md` instead of `README.md`. The substance of
those checks doesn't change — only where the prose has to live.
