# Component Structure — Pre-Implementation Decisions

Answer every decision below **before** scaffolding a new component, or
before refactoring an existing component's internal architecture. Each
decision has a recommended default; deviating requires a one-line
justification in the PR description or component README.

Read [component-structure.md](./component-structure.md) first if any of
these questions don't make sense.

---

## D-CST-1 — Host technology

**Question:** Which technology hosts the component?

**Options:**

- **A — Web-component** (custom element with Shadow DOM). Default for
  primitives consumed across multiple front-end stacks. Element layer
  is a class extending `HTMLElement`.
- **B — Svelte component**. Default for Svelte-only / SvelteKit-app-
  internal components. Element layer is a `.svelte` file.
- **C — Other framework** (React / Vue / Blazor / LiveView). The four-
  layer model still applies in spirit; pick the framework's equivalent
  shapes and document the choice.

**Default:** A for primitives shared across stacks; B for Svelte-only.

**Don't:** mix Shadow DOM and Svelte in the same component. Pick one.

**Your pick:** ____________

---

## D-CST-2 — Logic class name

**Question:** What's the framework-agnostic Logic class called?

**Rules:**

- For (A) web-component: `Web<Feature>`, generic if appropriate
  (`WebMultiSelect<T>`, `WebGrid<T>`).
- For (B) Svelte component: `<Feature>Controller` or
  `<Feature>Coordinator` in a `<feature>-controller.svelte.ts` or
  `<Feature>Controller.svelte.ts` file (matches svelte-treeview's
  `TreeController.svelte.ts`).
- One Logic class per component. No `MultiSelectCore` *and*
  `WebMultiSelect` for the same feature.

**Your pick:** ____________ (e.g., `WebMultiSelect`, `TreeController`)

---

## D-CST-3 — Element class / file name

**Question:** What's the Element layer called?

**Rules:**

- For (A) web-component: `<Feature>Element extends HTMLElement` in
  `src/web-component.ts`. Suffix `Element` is mandatory (mirrors
  `HTMLInputElement` / `HTMLDivElement`).
- For (B) Svelte component: `<Feature>.svelte` in
  `src/lib/components/`. PascalCase file name. No suffix.
- The custom-element tag and the Element class name **must agree**:
  `<web-multiselect>` ↔ `MultiSelectElement` registered via
  `customElements.define('web-multiselect', MultiSelectElement)`.

**Your pick:** ____________ (e.g., `MultiSelectElement`, `Tree.svelte`)

---

## D-CST-4 — Service classes

**Question:** What single-capability Service classes will this
component own?

**Examples from existing components:**

- web-multiselect: `Tooltip`, `VirtualScroll`.
- svelte-treeview: `RenderCoordinator`.

**Rules:**

- Each Service has **one** job. If you can't describe its job in one
  sentence, split it.
- Services don't import each other. Cross-Service coordination is the
  Logic class's job.
- Service files are named after the class in kebab-case (`tooltip.ts`,
  `virtual-scroll.ts`).

**Default:** Start with zero. Extract a Service class only when the
Logic class has > ~200 lines of code dedicated to a clearly separable
concern (positioning, virtual scrolling, tooltip lifecycle), or when
the concern is reusable in a sibling component.

**Your list:** ____________

---

## D-CST-5 — Side-layer files

**Question:** Which Side-layer files will the component ship with?

**Canonical set (almost always present):**

- [ ] `types.ts` — TS interfaces / enums / type aliases (no runtime
      code).
- [ ] `logger.ts` — logging helpers + `LOGGING_CATEGORIES`.

**Sometimes present:**

- [ ] `constants.ts` — magic strings/numbers (often inlined into
      other Side-layer files when the count is small).
- [ ] `helpers/<thing>.ts` or `<thing>-helpers.ts` — pure utility
      functions.
- [ ] Pure data structures with no DOM dependency (svelte-treeview's
      `ltree/`).

**Rule:** every Side-layer file must be liftable to its own package
with at most one line of edits. If it imports from the Logic or
Element layers, it's misnamed.

**Your list:** ____________

---

## D-CST-6 — Manager layer?

**Question:** Does the component need a Manager class between the
Element and the Logic class?

| Option | When to pick |
|--------|--------------|
| **A — No Manager** *(default)* | Single Logic class; the Element calls it directly. Honors the Bliss "Management only if adds value" rule. |
| B — Manager class | Two or more Logic classes that must be coordinated, or a transactional sequence the consumer shouldn't see. Rare in component libraries. |

**Default:** A.

**Your pick:** A / B

If B, justify briefly: ____________

---

## D-CST-7 — TS interface suffix policy

**Question:** Which suffixes will the public TS types use?

**Default set (use exactly these, no others):**

- [ ] `Config` for the main configuration object.
- [ ] `EventDetail` for `CustomEvent.detail` payloads (web-components
      only).
- [ ] `Context` for arguments passed to user-supplied rendering
      callbacks.
- [ ] `Spec` for declarative descriptor / table-row shapes (e.g.,
      `ATTRIBUTE_TABLE` rows).
- [ ] (none) for plain data models.

**Migration case:** if the component has a legacy `Options` interface
and a new `Config` interface, both may coexist with `Options` marked
`@deprecated`. After one major version, drop `Options`.

**Forbidden:** `Interface`, `Type`, `Data`, `Info`, `Object`, `Model`,
or any `I*` prefix.

**Your set:** ____________

---

## D-CST-8 — Premature interfaces?

**Question:** Will the component define interfaces for shapes with a
single implementation?

**Default:** No. The Bliss "Use only what you need" rule applies.
Wait until a second implementation is real.

**Exception:** an interface defining a *public contract* (e.g.,
`MultiSelectConfig` describes what the consumer passes in) is not
premature — it's the API surface. The rule targets *internal*
abstractions like `IMultiSelect` with one implementation.

**Your answer:** No premature interfaces / Yes — justify: ____________

---

## D-CST-9 — Logic class framework-runtime imports

**Question:** Does the Logic class import from any framework runtime
(Svelte, React, Vue)?

| Option | When to pick |
|--------|--------------|
| **A — No** *(default for web-components)* | Logic class uses only DOM, browser globals, Service classes, Side layer. Stays portable. |
| B — Svelte runes only (`$state`, `$derived`) | Default for Svelte-hosted Logic classes that live in `.svelte.ts` files. Svelte 5 runes are a language extension, not a runtime call. |
| C — Yes, full framework runtime | Anti-pattern. Means the Logic class is actually a framework-coupled component; either rename it or split off the framework piece. |

**Default:** A for web-components; B for Svelte-component Logic classes.

**Your pick:** A / B / C

If C, justify briefly: ____________

---

## Decision summary

Paste into PR description / CHANGELOG entry:

```
Component structure decisions:
- D-CST-1 host technology:               A web-component / B Svelte / C other
- D-CST-2 Logic class name:              <name>
- D-CST-3 Element class / file:          <name>
- D-CST-4 Service classes:               <list or "none">
- D-CST-5 Side-layer files:              <list>
- D-CST-6 Manager layer:                 A no / B yes — <reason>
- D-CST-7 TS interface suffixes:         Config / EventDetail / Context / Spec / (none)
- D-CST-8 premature interfaces:          no / yes — <reason>
- D-CST-9 Logic-class framework imports: A none / B Svelte runes only / C full
```
