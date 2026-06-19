# Naming Conventions — Web Component / Svelte Component Guideline

How a KeenMate component library names its identifiers, files, custom-
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
> files and tags and HTML attributes, SCREAMING_SNAKE for constants.
> Custom-element tags are hyphenated and package-prefixed
> (`<web-multiselect>`). HTML attributes are kebab; internal config keys
> are camel with `is*` / `should*` for booleans. A single
> `ATTRIBUTE_TABLE` constant drives `observedAttributes`, parsing, and
> `attributeChangedCallback`. Consumer-supplied functions follow a four-
> way hierarchy: `on*` for Svelte notifications, `*Callback` for plain-JS
> config notifications, `before*Callback` for interceptors,
> `get*Callback` paired with `*Member` for data extractors, plain
> `*Callback` for behavior providers. Internal: `handle*` for methods,
> `*Handler` for stored references. CSS uses BEM with the component
> prefix on every class. `CustomEvent` names are bare and short.**

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
| Constants, enum string values, env vars | SCREAMING_SNAKE_CASE | `MAX_LOGIN_ATTEMPTS`, `LOGGING_CATEGORIES` |

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
2. Short — one or two words. Two words are hyphenated (`item-added`).
3. Match HTML standard event names where the meaning aligns:
   `'select'`, `'change'`, `'input'`, `'focus'`, `'blur'` —
   re-using these is fine and matches user expectations.
4. The detail interface is `<ComponentName>EventDetail`
   (e.g., `MultiSelectEventDetail<T>`).

Forbidden: `'onSelect'`, `'Select'`, `'selectEvent'`, `'select-event'`,
`'SELECT'` — none of these match the HTML standard for event names.

---

## HTML attribute ↔ config key mapping

Two distinct names for the same concept, kept consistent by a single
declarative table:

| Public attribute (kebab) | Internal config key (camel) | Type |
|--------------------------|-----------------------------|------|
| `multiple` | `isMultipleEnabled` | boolean |
| `show-checkboxes` | `isCheckboxesShown` | boolean |
| `close-on-select` | `isCloseOnSelect` | boolean |
| `keep-search-on-close` | `shouldKeepSearchOnClose` | boolean |
| `badges-position` | `badgesPosition` | enum |
| `max-height` | `maxHeight` | string |
| `name` | `formFieldId` | string |

Pattern:

- Attributes are short, declarative, HTML-shaped (`multiple`, not
  `is-multiple-enabled`).
- Internal config keys are longer, fully descriptive, JS-shaped
  (`isMultipleEnabled`).
- A single top-of-file `ATTRIBUTE_TABLE` constant maps the two and
  drives `observedAttributes`, initial parsing, and
  `attributeChangedCallback`. **One source of truth.**

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

---

## The consumer-callback hierarchy

The KeenMate libraries use **six distinct shapes** for functions —
four consumer-facing, two internal. Each carries information about the
role the function plays.

| Shape | Suffix / pattern | Where it lives | Returns? | Examples |
|-------|------------------|----------------|----------|----------|
| Notification (Svelte) | `on*` | Svelte component prop | `void` | `onNodeClick`, `onSelectionChange`, `onRenderStart` |
| Notification (config object) | `*Callback` | Field on JS `Config` interface | `void` | `selectCallback`, `changeCallback`, `deselectCallback` |
| Interceptor | `before*Callback` | Config / Svelte prop | `false` to cancel, modified args to override, or `void` | `beforeDropCallback`, `beforeCheckboxToggleCallback`, `beforePasteCallback` |
| Data / behavior provider | `get*Callback` or plain `*Callback` | Config / Svelte prop | The data or behavior result | `getDisplayValueCallback`, `getIsExpandedCallback`, `sortCallback`, `renderOptionContentCallback`, `customStylesCallback` |
| Internal DOM event handler | `handle*` | Private method on Logic class | `void` | `handleKeydown(e)`, `handleClickOutside(e)` |
| Stored reference (consumer callback OR DOM listener) | `*Handler` | Field on Logic class | n/a | `onNodeClickHandler`, `documentKeydownHandler` |

### The choice falls out of two questions

**Q1 — does the function need to return a value the component uses?**

- "Tell me before X happens, let me cancel/modify" → `before*Callback`
- "Tell me the value of Y for this item" → `get*Callback` (paired with
  a `*Member` string field for the property-name shortcut)
- "Use this function instead of my default behavior" → plain
  `*Callback`

If the function returns a value the component uses, the answer is
**always** one of the three `*Callback` shapes above, regardless of
host framework.

**Q2 — for fire-and-forget notifications only — where does the field
live?**

- Svelte component prop → `on*`
- Plain JS config object → `*Callback`
- Custom-element DOM surface → no field name at all; the component
  dispatches a bare `CustomEvent` and the consumer subscribes via
  `addEventListener('select', …)`.

### The `*Member` + `get*Callback` pair

For data extractors that read a property off an item, KeenMate
provides both forms:

```typescript
// String shortcut (member-name lookup)
displayValueMember?: string;          // "label", "name", "title", …

// Function form (for computed values)
getDisplayValueCallback?: (item: T) => string;
```

The component checks `displayValueMember` first (cheaper, common
case), then `getDisplayValueCallback`. The pair is symmetric; both
target the same data, just different access shapes.

### The "parallel APIs" pattern for web-components

A web-component often exposes the **same** notification two ways:

```typescript
// Inside the Logic class, after the user picks an option:
this.options.selectCallback?.(item);          // config field (if provided)
this.element.dispatchEvent(                   // DOM event (always)
    new CustomEvent('select', { detail: { item } })
);
```

Both fire. The JS consumer who holds the instance picks
`selectCallback`; the declarative HTML / Svelte / React consumer picks
the `CustomEvent`. Both work.

Svelte components don't need this duality — they expose `on*` as a
Svelte prop and the framework handles subscription.

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
| `mount` / `unmount` | Lifecycle entry / exit | `mount()`, `unmount()` |
| `observe` | Subscribe to a Mutation/Resize/Intersection observer | `observeResize()` |
| `compute` | Derive a value with no side effects | `computePosition()` |
| `position` / `anchor` | Place a floating panel | `positionDropdown()`, `anchorFloatingPanel()` |
| `open` / `close` | Logical open/closed state | `open()`, `close()` |
| `show` / `hide` | Visual visibility | `showPopover()`, `hideSelectedPopover()` |
| `toggle` | Flip boolean state | `toggleOption(item)` |
| `focus` / `blur` | Programmatic focus | `focusNext()`, `focusFirst()` |
| `commit` | Apply a batched state mutation through one funnel | `commit({ added, removed })` |
| `reconcile` | Sync derived state to source | `reconcileSelectedOptions()` |
| `register` / `define` | Custom-element registration | `customElements.define(...)` |

When unsure, pick the verb that already exists elsewhere in the package
or in a sibling component. **Restrain yourself.**

### Async vs sync

- `get*` — synchronous retrieval.
- `fetch*` — asynchronous retrieval over a network or async API.
- `load*` — async retrieval where "fetch" feels wrong (lazy import,
  cache).
- `save*` — async write.

Don't suffix functions with `Async` — the return type already says
`Promise<T>`.

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
`sw` (svelte-switch).

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
| `target` | `event.target` vs Floating-UI reference element vs action target | Use `event.target` literally; rename others — `referenceEl`, `floatingEl`, `triggerEl` |
| `data` | `event.detail.data` vs `dataset.foo` vs domain payload | Avoid bare `data`; use `payload`, `items`, `detail` |
| `name` | HTML `name` attribute (form field) vs human-readable label vs domain name | The form-field meaning takes `name`; use `label` or `displayName` for others |
| `key` | `event.key` vs object key vs domain id | Keep `key` for keyboard events; use `id` or `itemId` for object identity |
| `index` | Filtered-list index vs source-list index vs DOM-position index | Always qualify: `filteredIndex`, `sourceIndex`, `domIndex` |

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
| `*Callback` notification field on a Svelte component prop | Doesn't match Svelte 5 idiom; readers expect `on*` | Rename to `on*` for Svelte components; keep `*Callback` for plain JS config objects |
| `WebMultiSelect` and `MultiSelectElement` and `MultiSelect` used interchangeably | Vocabulary drift | Settle on the trio: `WebMultiSelect` (Logic) + `MultiSelectElement` (Element) + `<web-multiselect>` (tag) |
| Bare `options` for both config and items | Vocabulary collision | `config` for settings, `options` (or `items`) for selectable list |
| Inventing a new lifecycle verb (`setup`, `boot`, `start`, `wakeup`) | Vocabulary sprawl | Use the registry: `connect`, `mount`, `attach`, `register` |
| `validate*` for read-only inspection | Wrong verb | `check*` |
| `check*` that throws on bad input from outside the trust boundary | Wrong verb | `validate*` |
| Magic strings inline in source (event names, attribute names, log categories) | DRY violation | Top-of-file constant table (`ATTRIBUTE_TABLE`, `LOGGING_CATEGORIES`) |
| `IMultiSelect` interface with one implementation | Premature abstraction; Bliss anti-pattern | Drop the interface |

---

## Worked example pointers

- **Web-component reference:** `@keenmate/web-multiselect` —
  `<web-multiselect>` tag, `MultiSelectElement`, `WebMultiSelect<T>`,
  `ATTRIBUTE_TABLE` constant, `selectCallback` / `getValueCallback` /
  `customStylesCallback` config fields, parallel `'select'` /
  `'change'` `CustomEvent`s, `ms` CSS prefix.
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
