# README Structure — Pre-Implementation Decisions

Answer every decision below **before** writing a new component's
documentation, or before splitting an existing oversized README into
the canonical layout. Each decision has a recommended default;
deviating requires a one-line justification in the PR description or
the component README.

Read [readme-structure.md](./readme-structure.md) first if any of
these questions don't make sense.

---

## D-RS-1 — Deployed demo location

**Question:** Where is the live, browsable demo hosted?

**Options:**

- **A — `demos.keenmate.com/<component>`** (default for public
  KeenMate components). Single subdomain, one path per component.
- **B — GitHub Pages on the component repo.** Acceptable when the
  central demo site doesn't yet host the component.
- **C — Storybook (deployed).** Reasonable when the component is
  primarily consumed inside a design system that already runs
  Storybook.
- **D — No deployed demo.** Only acceptable for private / internal
  packages. The "Demos & docs" section in the README becomes "Docs"
  and links only into `docs/`.

**Default:** A.

**Don't:** link to a CodePen / CodeSandbox as the primary demo —
those rot, fall out of sync with the package, and embed the demo
author's account. Use them as supplementary examples in
`docs/examples.md`, not as the canonical landing-page demo.

**Your pick:** ____________

---

## D-RS-2 — Accessibility doc applicability

**Question:** Does this component need a first-class
`docs/accessibility.md` file?

**Options:**

- **A — Required.** The component has any interactive surface —
  keyboard focus, clickable regions, dispatched user events. This is
  the default; nearly every component qualifies.
- **B — N/A (display-only).** The component renders content with no
  interactive behavior — a static badge, an icon, a read-only chart
  cell. The README must then carry a single "Accessibility notes"
  paragraph explaining the display-only nature; `docs/accessibility.md`
  is omitted and C-RS-13 is N/A.

**Default:** A.

**Don't:** mark N/A because writing the doc is tedious. If the
component reacts to any user input, A is the correct answer.

**Your pick:** ____________

---

## D-RS-3 — Examples format

**Question:** Single `docs/examples.md` file, or a `docs/examples/`
folder with one file per pattern?

**Options:**

- **A — Single `docs/examples.md`.** Default for components with up
  to ~8 examples. Easier to navigate, easier to maintain a coherent
  ordering, GitHub's single-file rendering scrolls fine.
- **B — `docs/examples/` folder** with `01-react-wrapper.md`,
  `02-vue-wrapper.md`, etc. Use when examples grow past ~8 and the
  single file becomes a TOC scroll problem. `docs/examples.md` then
  becomes a 1-page index that links into the folder.

**Default:** A. Promote to B only when the single file genuinely
hurts to navigate.

**Don't:** start with B "for future growth" — premature folder
hierarchies are a navigation tax with no payoff.

**Your pick:** ____________

---

## D-RS-4 — Framework-integration guide location

**Question:** Where do framework-specific integration walkthroughs
(React wrapper, Vue wrapper, SvelteKit setup, Blazor interop) live?

**Options:**

- **A — Inside `docs/examples.md`** as one section per framework.
  Default for web-components — they integrate by drop-in custom
  element use, so the per-framework wrappers are short.
- **B — Dedicated `docs/integrations/<framework>.md` files.** Use
  when a framework's integration has enough surface (a SSR story, a
  hydration story, a state-binding adapter, a typed wrapper package)
  that one section can't hold it.
- **C — Separate npm packages.** When integration becomes a real
  wrapper library (`@keenmate/web-multiselect-react`), the docs for
  the wrapper live with the wrapper package, not the core. The core
  `docs/examples.md` links out instead.

**Default:** A. Promote to B or C only when the section earns it.

**Your pick:** ____________

---

## D-RS-5 — "What's new" content shape

**Question:** What does the README's "What's new" section say?

**Options:**

- **A — Latest version number + 1-line summary + link to
  `CHANGELOG.md`.** Default. The link is authoritative; the inline
  summary is for visitors who don't click.
- **B — Last 2–3 versions, each with a 1-line summary.** Acceptable
  for components in active churn where one version doesn't capture
  the recent shape. Hard cap: 3 entries; older entries belong in
  `CHANGELOG.md` only.
- **C — No "What's new" section.** Acceptable only for components
  that have stabilized and changes are now rare (1.x.0 components
  with last release > 6 months old). The link to `CHANGELOG.md`
  moves to the "Demos & docs" section.

**Default:** A.

**Don't:** paste full changelog entries into the README. The
README is a landing page, not a release-notes archive.

**Your pick:** ____________

---

## D-RS-6 — Existing oversized READMEs — migration strategy

**Question:** How do you migrate an existing 1,000+ line README to
this structure?

**Options:**

- **A — One PR per docs file.** First PR extracts `docs/theming.md`
  from the existing README sections. Second PR extracts
  `docs/usage.md`. Etc. The README shrinks in tracked, reviewable
  chunks. Default for components in active production use.
- **B — Single PR, full rewrite.** Replace the entire README and
  write all four `docs/` files in one commit. Faster but harder to
  review and risks regressing on prose that was good. Acceptable for
  components with low external dependency on the existing README.
- **C — Big-bang with a comparison.** Single PR, but include a
  side-by-side "what moved where" table in the PR description so
  reviewers can verify nothing was lost. Default for components that
  ship a deprecation message in the old README pointing at the new
  layout.

**Default:** A for shipped components with active consumers; C for
internal-only or pre-1.0.

**Don't:** silently delete the old README content without confirming
every paragraph found a new home. Use the C-style comparison table
during review even if you choose A.

**Your pick:** ____________

---

## Decision summary (for the PR description)

| Decision | Pick | One-line rationale |
|---|---|---|
| D-RS-1 — Demo location | | |
| D-RS-2 — Accessibility doc | | |
| D-RS-3 — Examples format | | |
| D-RS-4 — Integration guides | | |
| D-RS-5 — What's new shape | | |
| D-RS-6 — Migration strategy | | |
