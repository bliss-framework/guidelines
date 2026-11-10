# Core Adoption — Post-Implementation Checks

Run every check below **after** you finish the component's behaviour, and **before** declaring it
done. Mark each as ✅ pass or ❌ fail in the PR description.

Read [core-adoption.md](./core-adoption.md) for the rationale behind each check.

Each check is tagged **`[auto]`**, **`[semi]`**, or **`[manual]`** — see
[css-structure.checks.md](./css-structure.checks.md) for the tiers. The `[auto]` checks are in
[core-adoption.checks.sh](./core-adoption.checks.sh).

**Applicability:** web components (D-CA-1 = A). For a Svelte component only C-CA-12 (parity)
applies.

Paths assume the source lives in `src/` and the e2e specs in `e2e/`.

---

## C-CA-1 — The element extends `BlissElement`, no own attribute plumbing

**Tier:** `[auto]`

**How to verify:**
```bash
grep -rnE "extends BlissElement" src/
grep -rnE "static (get )?observedAttributes|attributeChangedCallback\s*\(" src/ --include=*.ts | grep -v "\.test\."
```

**Pass:** at least one `extends BlissElement`; no own `observedAttributes` /
`attributeChangedCallback`.

**Failure mode:** a second attribute pipeline that skips core's parse / validate / reactivity.

---

## C-CA-2 — Every `toBool` names its mode; `'presence'` only for `disabled` / `readonly`

**Tier:** `[auto]`

**How to verify:**
```bash
grep -rnE "toBool\(\s*\)" src/ --include=*.ts | grep -v "\.test\."
grep -rnE "toBool\('presence'\)" src/ --include=*.ts | grep -vE "attribute: '(disabled|readonly)'"
```

**Pass:** both empty.

**Failure mode:** `x="false"` turns a flag on (presence mode), surprising every framework that
renders `x={false}` as `x="false"`.

---

## C-CA-3 — No dead `default` (core's table check is silent)

**Tier:** `[semi]` — needs the page running

**How to verify:** open any example page with the component, console filter `invalid input table`.

**Pass:** no `invalid input table` warning (in particular none ending `the default never
applies`).

**Failure mode:** a documented default the element never takes.

---

## C-CA-4 — No `scrollIntoView()` on inner elements

**Tier:** `[auto]`

**How to verify:**
```bash
grep -rnE "\.scrollIntoView\(" src/ --include=*.ts | grep -v "\.test\." | grep -v "core-adoption: allow"
```

**Pass:** empty. (A justified exception carries a `// core-adoption: allow — <reason>` comment on
the same line.)

**Failure mode:** a keyboard move or a search jump scrolls the whole page.

---

## C-CA-5 — No private scroll-container / floating-ui copies

**Tier:** `[auto]`

**How to verify:**
```bash
grep -rnE "findScrollableAncestor|_?findScrollContainer\s*\(|_?scrollIntoContainer\s*\(" src/ --include=*.ts \
  | grep -v "from '@keenmate/web-components-core'" | grep -vE "^\S+:\s*(import|//|\*)" | grep -E "(function|private|#)\s*_?\w*[Ss]croll"
grep -rnE "from '@floating-ui/dom'" src/ --include=*.ts
```

**Pass:** both empty (core's `findScrollContainer` / `scrollIntoContainer` imported, not
re-declared; no direct floating-ui import).

**Failure mode:** a private copy drifts from core (scroll-padding, RTL, shadow walk).

---

## C-CA-6 — `beforeScrollCallback` when the component scrolls on its own

**Tier:** `[semi]`

**What:** if D-CA-5 = A or B, the input exists, its ctx carries the item, `source`, `container`
and the options, it runs through `runBeforeCallbackSync`, `false` skips the scroll, and it is
documented (`docs/usage.md`) and demoed (an example card) and covered by an e2e spec.

**How to verify:**
```bash
grep -rnE "beforeScrollCallback" src/ docs/ examples-*.html e2e/
grep -rnE "scrollIntoContainer\(" src/
```

**Pass:** D-CA-5 = C, or all of the above present.

---

## C-CA-7 — Before-callbacks go through core's runner

**Tier:** `[semi]`

**How to verify:**
```bash
grep -rnE "before\w+Callback" src/ --include=*.ts | grep -v "\.test\." | grep -vE "runBeforeCallback|configKey|type |interface |\*|//"
```

**Pass:** every invocation site uses `runBeforeCallback` / `…Eager` / `…Sync`; the remaining
hits are declarations, not calls.

---

## C-CA-8 — No `console.*` in component source

**Tier:** `[auto]`

**How to verify:**
```bash
grep -rnE "\bconsole\.(log|info|warn|error|debug)\(" src/ --include=*.ts | grep -v "\.test\." | grep -v "core-adoption: allow"
```

**Pass:** empty — logging goes through the instance loggers.

---

## C-CA-9 — Loaders go through `renderLoader`

**Tier:** `[semi]`

**How to verify:** `grep -rn "renderLoader\|renderLoadingCallback" src/` — every async state from
D-CA-8 calls it; no hand-drawn spinner element.

---

## C-CA-10 — Search uses `/search`

**Tier:** `[semi]` (D-CA-9 = A only)

**How to verify:**
```bash
grep -rnE "from '@keenmate/web-components-core/search'" src/
grep -rnE "toLowerCase\(\)[^;]*\.(includes|indexOf|startsWith)\(" src/ --include=*.ts | grep -v "\.test\."
```

**Pass:** the import exists; no private case-folding match on user search text.

---

## C-CA-11 — e2e specs target `test/` fixtures, not example pages

**Tier:** `[auto]`

**How to verify:**
```bash
grep -rnE "goto\([^)]*examples-" e2e/ | grep -v "examples.spec.ts"
ls test/*.html
```

**Pass:** no spec except the smoke spec opens an `examples-*.html`; fixture pages exist.

---

## C-CA-12 — Parity copies recorded *(Svelte, and any component with a copy)*

**Tier:** `[manual]`

**What:** every non-core copy of a core algorithm (scroll container, search normalization, …) has
a `docs/parity.md` row naming the core function and the differences (should be none).

---

## C-CA-13 — `disabled` reflects on a form-associated component

**Tier:** `[auto]` (D-CA-4 = A only)

**How to verify:**
```bash
grep -rnE "attribute: 'disabled'" src/ --include=*.ts | grep -v "shouldReflect: true"
```

**Pass:** empty (core also warns at runtime).

---

## C-CA-14 — Core hooks stay `protected`

**Tier:** `[auto]`

**What:** in a class that extends `BlissElement`, no override of a core hook is public. The public
way to write many inputs at once is core's `el.setAttributes(props)` / `el.batch()`. A public
`update(props)` (web-treeview until 2026-11) skipped the input pipeline: no parse, no validation,
no `input-rejected`, `this.config` never written, so the next flush put the old values back.

**How to verify:**
```bash
grep -rlE "extends BlissElement" src/ --include=*.ts   | xargs grep -nE "^\s*(public\s+)?(override\s+)?(async\s+)?(reinit|update|connect|disconnect|removedCallback|destroyCallback|environmentChanged|viewportChanged|sizeChanged|directionChanged|themeChanged|disabledChanged|setFormatError|engineConfig|createController|eventContext)\s*\("   | grep -vE "protected|private"
```

**Pass:** empty.

---

## C-CA-15 — Custom CSS through `createCustomStyles()`, the canonical way

**Tier:** `[auto]`

**What:** every BlissElement component offers custom CSS the same way (core `docs/usage.md` →
"Style injection"): the input rows `customStyles` (`custom-styles`, `toText({ isNullable: true })`)
and `getCustomStylesCallback` (`toFunction()`), both `on: 'update'`; one `createCustomStyles()`
handle (`cssClass: '<prefix>-custom-styles'`, no `position` option) refreshed per build and on
those two keys, destroyed in `destroyCallback()`. No private custom-CSS code (`createStyleSlot`,
own `<style>` / `<link>` injection). This also makes the page layer
`window.components[tag].customStyles` work — core warns when a page sets it for a component that
doesn't apply it.

**How to verify:**
```bash
grep -rn "configKey: 'customStyles'\|configKey: 'getCustomStylesCallback'\|createCustomStyles" src/ --include=*.ts
grep -rnE "createStyleSlot\(|data-[a-z]+-injected" src/ --include=*.ts
grep -rnE -A8 "createCustomStyles(<.*>)?\(" src/ --include=*.ts | grep "position:"
```

**Pass:** both rows and the call exist; the last two greps are empty.

---

## C-CA-16 — Input properties typed on the element class

**Tier:** `[auto]`

**What:** core installs every input row's property on the instance at runtime, invisible to
TypeScript. Each exported `BlissElement` class gets the one-line declaration merge from core
`docs/usage.md` ("Typing the properties"): `export interface <Class><T> extends <ElementConfig><T> {}`,
where the config type lists exactly the input rows.

**How to verify:**
```bash
grep -rnE "export (abstract )?class [A-Za-z0-9_]+.* extends BlissElement" src/ --include=*.ts
grep -rnE "export interface <Class>(<[^{]*>)? extends [^{]*Config" src/ --include=*.ts
```

**Pass:** every exported BlissElement class has its merge.

