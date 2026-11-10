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
- Two–four lowercase letters (`ms`, `wg`, `drp`, `wp`, `wtv`, `stv`,
  `sw`).
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

## D-NC-5 — Public-event (notification) surface

**Question:** A function whose return value the component ignores is an
**event**, not a callback (see [naming-conventions.md](./naming-conventions.md)
→ "The consumer-function hierarchy"). How do consumers subscribe to the
component's fire-and-forget events?

| Option | When to pick |
|--------|--------------|
| **A — Both `CustomEvent` and `on*` config field** *(default for web-components)* | Web-component consumed in any framework. Dispatch the bare-name `CustomEvent` AND call the optional config-field `on*`. Parallel APIs. |
| B — `on*` Svelte props only *(default for Svelte components)* | Svelte component consumed in a Svelte app. No `CustomEvent` is dispatched; `on*` props are the only surface. |
| C — `CustomEvent` only | Acceptable for web-components where no JS consumer is anticipated and removing the `on*` field simplifies the surface. Document why. |
| D — `on*` field only | Acceptable for plain JS-class components consumed only via `new` (no DOM API at all). Rare. |

**Default:** A for web-components; B for Svelte components.

**Your pick:** A / B / C / D

If C or D, justify briefly: ____________

**Note:** none of these options uses `*Callback`. The `Callback` suffix
is reserved for functions whose return value the component consumes —
`before*Callback` interceptors (D-NC-8), `get*Callback` data extractors
(D-NC-7), and plain `*Callback` behavior providers.

---

## D-NC-6 — CustomEvent names (web-components only)

**Question:** Which `CustomEvent` names does the component dispatch?

**Rules:**

- Bare lowercase. No `on*` prefix. No `Event` suffix. No component
  prefix (`'select'`, not `'cp-select'`).
- Short — one or two words; two words hyphenated (`node-click`).
- Present tense (`node-click`, `item-add`), not past (`node-clicked`).
- Re-use a non-composed HTML name where the meaning aligns (`'select'`,
  `'change'`); **never** a composed native (`click`, `focus`, `blur`,
  `input`, `keydown`, `copy`, `cut`, `paste`, `drop`, … — full list in
  [naming-conventions.md](./naming-conventions.md) → "CustomEvent
  naming"). Prefix the domain instead: `'node-copy'`.
- Each event has an `on<PascalName>` twin (`'node-click'` ↔
  `onNodeClick`) receiving the same detail; dispatched with core's
  `emit()` on the host, `composed: false`.
- Shapes (D-NC-18): set / state changes are `<state>-change` with the
  whole new state; single acts are `<domain>-<verb>`; `change` only for
  the form value.

**Your list:** ____________ (e.g., `'select', 'deselect', 'change', 'action'`)

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

**Contract (both options):** one `ctx` argument; may be async; returns
`false` to cancel, nothing to continue unchanged, or a replacement to
continue with that. A per-value transform that can't cancel is not an
interceptor — name it `get<Thing>ValueCallback` (D-NC-7).
Exception: interceptors whose native trigger needs a synchronous answer
(`beforeDragStartCallback`, `beforeKeydownCallback`) are sync and say so;
keydown interceptors return `false` to suppress the built-in, never `true`.

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

## D-NC-11 — Controller facade and context

**Question:** What does the component hand to callbacks and events as
`controller`, and which context fields does it add?

**Rules:**

- `controller` is a curated public facade (a typed interface, e.g.
  `MultiSelectController`), never the internal state class. Internal
  state is named `*Engine`.
- Every `ctx` / event `detail` carries `controller` + `element`; a
  component that presents a popup also adds `presentation` /
  `isFullscreen` / `isModal`.
- Shared signatures: `open()` / `close()` / `toggle()` / `isOpen` (if it
  opens), `showMessage(content, { variant, autoHideMs })` / `hideMessage()` /
  `isMessageShown`, `showLoader()` / `hideLoader()` (D-NC-23).
- State is a same-named property on element and controller; `get*()`
  only for parameterised lookups / computed snapshots (D-NC-14).

**Your controller interface:** ____________ (e.g. `GridController<T>`)

**Presentation fields:** yes (popup) / no (inline only)

---

## D-NC-12 — Action items

**Question:** Does the component let consumers configure clickable items
(action buttons, toolbars, context / header menus)?

| Option | When to pick |
|--------|--------------|
| **A — Yes, core `ActionItem` / `MenuEntry`** *(default whenever there are configurable buttons or menus)* | Items follow the ms/drp pattern (static field + `get*Callback`, one `ctx`), `action` reserved for built-ins with `'custom'` + `id` for consumer items, divider entries, `children` / `getChildrenCallback`, one `'action'` event + `onAction` + `beforeActionCallback`. |
| B — No | The component has no configurable clickable items. |

**Never:** a component-local item type with its own field names,
`bool | fn` union fields, `dividerBefore`, positional `onclick` args.
Toggle state is `isToggled` / `getIsToggledCallback` (buttons: `aria-pressed`;
menu items: `menuitemcheckbox` + `aria-checked`).
`data-action` / `data-id` are reserved for action items; internal controls
use a prefixed attribute (`data-<prefix>-action`).

**Your pick:** A / B

If A, list the surfaces and their `source` names: ____________
(e.g. `'action-buttons'`, `'row-toolbar'`, `'context-menu'`)

---

# Suite-wide naming decisions (2026-10-27)

D-NC-13 … D-NC-27 are **fixed rules**, not per-component choices — they
were decided across the whole suite during the v2 API-naming
unification (source: `web-components-core/docs/api-naming-audit.md`).
A component doesn't pick an answer; it confirms compliance (or lists a
justified deviation in the PR). Each entry records the decision date
and a one-line rationale.

---

## D-NC-13 — Verb glossary

**Decided 2026-10-27.** Public methods, action ids, event verbs and
ctx fields use the glossary in [naming-conventions.md](./naming-conventions.md)
→ "Verb glossary": open/close/toggle + `isOpen` (surface you work in)
vs show/hide + `isVisible` (display only); select/deselect vs
check/uncheck vs focus vs highlight; add/insert/create;
remove/delete/clear/reset/discard; cancel/abort/dismiss; commit/apply;
update/replace/refresh/reload; search/filter (`term`);
move/reorder/drag-drop; `destroy` the only teardown verb;
`scrollTo<Thing>()` → `Promise<boolean>`.

**Rationale:** the same verb meant different things across components
(svelte-treeview `highlight` = selection; grid `row-delete` = request vs
treeview `node-delete` = done) — one glossary makes a verb predict
behaviour.

**Compliant:** yes / deviations: ____________

---

## D-NC-14 — State is a property; `get*()` only for lookups

**Decided 2026-10-27.** Real state = same-named property on the element
**and** the controller (controller read-only where the element is
writable). `get*()` only for lookups with an argument and computed
snapshots that build new objects. No `set*()` duplicates of properties.

**Rationale:** `selectedRows` vs `getSelectedRowsData()` vs
`getSelectedRows()` returned different shapes for one state.

**Compliant:** yes / deviations: ____________

---

## D-NC-15 — Boolean config keys and attribute derivation

**Decided 2026-10-27.** Config key `is*Shown` (visibility) /
`is*Enabled` (feature) / `should*` (policy) / `is|has|can*` otherwise.
The attribute is derived mechanically: `isXShown` → `show-x`,
`isXEnabled` → `enable-x`, `shouldX` → `x`
(`shouldCloseOnSelect` → `close-on-select`), `isDisabled` / `isReadonly`
/ `isMultiple` → `disabled` / `readonly` / `multiple`. Same concept =
same attribute in every component. JS properties keep the prefix.

**Rationale:** one concept had three attributes (`enable-virtual-scroll`
/ `virtual-scroll` / `is-virtual-scroll-enabled`); prefixed JS names are
clearer in code than Shoelace's bare `open`, while attributes stay
HTML-shaped.

**Your attribute list:** ____________

---

## D-NC-16 — `disabled` / `readonly`

**Decided 2026-10-27.** Every form-participating component has
`isDisabled` / `disabled` (no interaction, not submitted) and
`isReadonly` / `readonly` (readable / focusable / copyable, submitted).
`<fieldset disabled>` is handled once in core `BlissElement`
(`formDisabledCallback` merged into `isDisabled`). "Off" enum values are
`'none'`, never `'disabled'`.

**Rationale:** native form controls behave this way; half the suite
lacked a control-level disabled and grid encoded readonly as a mode.

**Form-participating:** yes (both flags present) / no

---

## D-NC-17 — `km-` prefix for core shared UI

**Decided 2026-10-27.** Shared UI rendered by
`@keenmate/web-components-core` uses the `km-` prefix — already defined
in [base-variables.md](./base-variables.md) (prefix registry and the
`--_km-*` → `--km-*` → `--base-*` chain); naming-conventions only
cross-references it.

**Rationale:** one owner for the rule, no duplicate definition to drift.

---

## D-NC-18 — Event shapes

**Decided 2026-10-27.** Kebab-case, present tense, no component prefix,
1–2 words. A change to a set / state = `<state>-change`
(`selection-change`, `checked-change`, `expanded-change`,
`focus-change`), one event per change with the whole new state. A single
act = `<domain>-<verb>` (`node-drop`, `row-delete`, `file-cancel`).
`change` only for the form value. `action` fires **after** the built-in
(notification).

**Rationale:** a consumer can predict an event's name and payload from
the state or act it reports; `change` keeps its form meaning.

**Your list:** ____________

---

## D-NC-19 — Ready / defer / destroy (core)

**Decided 2026-10-27.** Core `BlissElement` provides, for all
components: `defer` attribute / property holds the first render;
`release()` (or removing `defer`) builds once; then the `ready` event +
`:state(ready)` + `ready` host attribute; `whenReady(): Promise`. Every
element exposes `destroy()`.

**Rationale:** ms / drp / dz / ed each had their own `deferRender`,
`ready()`, `is-ready` / `data-ready` variant — one core implementation.

---

## D-NC-20 — ctx / detail nouns

**Decided 2026-10-27.** `item` is reserved for the `ActionItem`
(core `/actions`); otherwise the domain noun (`option`, `row`, `node`,
`file`, `command`, `date`). Never a bare `index` (`optionIndex`,
`rowIndex`, `fileIndex`). Old / new pairs are always `old*` / `new*`.

**Rationale:** multiselect's `action` detail carried both `item`
(ActionItem) and `option`; `prev*` / `previous*` / `old*` all coexisted.

**Your ctx nouns:** ____________

---

## D-NC-21 — Member pairs and one `ctx`

**Decided 2026-10-27.** `<xxx>Member` ↔ `get<Xxx>Callback`, same stem;
boolean members are `is*Member` (`isDisabledMember`, `isLockedMember`).
All callbacks take one `ctx` (no positional args) — applies to
svelte-treeview too.

**Rationale:** `disabledMember` + `getIsDisabledCallback` broke the
pairing; positional Svelte callbacks were the last exception to the
one-`ctx` rule.

---

## D-NC-22 — Counts, limits, sizes, virtual scroll

**Decided 2026-10-27.** Limits `max*` / `min*` + singular noun + `Count`
(`maxVisibleBadgeCount`); `*Size` only for bytes / px / `pageSize`;
virtual scrolling family `virtualScroll*` (`virtualScrollItemHeight`,
`virtualScrollOverscan`).

**Rationale:** five spellings for "how many" (`*Limit`, `*MaxVisible`,
`maxVisible*`, `*Count`, `*Below`) and three virtual-scroll families.

---

## D-NC-23 — Messages and loaders

**Decided 2026-10-27.** `showMessage(content, { type: 'info' |
'warning' | 'error' | 'success', autoHideMs })`, `hideMessage()`,
`isMessageShown`; no toggle methods; loaders `showLoader()` /
`hideLoader()`.

**Rationale:** daterangepicker's positional `showMessage` and
`toggleMessage` / `toggleLoader` diverged from multiselect's options
form.

**Amended 2026-11-07:** the option is `variant?: MessageVariant`
(`'info' | 'success' | 'warning' | 'danger'`), not `type` with `'error'`.
pure-admin's toasts already say `variant` with the contract's role names
(`danger`), and `MessageType` broke C-NC-11's suffix set. Affected:
web-multiselect (`type?: MessageType`, `'error'`), web-daterangepicker
(`type?: MessageSeverity`, `'error'`).

**Shows messages / loaders:** yes / no

---

## D-NC-24 — Labels and i18n

**Decided 2026-10-27.** One `labels` property per component (partial
object, `{name}` placeholders, built-in English only, also a JSON
attribute); page-wide via core `/locale`
(`window.components.locale = { locale, labels: { 'web-x': {...} } }`);
per-key merge instance → page → English; no per-string `*-text`
attributes; no built-in language tables in components; months /
weekdays / numbers from `Intl`; empty-list text key `empty`.

**Rationale:** `labels` / `customStrings` / `STATUS_LABELS` / ~8 `*Text`
keys and five names for "empty" — one surface, one merge order.

**Your label keys:** ____________

---

## D-NC-25 — Enum values are kebab-case

**Decided 2026-10-27** (replaces the former SCREAMING_SNAKE rule for
enum string values). Enum / union string values are kebab-case;
property and method names stay camelCase; SCREAMING_SNAKE is for code
constants only.

**Rationale:** values appear in HTML attributes, like native
`type="datetime-local"`; Plyr and Shoelace do the same; every component
already used kebab.

---

## D-NC-26 — `on*` is reserved for event twins

**Decided 2026-10-27.** `on<Name>` exists only as the twin of an emitted
event (`onRowChange` ⇔ `'row-change'`) or a Svelte event prop. Options-bag
hooks: return used → `before*Callback`; notification only → plain
`*Callback` (core positioning `onBeforeCompute` → `beforeComputeCallback`,
`onPlaced` → `placedCallback`).

**Rationale:** an `on*` name promises a matching DOM event; helper option
bags have none, so the name was a false promise.

---

## D-NC-27 — Small rules

**Decided 2026-10-27.** Form field name is `name` everywhere; `multiple`
never `multi`; no bare `mode` — qualify by meaning (`preset`,
`layoutMode`, `editMode`); root CSS part is always `container`; menu /
action items use core's `{ text, onClick, cssClass }`; `cssClass` (not
`className`) for class options.

**Rationale:** each was a two- or three-way split in the audit
(`formFieldId` / `formFieldName` / `name`, `'multi'` / `'multiple'`,
`root` / `container`, `className` / `cssClass`).

---

## Decision summary

Paste into PR description / CHANGELOG entry:

```
Naming conventions decisions:
- D-NC-1  custom-element tag:           <web-foo>          (N/A for Svelte)
- D-NC-2  CSS prefix:                   <prefix>           (cites D-BV-1)
- D-NC-3  Logic class name:             <name>             (cites D-CST-2)
- D-NC-4  boolean attribute defaults:   <per-attr table>
- D-NC-5  event (notification) surface: A both / B on* props / C CustomEvent only / D on* field only
- D-NC-6  CustomEvent names:            <list>             (N/A for Svelte)
- D-NC-7  *Member + get*Callback pair:  A / B / C / D
- D-NC-8  before*Callback interceptors: A — <list> / B none
- D-NC-9  ATTRIBUTE_TABLE:               yes / no — <reason>  (N/A for Svelte)
- D-NC-10 TS interface suffixes:        Config / EventDetail / Context / Spec / (none)  (cites D-CST-7)
- D-NC-11 controller / context:         <Controller interface>; presentation fields yes / no
- D-NC-12 action items:                 A — <surfaces> / B none
- D-NC-13..27 suite-wide rules (2026-10-27): compliant / deviations: <list>
  - D-NC-15 boolean attributes:         <key → attribute list>
  - D-NC-16 disabled / readonly:        yes / N/A (not form-participating)
  - D-NC-18 events:                     <state>-change: <list>; acts: <list>
  - D-NC-24 label keys:                 <list>
```
