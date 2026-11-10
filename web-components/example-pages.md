# Example pages — section codes

**Applies to every component's example site** (`examples-*.html` at the
package root). Today this topic covers one rule: every example carries a
short, permanent **section code** — `TH01`, `BU03`, `AB07` — so a person
can point at an example in one token ("TH07 is broken in dark mode") and
anyone, human or agent, finds it without a search.

Walk [example-pages.decisions.md](./example-pages.decisions.md) when you
add a page, and run [example-pages.checks.md](./example-pages.checks.md)
(C-EP-1 … C-EP-4) before declaring an example change done.

---

## The rule

Every `<h2>` on an `examples-*.html` page starts with its code, a
spaced middle dot, then the title:

```html
<h2>TH07 · Per-instance data-theme</h2>
<h2>BU03 · Listening for changes <span class="badge new">New</span></h2>
```

- **Code = page prefix + two-digit number.** `TH` + `07`. The number is
  zero-padded to two digits (`01`–`99`); a page that passes 99 examples
  goes to three (`TH100`) and should probably be split.
- **The prefix belongs to the page**, not to the topic of the example:
  everything on `examples-theming.html` is `TH`, even an example that
  also shows an event. Two uppercase letters, derived from the page name
  (`basic` → `BU`, `theming` → `TH`, `action-buttons` → `AB`).
- **Three letters only for a real acronym** — `API`, `CSS`, `SSR` —
  never just to dodge a collision (pick other two letters instead).
- **A prefix belongs to exactly one page**, so a code alone identifies
  the page. A page normally owns one prefix; it may own a second for a
  clearly separate block (`examples-data-api.html`: `DA` for data
  loading, `API` for the method reference).
- **Every example `<h2>` is coded.** The `<h2>` is the unit the chapter
  nav and the copy-link buttons address; an uncoded one is an example
  nobody can name. Exception: a closing **Summary** section isn't an
  example and stays uncoded (`<h2>Summary</h2>`). Sub-structure inside
  an example uses `<h3>` and is not coded.
- **The separator is ` · `** (space, U+00B7 middle dot, space).

## Codes are permanent

**A code, once published, never changes meaning.** Codes end up in bug
reports, chat, commit messages, CHANGELOG entries and agent sessions. If
`TH07` silently becomes a different example after a renumber, every old
reference now points at the wrong thing — and nothing tells the reader.
A wrong pointer is worse than no pointer: it leads to confident, wrong
conclusions.

So:

- **New example → next free number** on that page (highest ever used +
  1), wherever it sits on the page. Numbers on a page may therefore read
  out of order (`TH01, TH02, TH12, TH03, …`). That's expected.
- **Reordering sections** moves them; their codes go with them.
- **Deleted example → its code is retired**, never reused. Gaps are
  fine.
- **Renamed / rewritten example** keeps its code if it still
  demonstrates the same thing. If it now demonstrates something else,
  it's a new example: retire the old code, take the next free one.
- **Example moved to another page** takes the next free code on the
  new page; the old code is retired.
- **Page renamed or split** keeps its prefix where it can; a split-off
  page gets a new prefix and its examples new codes.

Never "tidy up" the numbering. There is no such thing as a cosmetic
renumber.

## Anchors

The devkit's chapter nav and copy-link buttons slug the heading text, so
the code lands in the URL hash (`#th07-per-instance-data-theme`). A deep
link therefore carries the code too. A section may set its own `id`; if
it does, start it with the lowercased code (`id="th07-…"`) for the same
reason.

## Where this does not apply

- `index.html` (the landing page) — its headings aren't examples.
- Partials pulled in with `<kmwc-include>` should not contain `<h2>`;
  the page owns its sections and their codes.
