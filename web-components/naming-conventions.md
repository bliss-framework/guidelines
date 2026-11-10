# Naming Conventions — Web Component / Svelte Component Guideline

How a Keenmate component library names its identifiers, files, custom-
element tags, HTML attributes, CSS classes, callback fields,
`CustomEvent`s, and internal methods.

This doc focuses on **names** — *what* the public and internal
identifiers look like. For *which file* holds *which* code, read
[component-structure.md](./component-structure.md). For *how* the CSS
is organized, read [css-structure.md](./css-structure.md). For the
two-layer CSS variable taxonomy (`--base-*` + `--<prefix>-*`), read
[base-variables.md](./base-variables.md).

The full rationale with worked examples and decision flowcharts lives
in the public manifesto:
`BlissFramework/web/docs/coding-guidelines-javascript/naming-conventions.md`.
This file is the rulebook half — tighter, with decisions and checks
alongside.

---

## TL;DR

> **Casing: camelCase identifiers, PascalCase types/classes, kebab-case
> files, tags, HTML attributes and enum string values,
> SCREAMING_SNAKE for code constants. Custom-element tags are hyphenated
> and package-prefixed (`<web-multiselect>`). Config keys are camel with
> `is*Shown` / `is*Enabled` / `should*` / `is|has|can*` for booleans; the
> HTML attribute is the short HTML-like form derived mechanically from
> the key (`isCounterShown` → `show-counter`). A single
> `ATTRIBUTE_TABLE` constant drives `observedAttributes`, parsing, and
> `attributeChangedCallback`. Consumer-supplied functions split on one
> question — **does the component use the return value?** If it's ignored,
> the function is an *event*: dispatch a bare `CustomEvent` and name its
> twin `on*` (or an `on*` Svelte prop). `on*` is **reserved for event
> twins** — a notification-only function in a plain options bag with no
> event behind it is a plain `*Callback`.
> If the return is used, it's a *callback*: `before*Callback` for
> interceptors, `get*Callback` paired with `*Member` for data extractors,
> plain `*Callback` for behavior providers. On a component the
> `Callback` suffix is reserved for return-consuming functions. Internal: `handle*` for
> methods, `*Handler` for stored references. CSS uses BEM with the
> component prefix on every class. `CustomEvent` names are bare, short,
> present tense, never a native event name that crosses shadow DOM, and
> carry the same detail as their `on*` twin. Every callback and event
> takes one `ctx` argument. Clickable items (buttons, toolbars, menus)
> share one `ActionItem` model and one `'action'` event. `controller`
> names only the public facade handed to consumers. Public verbs follow
> one glossary (open/close vs show/hide, select vs check, remove vs
> delete, …) — see "Verb glossary".**

---

## Casing summary

| Used for | Casing | Example |
|----------|--------|---------|
| Variables, function and method names, object keys | camelCase | `selectedOption`, `getItemValue()` |
| Classes, interfaces, types, enums, component classes | PascalCase | `WebMultiSelect`, `MultiSelectConfig`, `BadgesPosition` |
| TypeScript native enum members | PascalCase | `UserStatus.Active` |
| TS / JS source files, CSS files, test files | kebab-case | `web-component.ts`, `multiselect.ts`, `dark-mode.css`, `users-provider.test.ts` |
| Svelte component files | PascalCase + `.svelte` | `Tree.svelte`, `Node.svelte` |
| Custom-element tag names | kebab-case with mandatory hyphen | `<web-multiselect>`, `<my-grid>` |
| HTML attributes | kebab-case | `show-checkboxes`, `data-options` |
| CSS classes (BEM with component prefix) | kebab-case | `.ms__option--focused` |
| CSS custom properties | kebab-case with `--` prefix | `--ms-bg`, `--base-text-color` |
| Enum / union string values (anything that can appear in an attribute) | kebab-case | `'select-all'`, `'read-only'`, `'datetime-local'`, `'none'` |
| Code constants, env vars | SCREAMING_SNAKE_CASE | `MAX_LOGIN_ATTEMPTS`, `LOGGING_CATEGORIES` |

**Enum values are kebab-case** (changed 2026-10-27, D-NC-25): values
appear in HTML attributes (`selection-mode="multiple"`), like the
platform's own `type="datetime-local"`; Plyr and Shoelace do the same.
SCREAMING_SNAKE is for *code constants* only. Never camelCase values
(`'mousePosition'` → `'mouse-position'`). Names of properties and
methods stay camelCase. An "off" value is `'none'`, never `'disabled'`
or `'off'`.

---

## Custom-element tag rules

1. The tag **must** contain a hyphen — HTML spec requirement.
2. The tag uses the component's package family prefix as the first
   segment when reasonable. Current convention: `<web-*>` for web-
   component libraries in the `@keenmate/web-*` family
   (`<web-multiselect>`, `<web-grid>`).
3. The tag agrees with `customElements.define('the-tag', ElementClass)`
   exactly. Drift here breaks FOUC-prevention rules (see C-TC-15) and
   any selector targeting the tag.

---

## CustomEvent naming

1. Event names are **bare** lowercase strings, no `on*` prefix.
2. Short — one or two words. Two words are hyphenated (`node-click`).
3. **Present tense**, like the platform's own events (`click`, `change`,
   `select`): `node-click`, `item-add`, `row-change`, `date-select` —
   not `node-clicked`, `item-added`, `tree-changed`.
4. **No component prefix** (`'select'`, not `'cp-select'`). The event
   fires on the component's own host, so `e.target` already says which
   component it is.
5. **Never reuse a native event name that crosses shadow DOM**
   (composed natives): `click`, `dblclick`, `auxclick`, `contextmenu`,
   `focus`, `blur`, `focusin`, `focusout`, `keydown`, `keyup`,
   `beforeinput`, `input`, `pointer*`, `mouse*`, `touch*`, `wheel`,
   `drag*`, `drop`, `copy`, `cut`, `paste`, `composition*`. Such a native
   event fired inside the shadow root also reaches the host's
   listeners, so a listener would receive both the browser's event and
   the component's, with different `detail`s. Prefix the domain instead:
   `node-copy`, `node-paste`, `cell-input`.
   Non-composed natives — `select`, `change`, `toggle`, `scroll`,
   `load`, `error`, `reset`, `submit`, `invalid` — stay inside the
   shadow root, so re-using them is fine where the meaning aligns
   (`'select'`, `'change'`).
6. The detail interface is `<Thing>EventDetail`
   (e.g., `MultiSelectEventDetail<T>`, `ActionEventDetail`).
7. The bare `CustomEvent` name and its `on*` config-field twin are the
   same event under two surfaces: `on` + PascalCase of the event name.
   `'select'` ↔ `onSelect`, `'change'` ↔ `onChange`, `'node-click'` ↔
   `onNodeClick`. Always camelCase — never `onnodeclick`; camelCase also
   keeps the twin off the native handler properties every element
   already has (`onpaste`, `onselect`, `onchange` belong to
   `HTMLElement`; `onPaste`, `onSelect`, `onChange` don't). Both are
   fire-and-forget and receive **the same detail object**; see "The
   consumer-function hierarchy" below.
8. Every event detail carries the component context (see "Contexts and
   the controller" below): `controller` and `element` always; the
   presentation fields (`presentation`, `isFullscreen`, `isModal`) on
   components that present a popup. Core's `emit()` adds
   them — `controller` and `element` as **non-enumerable** properties,
   so destructuring works but `JSON.stringify(e.detail)` (e.g. a LiveView
   `pushEvent`) and logs see only the data.
9. Events are dispatched **on the host**, bubbling, `composed: false`.
   A component placed in a page still bubbles through the page; one
   nested inside another component's shadow DOM (an editor inside a
   grid cell) can't leak out and be mistaken for the outer component.
10. **Two shapes only** (D-NC-18):
    - **A change to a set / state** → `<state>-change`, one event per
      change carrying the **whole new state** (not a delta event per
      item): `selection-change`, `checked-change`, `expanded-change`,
      `focus-change`. The state noun matches the property
      (`expanded-change` ↔ `expandedPaths`), never a verb form
      (`expand-change`).
    - **A single act** → `<domain>-<verb>`: `node-drop`, `row-delete`,
      `file-cancel`, `date-select`. Still one or two words — if a third
      seems needed, drop the redundant one (`file-upload-complete` →
      `file-upload`). Verbs come from the "Verb glossary" below.
11. **`change` is reserved for the form value** (what a `<form>` would
    submit). Any other state change uses `<state>-change`. Don't fire
    two events with identical detail for one act (`select` + `change`,
    `files-change` + `change`) unless they are genuinely different
    surfaces (an act vs the form value).
12. **`action` is a notification after the fact** — it fires after the
    built-in behaviour has run (see "Action items" rule 8).
13. **`ready`** is the core lifecycle event (see "Ready, defer and
    destroy"); components don't invent `initialized` / `loaded` /
    `rendered` variants.

Forbidden: `'onSelect'`, `'Select'`, `'selectEvent'`, `'select-event'`,
`'SELECT'`, `'node-clicked'`, `'cp-select'`, `'copy'` (a composed
native), `'file-upload-complete'` (more than two words), `'expand-change'`
(verb instead of the state noun), `'km-overlay-activated'` (prefixed,
past tense) — none of these follow the rules above. The `on*` form is
the *field* name, never the `CustomEvent` string.

---

## HTML attribute ↔ config key mapping

Two distinct names for the same concept, kept consistent by a single
declarative table:

| Public attribute (kebab) | Internal config key (camel) | Type |
|--------------------------|-----------------------------|------|
| `multiple` | `isMultiple` | boolean |
| `disabled` | `isDisabled` | boolean |
| `readonly` | `isReadonly` | boolean |
| `show-checkboxes` | `isCheckboxesShown` | boolean |
| `enable-search` | `isSearchEnabled` | boolean |
| `close-on-select` | `shouldCloseOnSelect` | boolean |
| `keep-search-on-close` | `shouldKeepSearchOnClose` | boolean |
| `badges-position` | `badgesPosition` | enum |
| `max-height` | `maxHeight` | string |
| `name` | `name` | string |

Pattern:

- Attributes are short, declarative, HTML-shaped (`multiple`, not
  `is-multiple`; `show-summary`, not `is-summary-shown`).
- Internal config keys are longer, fully descriptive, JS-shaped
  (`isSummaryShown`). The JS **property keeps the prefix** — unlike
  Shoelace's bare `open` — because it reads clearer in JS
  (`if (el.isOpen)`).
- A single top-of-file `ATTRIBUTE_TABLE` constant (core `static inputs`)
  maps the two and drives `observedAttributes`, initial parsing, and
  `attributeChangedCallback`. **One source of truth.**

### Boolean config keys and their attributes (D-NC-15)

The config key's prefix says what kind of flag it is; the attribute is
derived from the key **mechanically** — no per-component creativity:

| Kind | Config key | Attribute | Example |
|------|-----------|-----------|---------|
| Feature switch — turns on a feature/part named by a noun | `is<Feature>Enabled` | `enable-<feature>` | `isVirtualScrollEnabled` → `enable-virtual-scroll`, `isFilteringEnabled` → `enable-filtering` |
| Visibility of a part | `is<Part>Shown` | `show-<part>` | `isCounterShown` → `show-counter` |
| User permission | `is<Subject>Allowed` | `allow-<subject>` | `isAddNewAllowed` → `allow-add-new` |
| Behaviour modifier of an existing interaction | `should<Behaviour>` | `<behaviour>` | `shouldCloseOnSelect` → `close-on-select`, `shouldExpandAsAccordion` → `expand-as-accordion` |
| Layout / appearance variant | `is<Adjective>` | `<adjective>` | `isStriped` → `striped`, `isFilesInside` → `files-inside` |
| Data hint / state | `is<Adjective>` | `<adjective>` | `isSorted` → `sorted`, `isLoading` → `loading` |
| HTML-native form state | `isDisabled` / `isReadonly` / `isMultiple` | `disabled` / `readonly` / `multiple` | — |

**Canonical (D-NC-28, 2026-10-28).** Decide the kind by meaning, then derive mechanically:
"does it turn a capability on?" → `enable-*` (even if an `-able` adjective reads naturally —
`filterable`/`pageable`/`editable` are **wrong**, use `enable-filtering`/`enable-paging`/`enable-editing`);
"does it show a part?" → `show-*`; "does it permit the user something?" → `allow-*`;
"does it change how an existing interaction behaves?" → `should*`; only a pure look/layout
variant or a data hint/state stays a bare adjective.

- Visibility is always `is*Shown` — never `is*Visible` or `shouldShow*`
  for a config flag. (`isVisible` stays the *state* name for show/hide
  surfaces and action items — see "Verb glossary".)
- **Same concept = same attribute (and key) in every component.**
  `isVirtualScrollEnabled` / `enable-virtual-scroll` in grid, treeview
  and multiselect alike; `show-checkboxes` is `isCheckboxesShown`
  everywhere.
- Every boolean config key carries a prefix — no bare `disabled`,
  `deferRender`, `treeDataSorted`
  (→ `isDisabled`, `defer` (core), `isTreeDataSorted`).
- **Motion is CSS, never an attribute** (2026-10-28): no `enable-transition(s)` /
  `enable-animation`; durations chain to `--base-duration-*`, and
  `prefers-reduced-motion` sets them to `0s`.

### Boolean attribute semantics

Two patterns, both valid. Pick per-attribute, record in the
`ATTRIBUTE_TABLE`:

| Pattern | Missing | Empty (`<el flag>`) | `flag="true"` | `flag="false"` | Other |
|---------|---------|---------------------|---------------|----------------|-------|
| `bool-default-true` | true | true | true | **false** | true |
| `bool-default-false` | false | true | true | false | true |

- `bool-default-true` matches "feature on by default; turn off with
  `flag='false'`" — friendlier for opinionated defaults.
- `bool-default-false` matches the HTML spec (presence = true).

Document each component's choices per-attribute in the README's
"Attributes" section, **or** rely on the `ATTRIBUTE_TABLE` row's
`parser` field as the single source of truth.

### `disabled` and `readonly` (D-NC-16)

Every **form-participating** component has both, with the native
meanings:

| Key / attribute | Interaction | Focusable, selectable, copyable | Submitted with the form |
|-----------------|-------------|---------------------------------|-------------------------|
| `isDisabled` / `disabled` | none | no | **no** |
| `isReadonly` / `readonly` | value can't change | yes | **yes** |

- `<fieldset disabled>` is handled **once, in core `BlissElement`**:
  `formDisabledCallback` is merged into the effective `isDisabled`.
  Components don't wire it themselves.
- Never express these as a mode value (`mode: 'read-only'`) — they are
  the two booleans above.
- An "off" value in an enum is `'none'`, never `'disabled'`
  (`cellSelectionMode: 'none'`), so "disabled" keeps one meaning.

### Form field name

The form field name is `name` (key and attribute) in every component —
never `formFieldId` / `formFieldName`. See also "Small rules".

---

## The consumer-function hierarchy

The Keenmate libraries use **six distinct shapes** for functions —
four consumer-facing, two internal. The primary seam is **not** the host
framework — it's a single semantic question:

> **Does the component use the function's return value?**
>
> - **No — the return is ignored (fire-and-forget).** The function is an
>   **event**: the component announces that something happened and walks
>   away. Name it `on*`.
> - **Yes — the component consumes what the function returns.** The
>   function is a **callback**: the component asks a question and uses the
>   answer to drive its own state or behavior. Name it from the
>   `*Callback` family.

The `Callback` suffix means *"I call you back for an answer and use it."*
A function whose return value is discarded is an **event**, never a
`*Callback` — no matter where it lives. A web-component config field that
just notifies (`onSelect`) is an event wearing a config-field surface,
not a callback; this is the distinction the older "config notifications
end in `*Callback`" rule erased.

**`on*` is reserved for event twins** (D-NC-26, 2026-10-27). `on<Name>`
exists only as the twin of an event the component actually emits
(`onRowChange` ⇔ `'row-change'`), or as a Svelte component's event prop
(the Svelte form of the same event). A function in a plain **options
bag** that has no event behind it — core helper options such as
`/positioning`'s — never takes `on*`:

- its return value is used → `before*Callback`
  (`onBeforeCompute` → `beforeComputeCallback`,
  `onBeforeShow` → `beforeShowCallback`);
- it only notifies → plain `*Callback` named after what happened
  (`onPlaced` → `placedCallback`, `onDrift` → `driftCallback`).

This is the **one** place a notification wears the `Callback` suffix: an
options-bag hook with no event surface. Anything a component emits as
an event stays `on*` + `CustomEvent`.

| Shape | Suffix / pattern | Return used? | Where it lives | Examples |
|-------|------------------|--------------|----------------|----------|
| Event / notification | `on*` (field) and/or bare `CustomEvent` (DOM) | **No** — fire-and-forget | Svelte prop, JS config field, custom-element DOM | `onSelect`, `onChange`, `onClick`; `'select'` / `'change'` `CustomEvent`s |
| Interceptor | `before*Callback` | **Yes** — `false` cancels, nothing continues, a replacement continues with that; may be async | Config / Svelte prop | `beforeDropCallback`, `beforeCheckboxToggleCallback`, `beforeActionCallback` |
| Data extractor | `get*Callback` (+ `*Member`) | **Yes** — the value | Config / Svelte prop | `getDisplayValueCallback`, `getIsExpandedCallback` |
| Behavior provider | plain `*Callback` | **Yes** — the behavior result (a content provider may write it into the element it's given) | Config / Svelte prop | `sortCallback`, `renderOptionContentCallback`, `renderNodeCallback` (fills `ctx.containerElement`), `customStylesCallback` |
| Internal DOM event handler | `handle*` | n/a (internal method) | Private method on Logic class | `handleKeydown(e)`, `handleClickOutside(e)` |
| Stored reference (consumer fn OR DOM listener) | `*Handler` | n/a (held for later) | Field on Logic class | `onSelectHandler`, `documentKeydownHandler` |

### The choice falls out of one question, then a refinement

**Q1 — does the component use the return value?**

- **No** → it's an **event**. Name it `on*`; pick the surface in Q2.
- **Yes** → it's a **callback**. Pick the kind by *what* it returns:
  - "Let me cancel/modify before X happens" (returns `false` / modified
    args) → `before*Callback`
  - "Tell me the value of Y for this item" (returns the value) →
    `get*Callback` (paired with a `*Member` string field for the
    property-name shortcut)
  - "Use this function instead of my default behavior" (returns the
    behavior result) → plain `*Callback`

**Filling an element counts as a used result.** A content provider may
hand back its result by writing into an element the component passes it
instead of returning markup (`renderNodeCallback` filling
`ctx.containerElement`). The component then shows what was written, so
the function is a behavior provider (plain `render*Callback`) even when
it's typed `=> void`. It's an event only
if the component ignores what it wrote.

The three `*Callback` shapes are the **only** place the `Callback` suffix
appears on a component, regardless of host framework (plus the
options-bag notification exception above).

**One argument, always `ctx`.** Every callback and every event handler
receives a single context object — never positional arguments
(`(option, selectedOptions)`, `(row, rowIndex)`, `(multiselect, ctx)`,
a comparator's `(a, b)` → `({ a, b })`). Fields can then be added
without breaking anyone, and every surface reads the same way:
`({ row, controller }) => …`. This applies to **Svelte components too**
(svelte-treeview's positional callbacks and transforms migrate to one
`ctx`; D-NC-21).

**The `before*Callback` contract.** One `ctx`; may return a `Promise`.
The return value decides:

| Returns | Meaning |
|---------|---------|
| `false` | Cancel the action. |
| nothing (`undefined`) | Continue unchanged. |
| a replacement value | Continue with that value (e.g. treeview's `beforeCopyCallback` returning a narrowed list of paths). |

While an async interceptor is pending, the triggering control is busy —
a second click is ignored, so the action can't run twice.

**Exception — synchronous interceptors.** When the triggering native
event needs its answer immediately, the interceptor is **sync** and
documents it: `beforeDragStartCallback` (the browser reads
`dataTransfer` before `dragstart` returns), `beforeKeydownCallback` (a
key's default action can only be prevented synchronously). A returned
`Promise` there is a usage error — warn and continue. The return
contract is unchanged (`false` cancels, nothing continues, a value
replaces), so keydown interceptors return `false` to suppress the
built-in handling — never `true` = "handled".

**Per-value transforms are `get*Callback`, not `before*`.** A function
called once per value that returns the value to use — and can't cancel
anything — is a data extractor named after what it produces and when:
`getCopyValueCallback({ value, row, column })` (cell → clipboard text),
`getPasteValueCallback({ text, row, column })` (clipboard text → cell
value). The `before*` prefix promises "can cancel the operation"; a
per-cell formatter can't.

**Q2 — for events only — what's the subscription surface?**

The event's *field* name is `on*` wherever it appears. The surface only
decides which fields exist and whether a `CustomEvent` also fires:

- Svelte component prop → `on*` prop (e.g. `onSelect`).
- Plain JS config object → `on*` field (e.g. `onSelect`).
- Custom-element DOM API → dispatch a bare `CustomEvent` (`'select'`)
  that consumers subscribe to with `addEventListener('select', …)`.

A web-component typically exposes both an `on*` config field **and** the
bare `CustomEvent` (see "Parallel APIs" below). The host framework
changes *where the field lives and whether a `CustomEvent` also fires* —
it never turns an event into a callback.

### The `*Member` + `get*Callback` pair

For data extractors that read a property off an item, Keenmate
provides both forms:

```typescript
// String shortcut (member-name lookup)
displayValueMember?: string;          // "label", "name", "title", …

// Function form (for computed values)
getDisplayValueCallback?: (ctx: { option: T }) => string;
```

The component checks `displayValueMember` first (cheaper, common
case), then `getDisplayValueCallback`. The pair is symmetric; both
target the same data, just different access shapes.

**Same stem, always** (D-NC-21): `<xxx>Member` ↔ `get<Xxx>Callback`.
Boolean members keep the `is*` prefix of the value they read, so the
stems still match: `isDisabledMember` ↔ `getIsDisabledCallback`,
`isLockedMember` ↔ `getIsLockedCallback` — never `disabledMember` /
`lockedMember` next to `getIsDisabledCallback`. The *default* member
value may still be the bare data-model field (`isDisabledMember`
defaults to `'disabled'`, per the data-model exception).

### The "parallel APIs" pattern for web-components

A web-component often exposes the **same** event two ways:

```typescript
// Inside the Logic class, after the user picks an option:
const detail = { option, controller, element: this.element };
this.config.onSelect?.(detail);                // config field (if provided)
this.element.dispatchEvent(                    // DOM event (always) — same object
    new CustomEvent('select', { detail, bubbles: true })
);
```

Both fire. The JS consumer who holds the instance picks the `onSelect`
config field; the declarative HTML / Svelte / React consumer subscribes
to the `'select'` `CustomEvent`. Both are fire-and-forget — neither
return value is read, which is exactly why both wear the `on*` /
bare-event spelling rather than `*Callback`.

Svelte components don't need this duality — they expose `onSelect` as a
Svelte prop and the framework handles subscription. No `CustomEvent` is
dispatched.

Components built on `@keenmate/web-components-core` don't hand-write the
pair: declare the event in `static events` and `this.emit('select',
detail)` adds the component context, calls the element's `onSelect`
twin with the detail and dispatches `'select'` with the **same object**,
so the two surfaces can't drift. An event that should have no twin
declares `property: false`.

---

## Contexts and the controller

Every `ctx` handed to a callback and every event `detail` extends one
base from core:

| Field | Present on | Meaning |
|-------|------------|---------|
| `controller` | every component | The **public facade**: a curated, typed set of methods to read and drive the component (`clearSelection()`, `open()`, `showMessage()`). |
| `element` | every component | The host element — the escape hatch for anything the controller doesn't cover. |
| `presentation`, `isFullscreen`, `isModal` | components that present a popup (multiselect, daterangepicker, command palette) | How it's shown right now. Inline-only components (grid, treeview) don't add them. |

A surface adds its own fields on top (`row`, `rowIndex`, `node`,
`column`, `date`…) — flat, not nested: `({ row, controller }) => …`.

**ctx / detail nouns** (D-NC-20):

- **`item` is reserved for the `ActionItem`** (core `/actions` — the
  clicked button / menu entry). Everything else uses the **domain noun**:
  `option`, `row`, `node`, `file`, `command`, `date`, `column`.
- **Never a bare `index`** — qualify it with the noun: `optionIndex`,
  `rowIndex`, `fileIndex` (and `filteredIndex` / `sourceIndex` where
  the list matters).
- **Old / new pairs are always `old*` / `new*`**: `oldValue` /
  `newValue`, `oldStatus` / `newStatus`, `oldRowIndex` — never
  `prev*` / `next*` / `previous*`.
- Search text is always **`term`** — in every ctx and method argument
  (`search(term)`, `openWith(term)`); never `searchTerm` and `term`
  side by side, `query`, or `text`.

This applies to **every** event, `ready` and data events included — no
judging which events are "interactions". On an event detail,
`controller` and `element` are non-enumerable: `const { controller } =
e.detail` works, `JSON.stringify(e.detail)` gives only the data. The
presentation fields are plain data and stay enumerable.

**`controller` is reserved for the public facade.** An internal state
engine is named `*Engine` (`TreeEngine`), never `*Controller` — one
word, one meaning across the suite. A component may add a
component-specific escape hatch next to `element` (daterangepicker's
`picker`), but never instead of it.

Shared controller methods use one signature everywhere: `open()` /
`close()` / `toggle()` / `isOpen` where the component opens, and
`showMessage(content, { variant, autoHideMs })` / `hideMessage()` (see
"Messages and loaders").

### State is a property, not a `get*()` (D-NC-14)

- **Real state** (the selection, the files, the expanded paths, the
  value) is a **same-named property on the element and on the
  controller**: `el.selectedRows` ↔ `controller.selectedRows`. Where the
  element property is writable, the controller's is a **read-only**
  getter.
- **`get*()` methods only** for (a) lookups that take an argument
  (`getNode(path)`, `getRowById(id)`) and (b) computed snapshots that
  build a new object each call. Never `getSelected()` next to a
  `selected` property.
- **No `set*()` duplicates** of a settable property (`setCommands(list)`
  next to `commands`, `setExpandedPaths()` next to `expandedPaths`) —
  assign the property.
- The same name on both surfaces must return the **same data**
  (element `selectedRows` and controller `getSelectedRows()` returning
  different shapes is the anti-pattern this rule removes).

---

## Action items (buttons, toolbars, menus)

Every clickable item a consumer configures — action buttons, row
toolbars, context menus, header menus — is an **`ActionItem`** from
`@keenmate/web-components-core/actions`, whatever the component calls
the list. One model, the multiselect / daterangepicker `ActionButton`
pattern:

```typescript
{
  action: 'custom',              // a built-in name, or 'custom'
  id: 'archive',                 // identifies a custom item
  text: 'Archive', icon: '📦', tooltip: '…', shortcut: 'Ctrl+A', cssClass: '…',
  isVisible: true, isDisabled: false, isDanger: false,          // static
  isToggled: false,              // toggle state (ON), not disabled
  getIsVisibleCallback: ({ row }) => row.status !== 'archived', // dynamic
  // also: getIsDisabledCallback, getIsToggledCallback, getTextCallback,
  //       getIconCallback, getTooltipCallback, getClassCallback
  onClick: ({ row, controller }) => { /* … */ },
}
```

Rules:

1. **Static field + separate `get*Callback`** for the dynamic version.
   Never a `boolean | (ctx) => boolean` union, never a static-only
   item. The callback wins when both are set.
2. **Action items are config, not data-model items** — booleans take
   the `is*` prefix (`isVisible`, `isDisabled`, `isDanger`), not the
   bare HTML names of the data-model exception. No `hidden`, no
   `danger`.
3. **`action` is reserved for built-ins.** A custom item is
   `action: 'custom'` and is identified by `id`. A future built-in can
   then never take over a consumer's item.
4. **String shorthand** for built-ins: `['add', 'delete']` ≡
   `[{ action: 'add' }, { action: 'delete' }]`.
5. **Dividers are their own entry**, `{ divider: true, text? }` (core's
   `menuDivider(text?)`) — never a flag on an item (`dividerBefore`) or
   a group number.
6. **Children:** static `children`, or `getChildrenCallback(ctx)`
   returning entries or a `Promise` of them (lazy submenu). Any depth.
7. **The context belongs to the surface:** built when the menu or
   toolbar opens for that row / node, and passed to every callback and
   to `onClick`.
8. **One `'action'` event** (`onAction`) per component, for every
   clicked item, built-in or custom. Order: `beforeActionCallback(ctx)`
   (can cancel everything — the `before*` contract above) → the item's
   `onClick` → the built-in behaviour → `'action'`. The event is a
   notification after the fact: a listener sees the state the built-in
   left (a deleted row is gone, an added row is present); a throwing
   built-in is logged and the event still fires. Detail fields:
   `action`, `id`, `item`, `source` (which surface: `'row-toolbar'`,
   `'context-menu'`, …), `sourceEvent`, `triggerElement`, `dataset` (the
   button's `data-*`), plus the context. These names are reserved — a
   surface context can't redeclare them.
9. **`isToggled` is toggle state, not availability.** `isDisabled` =
   greyed out, can't click; `isToggled` = the thing it toggles is ON
   (Bold while the caret is in bold text, "Show hidden" checked,
   "Freeze column" on a frozen column) — still clickable, plus a
   `--toggled` modifier class. A button renders `aria-pressed`; a menu
   item that defines `isToggled` / `getIsToggledCallback` is a toggle:
   `role="menuitemcheckbox"` + `aria-checked="true|false"`. Never
   `isActive` (ambiguous with focus / the active cell).
10. **`data-action` / `data-id` are reserved for action items.** HTML a
    consumer writes (a `showMessage` body, a custom renderer) becomes a
    clickable action with `data-action="custom" data-id="…"` (its other
    `data-*` arrive as `dataset`). The component's own internal
    controls (remove ✕, nav arrows, "add new") use a prefixed attribute
    (`data-ms-action`, `data-drp-action`), so consumer markup can never
    trigger them by accident and vice versa.
11. **Field names are core's**, in every component and in Svelte
    components too: `text` (not `label`), `onClick` (not `onclick`),
    `cssClass` (not `className`). A component-local menu-item type
    (svelte-treeview's `ContextMenuItem { label, onclick, className }`)
    migrates to them.

---

## Boolean predicates — properties vs verbs

**Property-style predicates** (boolean fields, getters):
- `is*` — current state. `isOpen`, `isDisabled`, `isValid`.
- `has*` — possession. `hasItems`, `hasPermission`.
- `can*` — capability. `canSubmit`, `canEdit`.
- `should*` — policy / configuration. `shouldKeepSearchOnClose`.

**Verb-style predicates** (methods that compute a verdict on demand):
- `check*` — see Bliss general guidelines. `checkValidity()`,
  `checkOverflow()`.

Don't mix: `isCheckValid` is wrong. Don't shadow a field with a method
of the same root (`isFoo` field **and** `isFoo()` method).

**Data-model exception — follow HTML / DOM convention.** The prefix
rule applies to **Config / Props** booleans (fields that control *the
component*). It does **not** apply to **data-model** interfaces
(`MultiSelectOption`, `LTreeNode`, `GridRow`, etc. — shapes describing
*one item*). Data-model booleans use bare `disabled`, `selected`,
`checked`, `hidden`, `required`, `readonly`, `visible`, `expanded` to
match HTML. The reference implementation (`MultiSelectOption.disabled`
in `@keenmate/web-multiselect`) was originally `isDisabled` and
renamed to `disabled` to align with HTML's `<option disabled>`.
**Action items (buttons, toolbars, menu items) are config, not data
model** — they control the component's own UI and take the `is*`
prefix (`isVisible`, `isDisabled`, `isDanger`).

---

## Verbs (Bliss registry plus JS additions)

The shared Bliss verb registry applies in full: `Create`, `Update`,
`Delete`, `Get`, `Search`, `Process`, `Map`, `Check`, `Generate`,
`Parse`, `(Bulk)Copy`, `Send`, plus the `Check` / `Validate` / `Verify`
/ `Is/Has/Can/Should` / `Ensure` family. See the public manifesto's
[general naming conventions](https://blissframework.dev/coding-guidelines/general-naming-conventions/).

Additional verbs for DOM / UI work:

| Verb | Means | Example |
|------|-------|---------|
| `render` | Build markup for a region | `renderDropdown()`, `renderBadges()` |
| `handle` | Internal DOM event handler method | `handleKeydown(e)` |
| `dispatch` | Emit a `CustomEvent` to the host | `dispatchSelect()` |
| `attach` / `detach` | Wire up / tear down listeners or DOM | `attachEvents()`, `attachBadgeTooltips()` |
| `mount` / `unmount` | Internal lifecycle entry / exit of a region or sub-part | `mount()`, `unmount()` |
| `observe` | Subscribe to a Mutation/Resize/Intersection observer | `observeResize()` |
| `compute` | Derive a value with no side effects | `computePosition()` |
| `position` / `anchor` | Place a floating panel | `positionDropdown()`, `anchorFloatingPanel()` |
| `open` / `close` | A surface you work in (see glossary) | `open()`, `close()` |
| `show` / `hide` | Display-only region (see glossary) | `showMessage()`, `hideLoader()` |
| `toggle` | Flip boolean state | `toggle()`, `toggleNodeExpanded(path)` |
| `focus` / `blur` | Programmatic focus / move the cursor | `focusNext()`, `focusFirst()` |
| `commit` | Write a staged value into the real value (see glossary) | `commit()` |
| `reconcile` | Sync derived state to source | `reconcileSelectedOptions()` |
| `register` / `define` | Custom-element registration | `customElements.define(...)` |
| `destroy` | Final public teardown — the only teardown verb | `destroy()` |

When unsure, pick the verb that already exists elsewhere in the package
or in a sibling component. **Restrain yourself.**

### Verb glossary — public API (D-NC-13)

Every public method, action id, event verb and ctx field across the
suite uses these meanings. Two verbs in the same row group are **not**
synonyms — pick by meaning.

**Surfaces**

| Verb | Means | State | Examples |
|------|-------|-------|----------|
| `open` / `close` / `toggle` | A surface **you work in**: takes focus, is dismissable | `isOpen` | dropdown, calendar, menu, dialog, palette, cell editor; `openGoToRowDialog()` |
| `show` / `hide` | **Display only**: no focus, no dismissal | `isVisible` | message, loader, summary, tooltip; `showMessage()`, `hideLoader()` |

**Choosing and pointing**

| Verb | Means | Never for |
|------|-------|-----------|
| `select` / `deselect` | The **chosen** set (value / UI selection); `clearSelection()` empties it | checkboxes that are a separate set |
| `check` / `uncheck` | **Checkbox** state — only where it is distinct from selection (treeview) | plain selection |
| `focus` | The keyboard / virtual **cursor** (the "active" cell / node / option) — `isFocused`, `select-focused` | emphasis |
| `highlight` | **Visual emphasis only** (search-match marks, scroll flash) | selection or cursor — ever |

**Collections**

| Verb | Means |
|------|-------|
| `add` | Put into the collection; the **component picks the position** |
| `insert` | Put at an **explicit position** / anchor (`insertRow(row, { after })`) |
| `create` | **Factory** — build a new data object, never inserts (`createRowCallback`) |
| `remove` | Local, **programmatic** removal (client only, no veto) |
| `delete` | The **user's destructive command** — action id `delete`, Del key, vetoable via `before*Callback`, may hit the server; `<domain>-delete` fires after it happened |
| `clear` | **Empty a set** — "remove all" (`clearSelection()`, `clearSearch()`) |
| `reset` | Restore the **initial / default** state |
| `discard` | Throw away **unsaved edits / drafts** (`discardDraft()`) |
| `update` | **Patch** — apply a partial |
| `replace` | Swap the **whole** thing |
| `move` | Relocate a **data item** (row, node) |
| `reorder` | Change order by **UI gesture** (columns; `isReorderable`) |
| `drag` / `drop` | The **gesture events only** (`node-drop`), never the data operation |

**Operations**

| Verb | Means |
|------|-------|
| `cancel` | Stop a **running operation** or a pending mode (upload, edit, cut) |
| `abort` | **Only** the platform `AbortSignal` (`signal` in ctx) |
| `dismiss` | **Internal** close reason — an overlay closed without a choice |
| `commit` | Write a **staged** edit / selection into the value (method and config: `commit()`, `commitMode`) |
| `apply` | **Only** a button label / action id that triggers `commit` — never a method name |
| `refresh` | **Sync** re-render from current data, no fetch |
| `reload` | **Async** re-fetch from the source → returns a `Promise` |
| `search` | Find and **navigate / highlight** — non-matching items stay |
| `filter` | **Hide** non-matching items |
| `destroy` | Final teardown. **The only teardown verb**; every element exposes `destroy()` (no `dispose`, `teardown`, `cleanup`) |
| `scrollTo<Thing>` | Scroll a thing into view → **`Promise<boolean>`** (resolves `false` when not found): `scrollToRow(rowIndex)`, `scrollToPath(path)` |

Search text is always **`term`** (`search(term)`, `({ term }) => …`).

### Async vs sync

- `get*` — synchronous retrieval.
- `fetch*` — asynchronous retrieval over a network or async API.
- `load*` — async retrieval where "fetch" feels wrong (lazy import,
  cache).
- `save*` — async write.

Don't suffix functions with `Async` — the return type already says
`Promise<T>`.

---

## Counts, limits and sizes (D-NC-22)

- Limits: `max*` / `min*` + **singular noun** + `Count`:
  `maxFileCount`, `maxVisibleBadgeCount`, `maxRecentCount` — not
  `badgesMaxVisible`, `recentLimit`, `maxVisibleFiles`.
- A plain quantity is `<singular>Count` (`visibleMonthCount`).
- `*Size` only for **bytes**, **pixels** and `pageSize`
  (`maxFileSize`, `iconSize`).
- Virtual scrolling is one family, `virtualScroll*`:
  `isVirtualScrollEnabled`, `virtualScrollItemHeight`,
  `virtualScrollOverscan` — not `optionHeight`, `virtualRowHeight`,
  `virtualScrollBuffer`, `virtualOverscan`.

---

## Messages and loaders (D-NC-23)

One signature in every component that shows an inline message:

```typescript
type MessageVariant = 'info' | 'success' | 'warning' | 'danger';
showMessage(content: string, opts?: { variant?: MessageVariant; autoHideMs?: number }): void;
hideMessage(): void;
isMessageShown: boolean;   // read-only state
showLoader(): void;
hideLoader(): void;
```

- Options object, never positional (`showMessage(content, variant,
  autoHide)`).
- **The kind of message is its `variant`, and the values are the status
  roles of the `--base-*` contract** (`--base-<role>-color`): `info`,
  `success`, `warning`, `danger` — `danger`, not `error`. It is the same
  word and the same values as pure-admin's toasts
  (`pureAdmin.toast.show({ variant: 'warning' })`, `.pa-toast--danger`), so
  a message, its CSS modifier (`.<prefix>__message--danger`) and its
  variables (`--<prefix>-message-danger-bg`) line up with the colours they
  read. The type is `MessageVariant` — not `MessageType` (C-NC-11) or
  `MessageSeverity`.
- **No toggle methods** (`toggleMessage`, `toggleLoader`) — show/hide
  are explicit.
- Messages and loaders are display-only → `show` / `hide`, never
  `open` / `close` (internal action ids too: `hide-message`).

---

## Labels and i18n (D-NC-24)

- **One `labels` property per component** — a *partial* object of
  UI strings with `{name}` placeholders (`'{count} selected'`). It is
  also accepted as a JSON attribute (`labels='{"empty":"Nothing"}'`).
- **Built-in strings are English only.** No built-in language tables
  inside a component.
- **Page-wide** strings come from core `/locale`:
  `window.components.locale = { locale: 'cs-CZ', labels: { 'web-multiselect': { noData: 'Nic' } } }`.
- **Per-key merge, most specific wins**: instance `labels` → page
  `window.components.locale.labels['<tag>']` → built-in English.
- **No per-string attributes** (`empty-text`, `no-data-text`,
  `placeholder-text`) and no `customStrings` / `*Text` config keys —
  every UI string is a `labels` key.
- Months, weekdays, numbers and dates are formatted via `Intl`
  using the resolved `locale`, never hard-coded.
- **Empty states (2026-10-28):** `noData` = nothing exists at all; `noResults` =
  data exists but a search/filter matched nothing. There is no `empty` key.
- **Progress:** `searching` = a user-typed search in flight; `loading` = data loading.
- **`''` is a value:** `''` = deliberately empty (render nothing); missing/`undefined`
  = the default.
- **Ellipsis** is the single `…` character in every default.
- **HTML:** content labels may contain HTML (inserted as-is — the app maker's
  responsibility, listed in the README XSS table); attribute labels (`aria-label`,
  `title`, `placeholder`) are text. Interpolated `{param}` values are data and are
  always escaped. Page-wide `window.components.security.shouldEscapeLabels` (core)
  escapes labels too.
- **Formatting extension:** `window.components.locale.formatLabelCallback(ctx)`
  (core) replaces the default `{name}` interpolation — ICU MessageFormat, i18next.
- **Lookups** are `get<Noun>By<Key>(key) → object | null` (`getNodeByPath`,
  `getRowById`, `getFileById`, `getOptionByValue`); no `find*`.

---

## Ready, defer and destroy (D-NC-19)

Provided by core `BlissElement` for **every** component — components
don't re-implement them:

| Surface | Meaning |
|---------|---------|
| `defer` (attribute + property) | Hold the first render. |
| `release()` — or removing `defer` | Build once, now. |
| `ready` event | Fired once after the first build. |
| `:state(ready)` + `ready` host attribute | Styling / selector hooks after the first build (not `is-ready`, not `data-ready`). |
| `whenReady(): Promise<void>` | Await the first build. |
| `destroy()` | Final teardown; every element exposes it. |

Not: `deferRender`, `ready()` as a method, `isReady` + `is-ready`
attribute variants.

---

## Small rules (D-NC-27)

- **Form field name** is `name` everywhere (never `formFieldId` /
  `formFieldName`).
- **`multiple`**, never `multi` (`selectionMode: 'multiple'`).
- **No bare `mode`** — qualify by meaning: `preset`, `layoutMode`,
  `editMode`, `commitMode`.
- The **root CSS part** is always `container` (`::part(container)`),
  never `root`.
- Menu / action items use core's `{ text, onClick, cssClass }` (see
  "Action items" rule 11).
- Class-name options are **`cssClass`**, never `className` (core
  `OpenMenuOptions` included).
- Shared UI rendered by `@keenmate/web-components-core` (menu, future
  tooltip …) uses the **`km-`** prefix for classes and variables
  (D-NC-17) — see
  [base-variables.md](./base-variables.md) → prefix registry.

---

## CSS class naming (cross-link)

Every CSS class emitted by the component carries the component's
**prefix** and follows BEM with two underscore levels max:

```
.<prefix>__element--modifier
```

Reserved prefixes (registry in `base-variables.md`):
`ms` (multiselect), `wg` (web-grid), `drp` (date-range-picker),
`wp` (web-player), `wtv` (web-treeview), `stv` (svelte-treeview),
`sw` (svelte-switch), `km` (shared UI rendered by
`@keenmate/web-components-core` — never used by a component's own
classes).

`.<prefix>__element__sub-element` is **forbidden** — promote the
sub-element to its own BEM block.

The canonical rules and rationale live in
[css-structure.md](./css-structure.md). This guideline only enforces
that the prefix-with-BEM shape is followed.

---

## TypeScript-specific notes

- Generic type parameters: single uppercase letter when the role is
  obvious (`T` for the item type, `K`/`V` for key/value); descriptive
  name otherwise (`TItem`, `TResponse`).
- Discriminated-union tags: lowercase string literals
  (`{ kind: 'success', data }`), not numeric or PascalCase.
- Branded types: reserve for cases where mixing two IDs would be a
  real bug. Don't apply to every string.
- No `I`-prefixed interfaces. The Bliss [Use only what you
  need](https://blissframework.dev/learning-guidelines/basic-principles/#use-only-what-you-need)
  rule covers this.

---

## Vocabulary collisions to watch for

| Word | Possible meanings | Disambiguation |
|------|-------------------|----------------|
| `options` | Config options vs selectable items | Reserve `options` for selectable items (matches `<option>`); use `config` for the component's settings |
| `value` | DOM `value` property vs domain "value" of a selected item | Prefix the domain meaning: `selectedValue`, `itemValue`, `formValue`. Bare `value` = DOM concept |
| `target` | `event.target` vs Floating-UI reference element vs action target | Use `event.target` literally; rename others — `referenceElement`, `floatingElement`, `triggerElement` (no abbreviations) |
| `data` | `event.detail.data` vs `dataset.foo` vs domain payload | Avoid bare `data`; use `payload`, `items`, `detail` — and `dataset` for an element's `data-*` map |
| `controller` | Public facade vs internal state engine | `controller` = the public facade in `ctx` / `detail` only; internal state is `*Engine` |
| `action` | Built-in action name vs the consumer's own item | `action` = a built-in name or `'custom'`; a custom item's identity is `id` |
| `name` | HTML `name` attribute (form field) vs human-readable label vs domain name | The form-field meaning takes `name`; use `label` or `displayName` for others |
| `key` | `event.key` vs object key vs domain id | Keep `key` for keyboard events; use `id` or `itemId` for object identity |
| `index` | Filtered-list index vs source-list index vs DOM-position index vs which list | Never bare: qualify with the noun (`optionIndex`, `rowIndex`, `fileIndex`) and the list where it matters (`filteredIndex`, `sourceIndex`, `domIndex`) |
| `item` | The clicked `ActionItem` vs a data row / option / node | `item` = the `ActionItem` only (core `/actions`); data uses its domain noun (`option`, `row`, `node`, `file`, `command`, `date`) |
| `mode` | Selection mode vs edit mode vs layout vs preset | Never bare: `selectionMode`, `editMode`, `layoutMode`, `commitMode`, or a domain word (`preset`) |
| `highlight` / `active` | Visual emphasis vs selection vs cursor | `highlight` = visual emphasis only; selection = `select*`; cursor = `focus*` (`isFocused`, never `isActive` / `isHighlighted` for the cursor) |

When the collision is unavoidable, **prefix the domain meaning, leave
the DOM meaning bare** — the DOM word is what consumers read most
often in surrounding code.

---

## Anti-patterns

| Pattern | Why | Use instead |
|---------|-----|-------------|
| `onSelect`, `selectEvent`, `select-event` as a `CustomEvent` name | CustomEvent names follow HTML standard — bare, short | `'select'` |
| `*Callback` for an internal handler | `Callback` implies "supplied by consumer" | `handle*` for internal methods; reserve `*Callback` for config-provided functions |
| `on*` used for a function that **returns** something the component uses | `on*` implies fire-and-forget; readers skip the return value | Pick the right verb: `before*Callback` (interceptor), `get*Callback` (data), or plain `*Callback` (behavior) |
| `*Callback` for a fire-and-forget notification on a component — Svelte prop *or* JS config field (`selectCallback`, `clickCallback`) | It's an **event**, not a callback | Emit a bare `CustomEvent` with its `on*` twin (`'select'` + `onSelect`). Only an options-bag hook with no event behind it is a notification `*Callback` (`placedCallback`) |
| `on*` on an options-bag hook with no event behind it (`onBeforeCompute`, `onPlaced`, `onDrift`) | `on*` is reserved for event twins | `beforeComputeCallback` (return used), `placedCallback` / `driftCallback` (notification) |
| `WebMultiSelect` and `MultiSelectElement` and `MultiSelect` used interchangeably | Vocabulary drift | Settle on the trio: `WebMultiSelect` (Logic) + `MultiSelectElement` (Element) + `<web-multiselect>` (tag) |
| Bare `options` for both config and items | Vocabulary collision | `config` for settings, `options` (or `items`) for selectable list |
| Inventing a new lifecycle verb (`setup`, `boot`, `start`, `wakeup`, `dispose`, `teardown`, `cleanup`) | Vocabulary sprawl | Use the registry: `connect`, `mount`, `attach`, `register`; public teardown is always `destroy()` |
| `validate*` for read-only inspection | Wrong verb | `check*` |
| `check*` that throws on bad input from outside the trust boundary | Wrong verb | `validate*` |
| Magic strings inline in source (event names, attribute names, log categories) | DRY violation | Top-of-file constant table (`ATTRIBUTE_TABLE`, `LOGGING_CATEGORIES`) |
| `IMultiSelect` interface with one implementation | Premature abstraction; Bliss anti-pattern | Drop the interface |
| Past-tense or prefixed event names (`'node-clicked'`, `'cp-select'`) | Platform events are present tense; the host already identifies the component | `'node-click'`, `'select'` |
| A component event named like a composed native (`'copy'`, `'input'`, `'focus'`) | Listeners get the browser's event *and* the component's | Prefix the domain: `'node-copy'`, `'cell-input'` |
| Lowercase `on*` properties (`onrowchange`) | Inconsistent with every other config key | `onRowChange` |
| Positional callback arguments (`(row, rowIndex)`, `(option, selected)`, `(multiselect, ctx)`) | Can't grow without breaking; every surface reads differently | One `ctx` object |
| `boolean \| (ctx) => boolean` union fields on items (`disabled: (row) => …`) | Two shapes in one field; no `*Callback` to discriminate | `isDisabled` + `getIsDisabledCallback` |
| `dividerBefore`, group numbers on items | A layout flag on an unrelated item | A `{ divider: true }` entry |
| `before*Callback` for a per-value transform | `before*` promises "can cancel the operation" | `get<Thing>ValueCallback` |
| Keydown interceptor returning `true` = "handled" | Inverts the `before*` contract | `beforeKeydownCallback(ctx)` returning `false` |
| Lowercase `on*` props (`onpaste`, `onrowchange`) | Collide with `HTMLElement` handler properties / break the camelCase twin rule | `onPaste` → better a domain name: `onNodePaste`, `onRowChange` |
| Internal controls sharing `data-action` with consumer actions | Consumer markup with `data-action` triggers internals (and vice versa) | Prefixed internal attribute (`data-ms-action`) |
| Toggle state expressed via `isDisabled`, a CSS class or `isActive` | Disabled ≠ pressed; no `aria-pressed` / `aria-checked`; "active" is ambiguous | `isToggled` + `getIsToggledCallback` |
| `*Controller` for internal state | `controller` means the public facade | `*Engine` |
| SCREAMING_SNAKE or camelCase enum values (`'SELECT_ALL'`, `'mousePosition'`) | Values appear in HTML attributes | kebab-case: `'select-all'`, `'mouse-position'` |
| Configkey-as-attribute (`is-summary-shown`, `is-virtual-scroll-enabled`) or per-component spellings of one concept | Attributes are HTML-shaped and identical suite-wide | Mechanical derivation: `show-summary`, `enable-virtual-scroll` |
| `is*Visible` / `shouldShow*` config flags | Three spellings of "shown" | `is*Shown` |
| `'disabled'` as an "off" enum value; `mode: 'read-only'` | `disabled` / `readonly` are the two booleans | `'none'`; `isReadonly` |
| `get*()` duplicating a state property; `set*()` duplicating a settable property | Two names for one state, can drift | The same-named property on element and controller |
| `open` / `close` for a message or loader; `show` / `hide` for a dialog or dropdown | Surface vs display-only | Verb glossary |
| `highlight*` meaning selection or cursor | `highlight` is visual emphasis only | `select*` / `focus*` |
| `remove` for the user's Del-key command, `delete` for a programmatic splice | remove = local, delete = user destructive | Verb glossary |
| Two events with identical detail for one act (`select` + `change`) / `change` for non-form state | `change` is the form value | `<state>-change` |
| `disabledMember` next to `getIsDisabledCallback` | Stems must match | `isDisabledMember` |
| `badgesMaxVisible`, `recentLimit`, `virtualRowHeight` | Count / virtual-scroll families | `maxVisibleBadgeCount`, `maxRecentCount`, `virtualScrollItemHeight` |
| Per-string `*-text` attributes, `customStrings`, built-in language tables | One i18n surface | `labels` + core `/locale` |
| `prev*` / `next*` / `previous*` pairs | One old/new spelling | `old*` / `new*` |
| `className` option, `label` / `onclick` on menu items, `::part(root)` | Core's names | `cssClass`, `text` / `onClick`, `::part(container)` |

---

## Worked example pointers

- **Web-component reference:** `@keenmate/web-multiselect` —
  `<web-multiselect>` tag, `MultiSelectElement`, `WebMultiSelect<T>`,
  `ATTRIBUTE_TABLE` constant, `onSelect` event field (return ignored)
  alongside `getValueCallback` / `customStylesCallback` callbacks (return
  consumed), parallel `'select'` / `'change'` `CustomEvent`s, `ms` CSS
  prefix.
- **Svelte-component reference:** `@keenmate/svelte-treeview` —
  `<Tree>` Svelte component, `TreeController.svelte.ts`,
  `onNodeClick` / `onSelectionChange` Svelte props,
  `beforeDropCallback` / `beforeCopyCallback` interceptors,
  `getDisplayValueCallback` + `displayValueMember` data extractors,
  `sortCallback` / `initializeIndexCallback` behavior providers,
  `stv` CSS prefix.

See the public manifesto for the full per-file walkthrough:
`BlissFramework/web/docs/coding-guidelines-javascript/naming-conventions.md`
— "Worked examples" section.
