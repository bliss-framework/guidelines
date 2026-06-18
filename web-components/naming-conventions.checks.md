# Naming Conventions — Post-Implementation Checks

Run every check below **after** finishing or refactoring a component's
public API surface and internal identifiers, and **before** declaring
the work done.

Each check: what to look for, how to verify, what failure looks like.
Failing any check means the work is not complete. Mark each as ✅
pass, ❌ fail, ⚠️ exception (with reason), or N/A in the PR description.

Read [naming-conventions.md](./naming-conventions.md) for rationale
and [naming-conventions.decisions.md](./naming-conventions.decisions.md)
for the matching decision tags.

Each check is tagged **`[auto]`**, **`[semi]`**, or **`[manual]`** — see
[css-structure.checks.md](./css-structure.checks.md) for the meaning of
each tier.

---

## C-NC-1 — Custom-element tag is hyphenated and prefixed

**Tier:** `[auto]` (N/A for Svelte)

**What:** The custom-element tag passed to `customElements.define`
contains a hyphen and starts with the family prefix.

**How to verify:**
```bash
grep -n "customElements.define" packages/<component>/src/**.ts
```

**Pass:** The string argument matches `^[a-z]+(-[a-z]+)+$` and starts
with `web-` (or another agreed family prefix).

**Failure mode:** Single-word tag fails to register (browser rejects).
Wrong prefix means the component doesn't read as part of the family.

**Exception:** N/A for Svelte components.

**Tag:** D-NC-1.

---

## C-NC-2 — CustomEvent names are bare and short

**Tier:** `[auto]` (N/A for Svelte)

**What:** Every `new CustomEvent('name', …)` call uses a bare
lowercase name with no `on*` prefix or `Event` suffix.

**How to verify:**
```bash
grep -rEn "new CustomEvent\(['\"]" packages/<component>/src/
```

**Pass:** Every dispatched event name matches `^[a-z]+(-[a-z]+)*$`.
None starts with `on`. None ends with `Event` or `Evt`.

**Failure mode:** Non-standard event names; consumers reach for
`addEventListener('onSelect', …)` and silently miss the event.

**Exception:** N/A for Svelte components (they don't dispatch
`CustomEvent`s in the Svelte-prop world).

**Tag:** D-NC-5, D-NC-6.

---

## C-NC-3 — Boolean config fields use `is*` / `should*` prefix

**Tier:** `[auto]`

**What:** Every boolean field on the component's **public `Config` /
Svelte `Props`** interface uses the `is*`, `has*`, `can*`, or `should*`
prefix.

**Exception — data-model interfaces.** Boolean fields on interfaces
that describe **data items** the consumer passes in (e.g.,
`MultiSelectOption`, `LTreeNode`, `GridRow`) follow HTML / DOM
convention and use bare `disabled` / `selected` / `checked` / `hidden`
/ `required` / `readonly` / `visible` / `expanded` etc. The HTML spec
itself doesn't prefix these (`<input disabled>` not `<input
isDisabled>`) and forcing a prefix would diverge from consumer
expectations of the data shape.

The distinction is: a config field controls *the component*; a data-
model field describes *one item*. Config gets the prefix; data-model
fields don't.

**How to verify:**
```bash
# Find all boolean fields on the Config / Props interfaces specifically.
# Restrict the grep to lines following an `interface *Config` or `Props`
# declaration; bare scans of types.ts pick up data-model booleans too.
grep -En "^\s+\w+\??:\s+boolean" packages/<component>/src/types.ts \
                                  packages/<component>/src/lib/**/*.svelte \
                                  packages/<component>/src/lib/**/*.svelte.ts
```

When auditing by eye, ignore matches inside data-model interfaces
(those whose name matches `Option`, `Node`, `Item`, `Row`, `Entry`,
`Record`).

**Pass:** Every boolean Config / Props field starts with `is`, `has`,
`can`, or `should`. Data-model boolean fields are exempt. (Function
fields ending in `Callback` are also exempt — they're functions, not
booleans, even if they return boolean.)

**Failure mode:** Inconsistent boolean naming; consumers can't tell at
a glance whether a Config field is a flag or a value.

**Tag:** D-NC-9, D-NC-10.

---

## C-NC-4 — Notification callbacks use the right shape

**Tier:** `[semi]` — needs host detection (web-component vs Svelte) first; then the grep + regex is mechanical

**What:** Every fire-and-forget notification field uses the shape
matching the host technology:

| Host | Pattern |
|------|---------|
| Web-component config | `*Callback` |
| Svelte component prop | `on*` |
| Custom-element DOM surface | no field; `CustomEvent` dispatch |

**How to verify (web-component):**
```bash
# Find every Config field that's a function returning void
grep -En "^\s+\w+\??:\s+\(.*\)\s*=>\s*void" packages/<component>/src/types.ts
```

Each match should be named `*Callback` (for notifications) or the
right alternative (`before*Callback`, `get*Callback`, plain
`*Callback`).

**How to verify (Svelte component):**
```bash
grep -En "^\s+on[A-Z]\w+\??:\s+\(.*\)\s*=>" packages/<component>/src/lib/components/*.svelte
```

Notification fields should be named `on*`. Return-value-required
fields stay as `*Callback`.

**Pass (web-component):** Every void-returning Config field is
`*Callback`-suffixed.

**Pass (Svelte):** Every notification prop is `on*`-prefixed. No
notification prop uses `*Callback`.

**Failure mode:** Mixed conventions; consumers can't predict the
suffix.

**Tag:** D-NC-5.

---

## C-NC-5 — Interceptor callbacks use `before*Callback`

**Tier:** `[semi]` — identifying cancellation-capable fields requires return-type heuristic; the name-pattern check is mechanical

**What:** Any function field that runs before an action and can cancel
or modify it uses the `before*Callback` shape.

**How to verify:**
```bash
# Find every field whose return type allows cancellation (boolean | object | void)
grep -En "Callback\??:\s+\(.*\)\s*=>\s*(boolean|false|.*\|\s*false)" \
    packages/<component>/src/types.ts \
    packages/<component>/src/lib/**/*.svelte \
    packages/<component>/src/lib/**/*.svelte.ts
```

**Pass:** Every cancellation-capable field starts with `before` and
ends with `Callback`. None named `validate*`, `check*`, `on*`, or just
`<verb>Callback`.

**Failure mode:** Interceptor surface inconsistent across components;
consumer can't find the cancel hook.

**Exception:** N/A if D-NC-8 = B (no interceptors).

**Tag:** D-NC-8.

---

## C-NC-6 — Data extractors use `get*Callback` + `*Member` pair

**Tier:** `[auto]` (grep both, set intersect/diff)

**What:** Every data-extractor field comes in two shapes — a string
`*Member` field for the property-name shortcut and a function
`get*Callback` field for computed values.

**How to verify:**
```bash
# Member fields
grep -En "^\s+\w+Member\??:\s+string" packages/<component>/src/types.ts \
                                       packages/<component>/src/lib/**/*.svelte \
                                       packages/<component>/src/lib/**/*.svelte.ts

# Paired get*Callback fields
grep -En "^\s+get\w+Callback\??:\s+\(" packages/<component>/src/types.ts \
                                        packages/<component>/src/lib/**/*.svelte \
                                        packages/<component>/src/lib/**/*.svelte.ts
```

**Pass:** For every `<thing>Member` field, a matching
`get<Thing>Callback` field exists. Both are optional. The function
field's return type matches what the member-property lookup would
return.

**Failure mode:** Asymmetric surface — consumer can use member
shortcut for some properties but not others, and the rule for which is
which is invisible.

**Exception:** N/A if D-NC-7 = D (no data extraction). Allowed to ship
function-only (D-NC-7 = B) or member-only (D-NC-7 = C) with
justification.

**Tag:** D-NC-7.

---

## C-NC-7 — `ATTRIBUTE_TABLE` single source of truth (web-components only)

**Tier:** `[semi]` — existence of the constant is a grep; "drives observedAttributes / parsing / attributeChangedCallback" requires reading the implementation

**What:** A constant named `ATTRIBUTE_TABLE` (or equivalent) exists in
the Element file, drives `observedAttributes`, drives initial parsing,
and drives `attributeChangedCallback`.

**How to verify:**
```bash
grep -n "ATTRIBUTE_TABLE\|observedAttributes\|attributeChangedCallback" \
    packages/<component>/src/web-component.ts
```

**Pass:** Exactly one `ATTRIBUTE_TABLE` constant exists.
`observedAttributes` is computed from it (e.g.,
`ATTRIBUTE_TABLE.map(spec => spec.attr)`). Initial parsing and
`attributeChangedCallback` iterate the same table.

**Failure mode:** Three independent lists of attribute names; one gets
updated and the others don't.

**Exception:** D-NC-9 = No with explicit justification. N/A for Svelte
components.

**Tag:** D-NC-9.

---

## C-NC-8 — CSS classes use BEM with component prefix

**Tier:** `[auto]` (requires component prefix as input)

**What:** Every CSS class emitted by the component (in stylesheet and
in TS render code) starts with the component's prefix (`<prefix>__`)
and follows BEM (at most two underscore-levels).

**How to verify:**
```bash
# Find every class string in CSS
grep -hEon "\.[a-z][a-z0-9_-]*" packages/<component>/src/css/*.css | sort -u | head -50

# Find every class string in TS (rendered DOM)
grep -hEon "className\s*=\s*['\"][^'\"]+['\"]|class=['\"][^'\"]+['\"]" \
    packages/<component>/src/*.ts | sort -u | head -50
```

Every match (other than CSS pseudo-classes like `:host`, `:focus`,
`:hover`) should start with `<prefix>__`, optionally followed by
`--modifier`.

**Pass:** Every class is `<prefix>__element` or
`<prefix>__element--modifier`. No `<prefix>__element__sub-element`.

**Failure mode:** Class collisions with consumer stylesheets; loss of
component identity in DOM inspection.

**Tag:** D-NC-2.

---

## C-NC-9 — Internal methods use `handle*`, stored references use `*Handler`

**Tier:** `[auto]`

**What:** Internal DOM event handler methods on the Logic class are
named `handle*`. Stored references to listener functions (held so
they can be removed or invoked later) are named `*Handler`.

**How to verify:**
```bash
# Methods with the handle prefix
grep -En "private\s+handle\w+\(" packages/<component>/src/<logic-file>.ts

# Stored handler fields
grep -En "private\s+\w+Handler\??:" packages/<component>/src/<logic-file>.ts
```

**Pass:** Every internal DOM handler method starts with `handle`.
Every stored listener field ends with `Handler`. No `*Listener` /
`*Fn` / `*Cb` suffixes.

**Failure mode:** Inconsistent internal vocabulary; harder to navigate
the codebase.

**Tag:** Per `naming-conventions.md` — "internal halves" rule.

---

## C-NC-10 — No `validate*` where `check*` belongs (and vice versa)

**Tier:** `[manual]` (requires reading function bodies to judge gate-input vs read-only-inspection semantics)

**What:** `validate*` is used at the I/O boundary to gate input;
`check*` is used for read-only state inspection. They're not
interchangeable.

**How to verify:**
```bash
grep -En "(validate|check)[A-Z]\w*\s*\(" packages/<component>/src/*.ts
```

For each match, judge:

- `validate*` should throw, return a Result, or return an errors
  array. It's gating input from outside the trust boundary.
- `check*` should return a boolean or detail object, with no
  mutation, no throw.

**Pass:** Every `validate*` call site matches the gate-input
semantics; every `check*` call site matches the read-only inspection
semantics.

**Failure mode:** Consumer reads `validateFoo()` and expects it to
throw on bad input but it just returns false (or vice versa).

**Tag:** General Bliss verb registry (see public manifesto).

---

## C-NC-11 — TS interface suffixes match closed set

**Tier:** `[auto]` (same as C-CST-8 — run once and cite here)

**What:** Every exported TS interface / type uses a suffix from
[D-NC-10 / D-CST-7], and avoids forbidden suffixes.

**Same check as C-CST-8.** Run once and cite here.

**Tag:** D-NC-10, D-CST-7.

---

## C-NC-12 — No magic strings inline

**Tier:** `[semi]` — duplicate detection is mechanical; deciding what counts as a "magic string" worth extracting is judgment

**What:** Repeated string literals (event names, attribute names,
log-category names) are consolidated into top-of-file constants, not
inlined at every call site.

**How to verify:**

Pick suspected magic strings and grep for duplicates:

```bash
# Example: event names
grep -rEn "new CustomEvent\(['\"][a-z-]+['\"]" packages/<component>/src/ | \
    awk -F"'" '{print $2}' | sort | uniq -c | sort -rn

# Example: attribute names
grep -rEn "\.dataset\.[a-zA-Z]+|getAttribute\(['\"]" packages/<component>/src/ | head
```

**Pass:** No string literal that looks like a public identifier
(`'select'`, `'change'`, `'multiple'`, `'show-checkboxes'`) appears
more than twice inline. The third use should pull from a constant.

**Failure mode:** Renaming an event or attribute requires touching
every site; one gets missed.

**Exception:** `'true'` / `'false'` for attribute parsing, single-use
debug strings, and similar tiny literals are fine inline.

**Tag:** General Bliss DRY rule.

---

## Summary checklist

Paste into PR description:

```
Naming conventions
[ ] C-NC-1  [auto]   custom-element tag hyphenated + prefixed     (N/A Svelte)
[ ] C-NC-2  [auto]   CustomEvent names bare and short              (N/A Svelte)
[ ] C-NC-3  [auto]   boolean config fields use is*/should*/has*/can*
[ ] C-NC-4  [semi]   notification callbacks match host shape
[ ] C-NC-5  [semi]   interceptors use before*Callback
[ ] C-NC-6  [auto]   data extractors use get*Callback + *Member pair
[ ] C-NC-7  [semi]   ATTRIBUTE_TABLE single source of truth        (N/A Svelte)
[ ] C-NC-8  [auto]   CSS classes are <prefix>__element--modifier (BEM)
[ ] C-NC-9  [auto]   internal: handle* methods, *Handler stored refs
[ ] C-NC-10 [manual] validate* vs check* used per their semantics
[ ] C-NC-11 [auto]   TS interface suffixes from closed set
[ ] C-NC-12 [semi]   no magic strings inline

Tier totals: 7 auto, 4 semi, 1 manual
```
