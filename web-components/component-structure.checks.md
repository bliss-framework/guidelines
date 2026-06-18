# Component Structure — Post-Implementation Checks

Run every check below **after** scaffolding or refactoring a
component's internal architecture, and **before** declaring the work
done.

Each check: what to look for, how to verify, what failure looks like.
Failing any check means the work is not complete. Mark each as ✅
pass, ❌ fail, ⚠️ exception (with reason), or N/A in the PR description.

Read [component-structure.md](./component-structure.md) for rationale
and [component-structure.decisions.md](./component-structure.decisions.md)
for the matching decision tags.

Each check is tagged **`[auto]`**, **`[semi]`**, or **`[manual]`** — see
[css-structure.checks.md](./css-structure.checks.md) for the meaning of
each tier.

---

## C-CST-1 — Element class exists with `Element` suffix (web-components only)

**Tier:** `[auto]` (N/A for Svelte)

**What:** For web-components, the custom-element wrapper class is
defined and its name ends in `Element`.

**How to verify:**
```bash
grep -rEn "class\s+\w+Element\s+extends\s+HTMLElement" packages/<component>/src/
grep -n "customElements.define" packages/<component>/src/web-component.ts
```

**Pass:** Exactly one class with the `Element` suffix is defined and
passed to `customElements.define(...)`.

**Failure mode:** Mixed conventions across the suite; readers can't
tell at a glance which class is the I/O wrapper.

**Exception:** N/A for Svelte components (D-CST-1 = B).

**Tag:** D-CST-3.

---

## C-CST-2 — Custom-element tag agrees with `customElements.define`

**Tier:** `[auto]` (extract two strings, compare; N/A for Svelte)

**What:** The tag name passed to `customElements.define(...)` matches
the tag the Element class is supposed to register, and is hyphenated
(spec requirement) and prefixed.

**How to verify:**
```bash
grep -n "customElements.define" packages/<component>/src/web-component.ts
grep -rEn "<[a-z]+-[a-z-]+" packages/<component>/index.html packages/<component>/examples-*.html 2>/dev/null | head
```

**Pass:** The first argument to `customElements.define(...)` is a
kebab-case string with at least one hyphen. The same string appears as
the tag in example HTML / docs / tests.

**Failure mode:** Tag mismatch — the registered tag and the
documented/example tag drift apart; consumers' HTML doesn't upgrade.
Past incident: `multi-select:not(:defined)` rule in `base.css` while
`customElements.define('web-multiselect', ...)` — the FOUC rule
never fires (covered by C-TC-15 in the theme-container triad too).

**Exception:** N/A for Svelte components.

**Tag:** D-CST-3.

---

## C-CST-3 — Logic class exists and is framework-agnostic

**Tier:** `[auto]`

**What:** The Logic class is defined and does not import from a
framework runtime (Svelte, React, Vue).

**How to verify:**
```bash
# Find the Logic class
grep -rEn "^export\s+class\s+(Web[A-Z]\w+|[A-Z]\w+Controller|[A-Z]\w+Coordinator)" packages/<component>/src/

# Verify it does not import from a framework runtime
grep -rE "^import .* from ['\"](svelte|react|vue)['\"]" packages/<component>/src/<logic-file>.ts
```

**Pass:** The Logic class is exported. No framework-runtime import
exists in the file.

**Failure mode:** Logic class is locked to one framework; can't be
reused or tested without that framework's runtime.

**Exception:** Svelte-hosted Logic classes living in `.svelte.ts` may
use Svelte 5 runes (`$state`, `$derived`) — that's the D-CST-9 = B
exception. They still **must not** import from `'svelte'` runtime; runes
are a language extension, not a runtime import.

**Tag:** D-CST-2, D-CST-9.

---

## C-CST-4 — Service classes don't import each other

**Tier:** `[auto]` (pairwise greps)

**What:** Service classes in this component are single-purpose and
don't depend on one another. Cross-Service coordination happens via
the Logic class.

**How to verify:**

For each Service file (D-CST-4 list), grep its imports for *other*
Service-file paths:

```bash
# Example for web-multiselect:
grep -n "^import" packages/<component>/src/tooltip.ts | grep "virtual-scroll"
grep -n "^import" packages/<component>/src/virtual-scroll.ts | grep "tooltip"
```

**Pass:** No Service file imports another Service file.

**Failure mode:** Service-to-service coupling reproduces the Bliss
"providers calling providers" anti-pattern at component scale; lifting
a Service to its own package becomes impossible without surgery.

**Exception:** None. If two services need to coordinate, split the
coordination into the Logic class or extract a shared helper into the
Side layer.

**Tag:** D-CST-4.

---

## C-CST-5 — Side-layer files have no upward imports

**Tier:** `[auto]` (per-file import grep against known Logic / Element / Service paths)

**What:** Files in the Side layer (`types.ts`, `logger.ts`, helpers,
pure data structures) don't import from the Element, Logic, or Service
layers.

**How to verify:**

For each Side-layer file (D-CST-5 list):

```bash
# Identify Side-layer files
ls packages/<component>/src/{types,logger,constants}.ts \
   packages/<component>/src/helpers/ \
   2>/dev/null

# For each Side-layer file, verify it imports only from other Side-layer files or vendored deps:
for f in packages/<component>/src/types.ts packages/<component>/src/logger.ts; do
    echo "=== $f ==="
    grep -E "^import.*from\s+['\"]\./" "$f"
done
```

**Pass:** Each Side-layer file imports only from other Side-layer
files, `./vendor/`, or external `npm` packages. No relative import
reaches a Logic file (`multiselect.ts`), an Element file
(`web-component.ts`), or a Service file (`tooltip.ts`).

**Failure mode:** The "lift to own package" promise breaks; the file
is misnamed (it's not Side layer if it depends on the layers above).

**Tag:** D-CST-5.

---

## C-CST-6 — Element layer holds no business state

**Tier:** `[manual]` (requires reading the Element class body and judging "business" vs "lifecycle")

**What:** The Element class is a thin I/O wrapper. State lives on the
Logic class instance the Element holds. The Element class should not
declare its own `_selectedValues` / `_filtered` / domain fields.

**How to verify (web-components):**

Read `web-component.ts`. The Element class should declare:
- A single private field for the Logic-class instance (e.g.,
  `private instance?: WebMultiSelect<T>`).
- Optionally fields needed for the lifecycle (an `AbortController`, a
  `MutationObserver`).

It should **not** declare:
- `selectedValues`, `filteredOptions`, `isOpen`, or any domain state.
- Rendering state (DOM element references for internal sub-parts).

**Pass:** Element class has only the Logic-class reference plus
lifecycle fields.

**Failure mode:** State drift between Element and Logic class; bugs
where the visible state and the actual state disagree.

**Exception:** Bindable props in Svelte components (`isRendering` etc.
in svelte-treeview's `Tree.svelte`) are OK — they're props the Svelte
runtime owns, not domain state the Element manages.

**Tag:** D-CST-1, D-CST-2.

---

## C-CST-7 — No premature Manager

**Tier:** `[semi]` — grep for `*Manager` is mechanical; if matches exist, verifying D-CST-6 = B justification needs reading the PR description / README

**What:** A Manager class exists only when D-CST-6 = B was justified.

**How to verify:**
```bash
grep -rEn "^export\s+class\s+\w+Manager" packages/<component>/src/
```

**Pass:** Either no `*Manager` class exists, or D-CST-6 = B and the
PR description documents which Logic classes the Manager coordinates.

**Failure mode:** Single-Logic-class component wrapped in a
zero-value Manager; Bliss anti-pattern.

**Tag:** D-CST-6.

---

## C-CST-8 — TS interface suffixes match the closed set

**Tier:** `[auto]`

**What:** Every exported TS interface / type / class uses a suffix from
the D-CST-7 set, or none, and avoids the forbidden suffixes.

**How to verify:**
```bash
# List every exported interface and type
grep -rEn "^export\s+(interface|type)\s+\w+" packages/<component>/src/

# Check for forbidden suffixes
grep -rEn "^export\s+(interface|type)\s+\w+(Interface|Type|Data|Info|Object|Model)\b" packages/<component>/src/

# Check for I-prefixed interfaces
grep -rEn "^export\s+interface\s+I[A-Z]" packages/<component>/src/
```

**Pass:** Every export uses one of: `Config`, `Options` (migration only),
`EventDetail`, `Context`, `Spec`, `Request`, `Response`, or none. No
`Interface` / `Type` / `Data` / `Info` / `Object` / `Model` suffix. No
`I*` prefix.

**Failure mode:** Vocabulary drift; consumers can't tell which type is
the active surface.

**Tag:** D-CST-7.

---

## C-CST-9 — No premature interfaces

**Tier:** `[manual]` (requires counting implementations of each abstraction interface)

**What:** No interface exists for a shape that has a single
implementation, except for **public contract** interfaces
(`<Feature>Config`, `<Feature>EventDetail`, etc.).

**How to verify (manual):**

For each `export interface I*` or `export interface *Provider` /
`*Renderer` / `*Loader` etc. found, check that at least two concrete
implementations exist in the codebase (or that the README documents
the abstraction as a public extension point).

**Pass:** Every internal-abstraction interface has two implementations
or a documented public-extension role.

**Failure mode:** Bliss "Use only what you need" anti-pattern;
premature abstraction slows future readers.

**Exception:** Public-contract interfaces (`MultiSelectConfig<T>`) are
not internal abstractions — they describe the API surface. They get a
free pass.

**Tag:** D-CST-8.

---

## C-CST-10 — Folder layout matches convention

**Tier:** `[semi]` — `ls` against canonical shape is mechanical; deciding whether a deviation is documented in README is judgment

**What:** The component's `src/` (or `src/lib/`) folder structure
matches one of the canonical shapes documented in
`component-structure.md` → "Folder layout".

**How to verify (web-component):**
```bash
ls packages/<component>/src/
# Expected: index.ts, web-component.ts, <feature>.ts, types.ts,
# logger.ts, <service>.ts (one per Service), vendor/ (if any), css/
```

**How to verify (Svelte component):**
```bash
ls packages/<component>/src/lib/
# Expected: index.ts, components/, core/, <data-structure>/ (e.g. ltree/),
# helpers/, logger.ts, vendor/ (if any), styles/
```

**Pass:** Folder shape matches the documented layout. Deviations have
a one-line note in the README's "Code structure" section.

**Failure mode:** Suite-wide inconsistency; each new component
re-invents its own folder shape.

**Tag:** D-CST-1.

---

## C-CST-11 — Logic-class framework imports respect D-CST-9

**Tier:** `[auto]`

**What:** A web-component-hosted Logic class (D-CST-9 = A) has no
imports from `'svelte'`, `'react'`, `'vue'`. A Svelte-hosted Logic
class (D-CST-9 = B) may declare `$state` / `$derived` but **does
not** import from `'svelte'` runtime.

**How to verify:**
```bash
grep -rE "^import\s+.*\s+from\s+['\"](svelte|react|vue|vue/.*)['\"]" \
    packages/<component>/src/<logic-file>.*
```

**Pass (D-CST-9 = A):** Zero matches.

**Pass (D-CST-9 = B):** Zero matches. Runes used inline (`$state`,
`$derived`) are language syntax, not runtime imports.

**Failure mode:** Framework lock-in; the Logic class can't be ported
or unit-tested without booting the framework.

**Tag:** D-CST-9.

---

## Summary checklist

Paste into PR description:

```
Component structure
[ ] C-CST-1  [auto]   Element class with Element suffix    (N/A Svelte)
[ ] C-CST-2  [auto]   Tag agrees with customElements.define (N/A Svelte)
[ ] C-CST-3  [auto]   Logic class is framework-agnostic
[ ] C-CST-4  [auto]   Service classes don't import each other
[ ] C-CST-5  [auto]   Side-layer has no upward imports
[ ] C-CST-6  [manual] Element layer holds no business state
[ ] C-CST-7  [semi]   No premature Manager
[ ] C-CST-8  [auto]   TS interface suffixes match closed set
[ ] C-CST-9  [manual] No premature interfaces
[ ] C-CST-10 [semi]   Folder layout matches convention
[ ] C-CST-11 [auto]   Logic-class framework imports respect D-CST-9

Tier totals: 7 auto, 2 semi, 2 manual
```
