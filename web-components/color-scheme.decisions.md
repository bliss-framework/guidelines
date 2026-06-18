# Color-Scheme — Pre-Implementation Decisions

Answer every decision below **before** writing any CSS for light/dark
handling. Each decision has a recommended default; deviating from the default
requires a one-line justification (write it down somewhere — README, CHANGELOG,
PR description).

Read [color-scheme.md](./color-scheme.md) first if any of these questions
don't make sense.

---

## D-CS-1 — Dark mode strategy

**Question:** Which combination of CSS mechanisms will the component use to
detect dark mode?

| Option | When to pick | Implication |
|--------|--------------|-------------|
| **A. Belt-and-suspenders** *(default)* | The component will ship to heterogeneous consumers (apps using different frameworks, varied conventions, possibly older Bootstrap). | `light-dark()` in fallbacks + `:host-context()` selectors for framework classes + `:host([data-theme])` per-instance. ~50 extra lines of CSS. Catches every case. |
| B. `light-dark()` only | Greenfield component, small/controlled consumer base, modern frameworks (Bootstrap 5.3+, Tailwind with explicit color-scheme), willing to require consumers to set `color-scheme`. | Cleanest CSS. Won't catch framework theme classes that *don't* set `color-scheme`. |
| C. Explicit overrides only | Legacy browser support requirement (no `light-dark()` available — pre-Chrome 123 / Firefox 120 / Safari 17.5). | No zero-config OS mode; consumer must set the theme class. Most CSS to write. |

**Default: A. Belt-and-suspenders.**

**If you pick B or C:** document the deviation in the component README under
"Theming notes."

---

## D-CS-2 — Framework theme classes to support

**Question:** Which framework conventions will the `:host-context()` selectors
match?

Pick all that apply. Defaults are pre-checked.

- [x] `:host-context([data-theme="dark"])` — generic project convention
- [x] `:host-context([data-bs-theme="dark"])` — Bootstrap 5.3+
- [x] `:host-context(.dark)` — Tailwind
- [ ] `:host-context([data-mui-color-scheme="dark"])` — MUI v6+ (only if the
      component is expected to ship inside MUI apps)
- [ ] Custom convention (specify name): __________

Symmetric `light` selectors are mandatory for whichever `dark` selectors you
picked. (You need to be able to force light on a dark page.)

**Default:** the three checked above. They cover the vast majority of
real-world apps.

---

## D-CS-3 — Per-instance override attribute

**Question:** What attribute on the component itself flips it to dark/light?

| Option | When to pick |
|--------|--------------|
| **A. `data-theme="dark"` / `data-theme="light"`** *(default)* | Project-wide consistency. Every KeenMate component uses this convention. |
| B. `data-color-scheme="dark"` | Only if there's a name clash with an existing attribute that conflicts. Document the deviation. |
| C. No per-instance override | Component is always page-driven. Acceptable if there's a strong reason; otherwise this is leaving an escape hatch on the table. |

**Default: A. `data-theme`**

---

## D-CS-4 — Hover/active fallback strategy

**Question:** How should hover and active backgrounds compute their fallbacks?

| Option | When to pick |
|--------|--------------|
| **A. Adaptive via `color-mix`** *(default)* | The hover highlight should stay visible regardless of how dark or light the surface is. |
| B. Flat literal | Only if `color-mix` is unsupported (very old browsers) OR if the component has a fixed/known background that won't drift. |

**Default: A. Adaptive.** Use:
```css
color-mix(in srgb, var(--<prefix>-text) 8%, var(--<prefix>-main-bg))
```
for hover, and `14%` for active.

---

## D-CS-5 — Contrast testing scope

**Question:** Which signals will the dark-mode test suite cover?

Pick all that the component supports (from D-CS-2). Defaults: cover everything
you chose to support in D-CS-2 plus per-instance from D-CS-3.

- [ ] Signal #3 — `body { color-scheme: dark }` (light-dark() inheritance)
- [ ] Signal #4a — `[data-theme="dark"]` ancestor
- [ ] Signal #4b — `[data-bs-theme="dark"]` ancestor
- [ ] Signal #4c — `.dark` ancestor
- [ ] Signal #5 — `data-theme="dark"` on the component itself

**Rule:** every signal the component *claims* to support must have at least
one Playwright test asserting WCAG contrast ≥ 3:1 against a representative
text element.

---

## D-CS-7 — Signal handling strategy: override variables, or flip `color-scheme`?

**Question:** When a framework-class or per-instance signal fires
(D-CS-2, D-CS-3), do the matched selectors override CSS variables,
or do they flip `color-scheme` on the host?

| Option | When to pick | Implication |
|--------|--------------|-------------|
| **A — Override variables** *(legacy default)* | Component has hardcoded single-mode literals in fallbacks (incremental migration); or dark-mode colors don't derive from `light-dark(<light>, <dark>)` (e.g., dark mode uses a different hue, not just a darker version). | Each signal selector sets `--my-bg: #...; --my-text: #...;` etc. Explicit. Larger `dark-mode.css`. Risks shadowing the consumer's `--base-*` overrides for the matched scope. |
| **B — Flip `color-scheme`** *(recommended for new components)* | Every color in the component already chains through `light-dark()` (which the guideline requires anyway — C-CS-2). | Each signal selector sets `color-scheme: dark` (or `light`). One declaration per signal. `light-dark()` picks the dark branch automatically. Consumer's `--base-*` overrides keep flowing through untouched. |

**Default:** B for new components. A for components migrating from a
pre-`light-dark()` codebase that haven't yet finished moving every
literal into a fallback chain.

**Constraint shared by both:** The base `:host` block must NEVER
declare a *bare* `color-scheme: ...` — that shadows page inheritance
for every instance (C-CS-1). Strategy B only works because the
declarations are conditional on signal selectors.

**Reference:**
- Strategy A — web-grid (legacy, ~300 lines of dark-mode CSS).
- Strategy B — `@keenmate/web-multiselect` v1.12.0-rc01+ (`src/css/dark-mode.css`, ~60 lines).

**Your pick:** A / B

If A, justify briefly: ____________

---

## D-CS-6 — Forced-colors / high-contrast support

**Question:** Will the component respect Windows High Contrast mode and
similar accessibility modes?

| Option | When to pick |
|--------|--------------|
| **A. No special handling** *(default for now)* | Component uses system-aware colors via `light-dark()` and accent-color; forced-colors will typically work passably. |
| B. Explicit `@media (forced-colors: active)` block | Component has interactive elements (buttons, focus rings, indicators) that need to be visible in forced-colors mode. Worth doing for production-critical components. |

**Default: A.** Revisit when the component lands an accessibility audit.

If you pick B, see the (TBD) `accessibility.md` for the forced-colors pattern.

---

## Decision summary table

Fill this out and paste it into the component's CHANGELOG entry or PR
description so future maintainers know what was decided.

```
D-CS-1 dark mode strategy        : [A | B | C]   ← _______
D-CS-2 framework classes         : [data-theme, data-bs-theme, .dark, MUI, custom]
D-CS-3 per-instance attribute    : [data-theme | data-color-scheme | none]
D-CS-4 hover/active fallback     : [adaptive color-mix | flat literal]
D-CS-5 contrast tests cover      : [signals 3, 4a, 4b, 4c, 5]
D-CS-6 forced-colors             : [no special handling | @media block]
D-CS-7 signal handling           : [A override --vars | B flip color-scheme]
```

---

When done deciding, proceed to implementation. Use
[color-scheme.checks.md](./color-scheme.checks.md) before declaring it done.
