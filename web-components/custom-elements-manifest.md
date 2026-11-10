# Custom Elements Manifest — distribution & discoverability

**Web-components only.** This topic governs how a custom-element
package ships a **Custom Elements Manifest (CEM)** — the
`custom-elements.json` file produced by
[`@custom-elements-manifest/analyzer`](https://github.com/open-wc/custom-elements-manifest)
— and the editor-tooling files derived from it. Svelte / light-DOM
components are **not** custom elements and do not ship a CEM; the
whole triad is N/A for them (see D-CEM-1).

Read this once. Walk [custom-elements-manifest.decisions.md](./custom-elements-manifest.decisions.md)
before wiring it up, and [custom-elements-manifest.checks.md](./custom-elements-manifest.checks.md)
(C-CEM-1 … C-CEM-12) before declaring done.

---

## Why this multiplies everything else

The CEM is the **distribution key**, not optional plumbing. One small
JSON file, generated once, unlocks three separate adoption levers:

1. **[webcomponents.org](https://www.webcomponents.org/) catalog
   listing — automatic.** The catalog indexes npm packages, records
   whether a package *validly* contains custom elements (it reads the
   `customElements` field in `package.json` and the manifest it points
   at), and periodically rescans for new versions. **No manual
   submission — but no CEM means no listing.** A `web-*` package
   without a manifest is invisible to the one catalog our users search.

2. **Editor autocomplete — free, from the same manifest.** From
   `custom-elements.json` we generate:
   - `vscode.html-custom-data.json` → VS Code offers tag + attribute
     completion and hover docs for `<web-daterangepicker>` in `.html`.
   - `web-types.json` → JetBrains IDEs (WebStorm, IntelliJ) do the
     same, auto-discovered from the `web-types` field in `package.json`.

   Almost nobody in the vanilla-web-component space ships these. It's a
   real, cheap adoption lever.

3. **Collections.** webcomponents.org has first-class support for
   *collections* — users search for a group of related components
   rather than hunting one at a time. Our whole `web-*` family is
   exactly that case; the catalog can only group what it can index, so
   the CEM is the prerequisite (see D-CEM-4).

**Do this once across every `web-*` package before spending any effort
on outreach.** Outreach to a catalog that can't list you is wasted.

> **Two manifests, don't conflate them.** This package already ships
> `component-variables.manifest.json` (see
> [base-variables.md](./base-variables.md) → "Exporting the manifest")
> — that describes the component's *theming variables*. The CEM
> (`custom-elements.json`) describes the component's *element API*
> (tag, attributes, properties, events, slots, CSS parts). Both ship,
> both are pointed at from `package.json`, and they serve different
> tools. Keep them separate.

---

## The three artifacts

Every `web-*` package ships these three files at the package root and
includes them in the published tarball (`files` field / pack):

| File | Produced by | Consumed by | `package.json` field |
|---|---|---|---|
| `custom-elements.json` | `cem analyze` | webcomponents.org catalog, VS Code, JetBrains, any CEM-aware tool | `"customElements"` |
| `vscode.html-custom-data.json` | analyzer VS Code plugin | VS Code HTML language service | *(consumer wires `html.customData`)* |
| `web-types.json` | analyzer JetBrains plugin | JetBrains IDEs (auto-discovered) | `"web-types"` |

The two editor files are **derived from** the CEM — they are not
hand-written and never edited by hand. Regenerating the CEM regenerates
them.

---

## `package.json` — the fields that make it discoverable

Three additions. All three are mechanical and checked (C-CEM-4,
C-CEM-5, C-CEM-9):

```jsonc
{
  "customElements": "custom-elements.json",
  "web-types": "web-types.json",
  "keywords": [
    "web-components", "custom-elements", "customelements",
    "keenmate", "bliss"
    // …plus component-specific keywords (grid, multiselect, …)
  ],
  "files": [
    "dist/",
    "custom-elements.json",
    "web-types.json",
    "vscode.html-custom-data.json",
    "component-variables.manifest.json"
    // …
  ]
}
```

- **`customElements`** — the standardized field the whole ecosystem
  reads. webcomponents.org's validity check and VS Code's package
  auto-discovery both key off it. Without it there is no listing and no
  editor integration. (C-CEM-4)
- **`web-types`** — JetBrains auto-discovers this field from
  `node_modules`; no consumer-side config needed. (C-CEM-5)
- **`keywords`** must include `web-components` **and**
  `custom-elements` — the catalog uses them for search and for
  grouping the family into a collection. (C-CEM-9)
- **`files`** must list all three artifacts so they actually ship in
  the tarball. A CEM that exists locally but isn't packed is invisible
  to npm consumers. (C-CEM-8)

There is no `package.json` field for the VS Code HTML custom-data file.
Consumers opt in with one line in their workspace `.vscode/settings.json`:

```jsonc
{
  "html.customData": [
    "./node_modules/@keenmate/web-daterangepicker/vscode.html-custom-data.json"
  ]
}
```

Document that snippet in the component's `docs/usage.md` so consumers
can find it.

---

## The analyzer config

A single config file at the package root drives generation of all three
artifacts. Name it `custom-elements-manifest.config.mjs` (`.js` / `.cjs`
also accepted — C-CEM-2):

```js
// custom-elements-manifest.config.mjs
import { customElementVsCodePlugin } from 'custom-element-vs-code-integration';
import { customElementJetBrainsPlugin } from 'custom-element-jet-brains-integration';

export default {
  globs: ['src/**/*.ts'],
  exclude: ['src/**/*.spec.ts', 'src/**/*.test.ts'],
  outdir: '.',                       // custom-elements.json at package root
  litelement: false,                 // vanilla custom elements
  plugins: [
    customElementVsCodePlugin({ outdir: '.' }),      // vscode.html-custom-data.json
    customElementJetBrainsPlugin({ outdir: './', fileName: 'web-types.json' }),
  ],
};
```

Add the analyzer and both integration packages as **devDependencies**
(C-CEM-1):

```
npm i -D @custom-elements-manifest/analyzer \
         custom-element-vs-code-integration \
         custom-element-jet-brains-integration
```

The analyzer reads JSDoc on the element class to enrich the manifest —
`@attr`, `@fires`, `@slot`, `@csspart`, `@cssprop`. The richer the
JSDoc, the better the autocomplete. It's worth annotating the Element
class (the thin I/O wrapper — see
[component-structure.md](./component-structure.md)) since that's where
the public surface lives.

---

## Build & publish wiring

**The manifest is a generated artifact — it must be regenerated by the
build, never edited by hand.** Wire it into the package scripts so it
can't drift (C-CEM-7):

```jsonc
{
  "scripts": {
    "analyze": "cem analyze",
    "build": "npm run analyze && vite build"   // analyze BEFORE the bundle
  }
}
```

The `/publish` flow already gates on a fresh build
([publish-command.md](./publish-command.md) → Section 12 "Build" and
Section 13 "Verify package contents"). For a web-component that flow
must, in addition to the JS/CSS bundle:

- **Regenerate** `custom-elements.json`, `web-types.json`, and
  `vscode.html-custom-data.json` via the `analyze` step (Section 12).
- **Verify the pack ships them** — the three files appear in
  `npm pack --dry-run` output (Section 13, `{{PACK_FILES}}`).
- **Stage them in the commit** if they're committed to git (D-CEM-2 =
  A; Section 14 `{{STAGE_FILES}}`).

A **stale** manifest (source changed, `cem analyze` not re-run) is the
main failure mode. C-CEM-10 catches it: re-running the analyzer must
produce **no diff**. Committing the artifacts (D-CEM-2 = A) makes that
diff visible in PR review, so the manifest doubles as a human-readable
API-change record.

---

## Manifest fidelity

The manifest is only useful if it tells the truth. Two facts must agree
with the source (C-CEM-11):

- The declared **tag name** matches `customElements.define('the-tag',
  …)` (the same string checked by C-CST-2 / C-NC-1).
- The declared **attributes** match the `ATTRIBUTE_TABLE` /
  `observedAttributes` (C-NC-7), and declared **events** match the
  `dispatchEvent` call sites (C-NC-3). Analyzer JSDoc (`@attr`,
  `@fires`) is how you keep these in sync.

If the analyzer under-reports (e.g. attributes registered dynamically
rather than declared), add the missing `@attr` / `@fires` JSDoc rather
than hand-editing the JSON — hand edits are wiped on the next
`cem analyze`.

---

## Documenting the public surface (harvestable JSDoc)

A structurally-correct manifest can still ship **empty hover docs**.
The analyzer only harvests **`/** … */` JSDoc blocks** — it does **not**
read inline `//` line comments or trailing `//` comments, and a bare
member has nothing to harvest. So an attribute can appear in
autocomplete with no description at all.

Concretely: `<web-daterangepicker selection-mode>` showed no hover
because its backing member —
`selectionMode?: 'single' | 'range' | 'multiple'` in `types.ts` — had
no `/** */` block, so there was nothing to harvest. Siblings like
`date-member`, `picker-mode`, and `time-display`, whose members *do*
carry `/** */`, show hover text. Nothing is broken — the plugin only
surfaces docs that exist.

The rule (C-CEM-13): **document every public-facing member** — the
members targeted by the `key:` column of `ATTRIBUTE_TABLE`, the members
behind public property setters, and any `@attr` the class declares.
Put the doc **on the backing options interface** (e.g.
`DatePickerOptions` in `types.ts`), not on the attribute wiring, so one
source feeds **both** TypeScript consumers (hover / IntelliSense) **and**
the manifest.

### Canonical property-JSDoc format

Use this shape for every public member so hovers render consistently
across the suite. It is **intro line → blank line → bullet list of
allowed values**:

```ts
/**
 * <one-line intro of what the property does>. Default: <default>.
 *
 * - `value-a` — what this value does
 * - `value-b` — what this value does
 * - `value-c` — what this value does
 */
selectionMode?: 'single' | 'range' | 'multiple';
```

Format rules that make the hover render (editors render the JSDoc block
as markdown, and the analyzer/plugin must preserve line breaks rather
than collapsing them — see the note below):

- **Intro line first**, ending with `Default: <value>.` when the member
  has a default.
- **A blank line before the bullet list.** Markdown only renders a list
  reliably when a blank line precedes it — without it the bullets
  collapse into the intro paragraph.
- **One bullet per allowed value** for enum / union members:
  `` - `value` — description `` (backtick-quoted value, em-dash,
  description). This is what surfaces the allowed values in the hover.
- Non-enum members (strings, numbers, booleans) use just the intro line
  (plus `@default` / units where useful) — no bullet list needed.

*Footnote:* if hovers render the multiline block as one run-on line
instead of a list, the editor generator is collapsing the newlines when
it copies the description into `vscode.html-custom-data.json` /
`web-types.json`. The line breaks must survive; keep them if you patch
the generator.

Inline `//` comments help nobody downstream — convert them to this
format. After editing JSDoc, re-run `cem analyze` and confirm the
manifest refreshed (C-CEM-10).

---

## Svelte / light-DOM components

Svelte components in the Bliss suite are consumed as Svelte, not as
custom elements, so they have **no CEM** and this entire triad is N/A
(D-CEM-1). If a component is *additionally* compiled to a custom
element (a `customElements.define(...)` build target), the CEM applies
to **that build's** entry points — treat it as a web-component for this
topic and point `customElements` at the manifest for the custom-element
distribution.

---

## Anti-patterns

1. **Hand-editing `custom-elements.json`.** It's generated. Edits are
   lost on the next `cem analyze`. Fix the source JSDoc instead.
2. **Shipping the CEM but forgetting the `customElements` field.** The
   file exists, the catalog still can't find it — the field is the
   pointer the ecosystem reads. (C-CEM-4)
3. **Generating locally but not listing in `files`.** The artifact
   never reaches the tarball; npm consumers and the catalog see
   nothing. (C-CEM-8)
4. **Letting the manifest go stale.** Source changes, `analyze` not
   re-run, autocomplete lies. Wire `analyze` into `build` and commit
   the diff. (C-CEM-7, C-CEM-10)
5. **Conflating the CEM with `component-variables.manifest.json`.**
   Different files, different tools, both ship. See the callout at the
   top.
6. **Dropping the `web-components` / `custom-elements` keywords.** The
   catalog can't group the family into a collection without them.
   (C-CEM-9, D-CEM-4)

---

## Cross-references

- [component-structure.md](./component-structure.md) — the Element
  layer whose JSDoc feeds the manifest.
- [naming-conventions.md](./naming-conventions.md) — the tag
  (C-NC-1), attributes (C-NC-7), and events (C-NC-3) the manifest
  must mirror.
- [base-variables.md](./base-variables.md) → "Exporting the manifest"
  — the *other* manifest (`component-variables.manifest.json`) and its
  `exports` entry.
- [publish-command.md](./publish-command.md) — Sections 12–14, where
  the artifacts are regenerated, packed, and staged.
- [readme-structure.md](./readme-structure.md) — `docs/usage.md`
  hosts the consumer-side `html.customData` snippet.
