# Example pages — Post-Implementation Checks

Run every check below **after** adding or changing examples, and
**before** declaring the work done. Mark each as ✅ pass, ❌ fail,
⚠️ exception (with reason), or N/A in the PR description.

Read [example-pages.md](./example-pages.md) for rationale and
[example-pages.decisions.md](./example-pages.decisions.md) for the
matching decision tags.

Each check is tagged **`[auto]`**, **`[semi]`**, or **`[manual]`** —
see [css-structure.checks.md](./css-structure.checks.md) for the
meaning of each tier. `example-pages.checks.sh` runs C-EP-1 … C-EP-3.

> **Applicability.** N/A for a package with no `examples-*.html` pages.

---

## C-EP-1 — Every `<h2>` on an example page carries a code

**Tier:** `[auto]`

**What:** Each `<h2>` in `examples-*.html` starts with
`<PREFIX><NN> · ` — 2–3 uppercase letters, 2–3 digits, space, middle
dot (U+00B7), space. A three-letter prefix must be an acronym
(D-EP-1 = B) — the script can't judge that; a reviewer does. A
heading reading just `Summary` is exempt.

**How to verify:**
```bash
bash example-pages.checks.sh <package-root>
```

**Pass:** No uncoded `<h2>`.

**Failure mode:** An example nobody can name in one token; people fall
back to "the third one under theming", which breaks as soon as the page
changes.

**Tag:** D-EP-1.

---

## C-EP-2 — Each prefix belongs to one page

**Tier:** `[auto]`

**What:** No prefix is used on two pages. (A page may own two
prefixes — D-EP-1; the script warns-by-listing when it does, so a
reviewer can confirm the second block is genuinely separate.)

**Pass:** Every prefix maps to exactly one page.

**Failure mode:** `API04` could live on either of two pages; the code no
longer identifies the page.

**Tag:** D-EP-1.

---

## C-EP-3 — No duplicate codes

**Tier:** `[auto]`

**What:** No code appears on more than one `<h2>` across the site.

**Pass:** Every code is unique.

**Failure mode:** Usually a copy-pasted section that kept its code —
"TH04" now means two different examples.

---

## C-EP-4 — No code was renumbered or reused

**Tier:** `[manual]`

**What:** Every code that existed before the change still names the
same example; new examples took the next free number; deleted codes
were not reused.

**How to verify:**
```bash
git diff <base> -- 'examples-*.html' | grep -E '^[-+]\s*<h2'
```
Every `-` line whose code reappears in a `+` line must be the same
example (title may be reworded); a code that appears only as `-` is
retired and must not show up on a different example later.

**Pass:** No code changed meaning.

**Failure mode:** Old bug reports, CHANGELOG entries and chat that say
"TH07" now point at a different example — and nothing warns the reader.
See example-pages.md → "Codes are permanent".

**Tag:** D-EP-2.
