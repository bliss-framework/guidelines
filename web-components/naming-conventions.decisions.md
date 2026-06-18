# Naming Conventions — Pre-Implementation Decisions

Answer every decision below **before** scaffolding a new component, or
before changing an existing component's public API surface. Each
decision has a recommended default; deviating requires a one-line
justification in the PR description or component README.

Read [naming-conventions.md](./naming-conventions.md) first if any of
these questions don't make sense.

---

## D-NC-1 — Custom-element tag name (web-components only)

**Question:** What's the custom-element tag the component registers?

**Rules:**

- Mandatory hyphen (HTML spec).
- Use the family prefix as the first segment when reasonable:
  `<web-multiselect>`, `<web-grid>`. The family is currently `web-*`
  for `@keenmate/web-*` web-components.
- The tag in `customElements.define('the-tag', ElementClass)` and the
  tag selectors in `base.css` (FOUC-prevention) and example HTML
  **must** agree exactly.

**Default:** `<web-<feature>>` — the package's last name segment with
the `web-` family prefix.

**Your pick:** ____________

**N/A for Svelte components.**

---

## D-NC-2 — CSS prefix

**Question:** What's the short CSS prefix the component uses on every
emitted class and CSS variable?

**Rules:**

- Reserved registry lives in [base-variables.md](./base-variables.md).
- Two–five lowercase letters typical (`ms`, `wg`, `drp`, `wp`,
  `ltree`, `sw`).
- The prefix is **per package**. Pick once and use forever.

**Same question as D-BV-1.** Answer it once and cite here.

**Your pick:** ____________

---

## D-NC-3 — Logic class name

**Question:** What's the framework-agnostic Logic class called?

**Same question as D-CST-2.** Answer it once and cite here.

**Your pick:** ____________

---

## D-NC-4 — Boolean attribute default policy

**Question:** For each boolean attribute the component accepts, which
semantic does it use — `bool-default-true` or `bool-default-false`?

**Rule:** record the per-attribute choice in the `ATTRIBUTE_TABLE`
constant. Don't mix interpretations within one attribute.

**Default policy guidance:**

- **"Feature on by default; consumer opts out"** → `bool-default-true`.
  Examples: `multiple` (multi-select enabled by default),
  `allow-groups`, `enable-search`.
- **"Feature off by default; consumer opts in"** → `bool-default-false`.
  Examples: `allow-add-new`, `show-counter`.

**Your table:**

| Attribute | Pattern |
|-----------|---------|
| ____ | bool-default-true / bool-default-false |
| ____ | bool-default-true / bool-default-false |

---

## D-NC-5 — Public-notification surface

**Question:** How do consumers subscribe to fire-and-forget
notifications?

| Option | When to pick |
|--------|--------------|
| **A — Both `CustomEvent` and `*Callback` field** *(default for web-components)* | Web-component consumed in any framework. Dispatch the bare-name `CustomEvent` AND call the optional config-field `*Callback`. Parallel APIs. |
| B — `on*` Svelte props only *(default for Svelte components)* | Svelte component consumed in a Svelte app. No `CustomEvent` is dispatched; props are the only surface. |
| C — `CustomEvent` only | Acceptable for web-components where no JS consumer is anticipated and removing the `*Callback` field simplifies the surface. Document why. |
| D — `*Callback` only | Acceptable for plain JS-class components consumed only via `new` (no DOM API at all). Rare. |

**Default:** A for web-components; B for Svelte components.

**Your pick:** A / B / C / D

If C or D, justify briefly: ____________

---

## D-NC-6 — CustomEvent names (web-components only)

**Question:** Which `CustomEvent` names does the component dispatch?

**Rules:**

- Bare lowercase. No `on*` prefix. No `Event` suffix.
- Short — one or two words; two words hyphenated (`item-added`).
- Match HTML standard names where the meaning aligns (`'select'`,
  `'change'`, `'input'`).

**Your list:** ____________ (e.g., `'select', 'deselect', 'change'`)

**N/A for Svelte components.**

---

## D-NC-7 — `*Member` + `get*Callback` pair adoption

**Question:** Does the component expose data-extractor pairs in the
form `<thing>Member` (string property name) + `get<Thing>Callback`
(function)?

| Option | When to pick |
|--------|--------------|
| **A — Yes** *(default for any component with item data)* | The component has selectable / displayable / draggable items where the consumer's data model varies. Both shapes coexist. |
| B — Function only | Items are typed; consumer always provides a function. Rare in our suite. |
| C — Member only | Items are always the canonical shape; no function override. Rare. |
| D — Neither | Component has no data extraction needs (it's a pure UI primitive — a switch, a badge). |

**Default:** A for data-driven components (multiselect, grid,
treeview); D for primitives.

**Your pick:** A / B / C / D

---

## D-NC-8 — Interceptor (`before*Callback`) adoption

**Question:** Does the component expose `before*Callback` interceptors
for any of its actions (drop, delete, copy, paste, submit, …)?

| Option | When to pick |
|--------|--------------|
| **A — Yes** *(default when the component performs destructive or non-trivial state changes)* | The consumer should be able to veto, modify, or async-defer the action. Examples: drag-drop, clipboard, form-submission. |
| B — No | The component's actions are local and reversible (toggling open/closed, navigating focus). |

**Default:** B for primitives, A for complex interactive components.

**Your pick:** A / B

If A, list the interceptors: ____________

---

## D-NC-9 — `ATTRIBUTE_TABLE` single source of truth (web-components only)

**Question:** Will the component use a top-of-file `ATTRIBUTE_TABLE`
constant to drive `observedAttributes`, initial parsing, and
`attributeChangedCallback`?

**Default:** Yes. Single source of truth; matches the reference
implementation in `@keenmate/web-multiselect`.

**Anti-pattern:** Three places where attribute names live —
`observedAttributes`, the constructor's initial-parse, and
`attributeChangedCallback` — each with its own copy of the list. Drift
is a matter of time.

**Your answer:** Yes / No

If No, justify: ____________

**N/A for Svelte components.**

---

## D-NC-10 — TS interface suffix policy

**Question:** Which TS suffixes will the component's public types use?

**Same question as D-CST-7.** Answer it once and cite here.

**Your set:** ____________

---

## Decision summary

Paste into PR description / CHANGELOG entry:

```
Naming conventions decisions:
- D-NC-1  custom-element tag:           <web-foo>          (N/A for Svelte)
- D-NC-2  CSS prefix:                   <prefix>           (cites D-BV-1)
- D-NC-3  Logic class name:             <name>             (cites D-CST-2)
- D-NC-4  boolean attribute defaults:   <per-attr table>
- D-NC-5  notification surface:         A both / B on* / C CustomEvent only / D Callback only
- D-NC-6  CustomEvent names:            <list>             (N/A for Svelte)
- D-NC-7  *Member + get*Callback pair:  A / B / C / D
- D-NC-8  before*Callback interceptors: A — <list> / B none
- D-NC-9  ATTRIBUTE_TABLE:               yes / no — <reason>  (N/A for Svelte)
- D-NC-10 TS interface suffixes:        Config / EventDetail / Context / Spec / (none)  (cites D-CST-7)
```
