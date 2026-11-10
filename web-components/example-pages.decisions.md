# Example pages — Pre-Implementation Decisions

Answer these when you **add an example page** (or adopt the convention
on an existing site). Each has a recommended default; deviating requires
a one-line justification in the PR description.

Read [example-pages.md](./example-pages.md) first if any of these
questions don't make sense.

---

## D-EP-1 — The page's prefix

**Question:** Which code prefix does the new page own?

**Options:**

- **A — Two letters from the page name (default).** `basic` → `BU`,
  `theming` → `TH`, `events-callbacks` → `EV`, `virtual-scrolling` →
  `VS`. Pick something a reader can map back to the page.
- **B — Three letters, for a real acronym.** `API`, `CSS`, `SSR` —
  when the block is *about* that thing. Not as a collision dodge.

**Default:** A.

A page may own a second prefix for a clearly separate block
(`examples-data-api.html`: `DA` + `API`).

**Don't:** reuse a prefix another page already owns — a code must name
exactly one page.

**Your pick:** ____________

---

## D-EP-2 — Adopting codes on an existing uncoded site

**Question:** The site has examples without codes. How are the first
codes assigned?

**Options:**

- **A — Number in current page order, once (default).** First adoption
  numbers each page top-to-bottom from `01`. From then on the codes are
  permanent (see example-pages.md → "Codes are permanent").
- **B — Keep any codes that already exist** and give the uncoded
  sections the next free numbers. Required whenever *some* codes are
  already in circulation — never renumber those.

**Default:** A for a fully uncoded site, B otherwise.

**Your pick:** ____________
