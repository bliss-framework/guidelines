#!/usr/bin/env bash
# readme-structure.checks.sh
#
# Mechanical Tier-1 ([auto]) checks for readme-structure.checks.md.
# Skips [semi] (needs context) and [manual] (needs judgment) checks.
#
# Usage:
#   ./readme-structure.checks.sh <component-package-path>
#
# Exit codes:
#   0   all auto checks passed
#   1   one or more auto checks failed
#   2   bad usage / target not found

set -u

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <component-package-path>" >&2
  exit 2
fi
if [[ ! -d "$TARGET" ]]; then
  echo "ERROR: target directory not found: $TARGET" >&2
  exit 2
fi
TARGET="$(cd "$TARGET" && pwd)"

PASS=0; FAIL=0; SKIP=0
if [[ -t 1 ]]; then
  C_PASS=$'\033[32m'; C_FAIL=$'\033[31m'; C_SKIP=$'\033[33m'
  C_INFO=$'\033[36m'; C_RESET=$'\033[0m'
else
  C_PASS='' C_FAIL='' C_SKIP='' C_INFO='' C_RESET=''
fi

record_pass() { echo "${C_PASS}✅ PASS${C_RESET} $1"; PASS=$((PASS+1)); }
record_fail() { echo "${C_FAIL}❌ FAIL${C_RESET} $1 — $2"; FAIL=$((FAIL+1)); }
record_skip() { echo "${C_SKIP}⏭  SKIP${C_RESET} $1 — $2"; SKIP=$((SKIP+1)); }

README="$TARGET/README.md"
DOCS_DIR="$TARGET/docs"

echo "${C_INFO}Component target:${C_RESET} $TARGET"
echo

echo "${C_INFO}== Running [auto] checks ==${C_RESET}"

# -----------------------------------------------------------------------------
# C-RS-1 — README.md exists at the package root
# -----------------------------------------------------------------------------

if [[ -f "$README" ]]; then
  record_pass "C-RS-1  README.md exists at package root"
else
  record_fail "C-RS-1" "no README.md at $TARGET"
  # Bail out of subsequent README-based checks
  echo
  echo "${C_INFO}== Summary ==${C_RESET}"
  echo "  ${C_PASS}Pass${C_RESET}:    $PASS"
  echo "  ${C_FAIL}Fail${C_RESET}:    $FAIL"
  echo "  ${C_SKIP}Skip${C_RESET}:    $SKIP"
  exit 1
fi

# -----------------------------------------------------------------------------
# C-RS-2 — README.md is under 400 lines
# -----------------------------------------------------------------------------

LINE_COUNT=$(wc -l < "$README" | tr -d ' ')

if [[ "$LINE_COUNT" -le 400 ]]; then
  if [[ "$LINE_COUNT" -le 200 ]]; then
    record_pass "C-RS-2  README.md is $LINE_COUNT lines (≤ 200 soft target)"
  else
    record_pass "C-RS-2  README.md is $LINE_COUNT lines (≤ 400 cap; > 200 soft target — consider trimming)"
  fi
else
  record_fail "C-RS-2" "README.md is $LINE_COUNT lines, exceeds 400-line hard cap (move content into docs/)"
fi

# -----------------------------------------------------------------------------
# C-RS-3 — docs/ folder exists with the required files
# -----------------------------------------------------------------------------

REQUIRED_DOCS=(usage.md theming.md examples.md accessibility.md)
MISSING_DOCS=()

if [[ ! -d "$DOCS_DIR" ]]; then
  record_fail "C-RS-3" "docs/ folder does not exist at $TARGET/docs"
  for f in "${REQUIRED_DOCS[@]}"; do MISSING_DOCS+=("$f"); done
else
  for f in "${REQUIRED_DOCS[@]}"; do
    if [[ ! -f "$DOCS_DIR/$f" ]]; then
      MISSING_DOCS+=("$f")
    fi
  done

  if [[ "${#MISSING_DOCS[@]}" -eq 0 ]]; then
    record_pass "C-RS-3  docs/ folder has all four required files (usage, theming, examples, accessibility)"
  elif [[ "${#MISSING_DOCS[@]}" -eq 1 ]] && [[ "${MISSING_DOCS[0]}" == "accessibility.md" ]]; then
    record_skip "C-RS-3" "docs/accessibility.md missing — N/A if D-RS-2 = B (display-only); otherwise FAIL"
  else
    record_fail "C-RS-3" "missing docs/ files: ${MISSING_DOCS[*]}"
  fi
fi

# -----------------------------------------------------------------------------
# C-RS-4 — README links to every docs/ file at least once (relative path)
# -----------------------------------------------------------------------------

UNLINKED_DOCS=()
if [[ -d "$DOCS_DIR" ]]; then
  for f in "${REQUIRED_DOCS[@]}"; do
    [[ ! -f "$DOCS_DIR/$f" ]] && continue   # missing file — already flagged by C-RS-3
    # Match either (./docs/usage.md) or (docs/usage.md) — both render correctly
    if ! grep -qE "\(\.?/?docs/$f\)" "$README"; then
      UNLINKED_DOCS+=("$f")
    fi
  done

  if [[ "${#UNLINKED_DOCS[@]}" -eq 0 ]]; then
    record_pass "C-RS-4  README links every existing docs/ file at least once"
  else
    record_fail "C-RS-4" "README does not link: ${UNLINKED_DOCS[*]}"
  fi
else
  record_skip "C-RS-4" "no docs/ folder to link to (see C-RS-3)"
fi

# -----------------------------------------------------------------------------
# C-RS-5 — README has the canonical section headings
# -----------------------------------------------------------------------------

# Required: "Install", "Quick start" or "Quick demo", "License"
# Plus a "What is it" / "About" / "Overview" style intro (any of these).

HAS_INSTALL=0
HAS_QUICKSTART=0
HAS_LICENSE=0
HAS_INTRO=0

grep -qiE "^##\s+Install" "$README" && HAS_INSTALL=1
grep -qiE "^##\s+(Quick\s+(start|demo)|Usage)" "$README" && HAS_QUICKSTART=1
grep -qiE "^##\s+License" "$README" && HAS_LICENSE=1
grep -qiE "^##\s+(What\s+is\s+it|About|Overview|Introduction)" "$README" && HAS_INTRO=1

MISSING_HEADINGS=()
[[ "$HAS_INTRO" -eq 0 ]]       && MISSING_HEADINGS+=("intro (What is it / About / Overview)")
[[ "$HAS_INSTALL" -eq 0 ]]     && MISSING_HEADINGS+=("Install")
[[ "$HAS_QUICKSTART" -eq 0 ]]  && MISSING_HEADINGS+=("Quick start (or Quick demo / Usage)")
[[ "$HAS_LICENSE" -eq 0 ]]     && MISSING_HEADINGS+=("License")

if [[ "${#MISSING_HEADINGS[@]}" -eq 0 ]]; then
  record_pass "C-RS-5  README has all required canonical section headings"
else
  record_fail "C-RS-5" "missing required headings: ${MISSING_HEADINGS[*]}"
fi

# -----------------------------------------------------------------------------
# C-RS-14 — README acknowledges BlissFramework guidelines + links to blissframework.dev
# -----------------------------------------------------------------------------

HAS_BF_LINK=0
HAS_BF_PROSE=0

grep -qE "https?://blissframework\.dev" "$README" && HAS_BF_LINK=1
grep -qiE "blissframework|guidelines?"  "$README" && HAS_BF_PROSE=1

if [[ "$HAS_BF_LINK" -eq 1 && "$HAS_BF_PROSE" -eq 1 ]]; then
  record_pass "C-RS-14 README links blissframework.dev and mentions the guidelines"
else
  MISSING=()
  [[ "$HAS_BF_LINK"  -eq 0 ]] && MISSING+=("absolute link to https://blissframework.dev/")
  [[ "$HAS_BF_PROSE" -eq 0 ]] && MISSING+=("attribution prose ('BlissFramework' or 'guidelines')")
  record_fail "C-RS-14" "missing: ${MISSING[*]} — add a 'Built with BlissFramework' line"
fi

# -----------------------------------------------------------------------------
# C-RS-15 — README has canonical ## About paragraph (KeenMate + Pure Admin + standalone + --base-*)
# -----------------------------------------------------------------------------

HAS_ABOUT_HEADING=0
HAS_KEENMATE=0
HAS_PUREADMIN=0
HAS_STANDALONE=0
HAS_BASE_TAXONOMY=0

grep -qiE "^##\s+(About|Credits)"        "$README" && HAS_ABOUT_HEADING=1
grep -qiE "KeenMate"                     "$README" && HAS_KEENMATE=1
grep -qiE "Pure[ -]?Admin|pureadmin"     "$README" && HAS_PUREADMIN=1
grep -qiE "standalone"                   "$README" && HAS_STANDALONE=1
grep -qE  "\-\-base-\*"                  "$README" && HAS_BASE_TAXONOMY=1

if [[ "$HAS_ABOUT_HEADING" -eq 1 \
   && "$HAS_KEENMATE"      -eq 1 \
   && "$HAS_PUREADMIN"     -eq 1 \
   && "$HAS_STANDALONE"    -eq 1 \
   && "$HAS_BASE_TAXONOMY" -eq 1 ]]; then
  record_pass "C-RS-15 README has canonical About paragraph (KeenMate + Pure Admin + standalone + --base-*)"
else
  MISSING=()
  [[ "$HAS_ABOUT_HEADING" -eq 0 ]] && MISSING+=("## About heading (## Credits accepted during transition)")
  [[ "$HAS_KEENMATE"      -eq 0 ]] && MISSING+=("KeenMate author attribution")
  [[ "$HAS_PUREADMIN"     -eq 0 ]] && MISSING+=("Pure Admin reference")
  [[ "$HAS_STANDALONE"    -eq 0 ]] && MISSING+=("'standalone' wording")
  [[ "$HAS_BASE_TAXONOMY" -eq 0 ]] && MISSING+=("--base-* taxonomy reference")
  record_fail "C-RS-15" "missing: ${MISSING[*]} — see readme-structure.md → '## About — canonical text'"
fi

# -----------------------------------------------------------------------------
# C-RS-16 — ## What's New in vX.Y.Z sections follow the canonical format
# -----------------------------------------------------------------------------
#
# Verifies four things:
#   1. At least one canonical heading is present:
#        ## What's New in v<semver>     (lowercase v, no backticks, no date)
#   2. At most two canonical headings exist (older releases live in CHANGELOG).
#   3. Every bullet directly under a What's New heading (until the next ##)
#      starts with "- **" and contains " — " (true em-dash + surrounding
#      spaces) between the bold lead phrase and the prose body.
#   4. No "### " sub-headers appear inside a What's New section.

WN_HEADING_RE='^## What'\''s New in v[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?$'
WN_ANY_HEADING_RE='^## What'\''s New in v'
# Loose match: any "## What's new..." heading, case-insensitive, with or
# without version. Used to distinguish "section is missing entirely" (the
# D-RS-5 = C exception) from "section exists but uses the wrong shape".
WN_LOOSE_HEADING_RE='^##\s+what'\''?s\s+new'

WN_HEADING_COUNT=$(grep -cE "$WN_HEADING_RE" "$README")
WN_ANY_HEADING_COUNT=$(grep -cE "$WN_ANY_HEADING_RE" "$README")
WN_LOOSE_HEADING_COUNT=$(grep -ciE "$WN_LOOSE_HEADING_RE" "$README")

# Detect a D-RS-5 = C exception: the README intentionally has NO What's New
# section of any kind, and links CHANGELOG.md from the Demos & docs block.
WN_HAS_CHANGELOG_LINK=0
grep -qE "\(\.?/?CHANGELOG\.md\)" "$README" && WN_HAS_CHANGELOG_LINK=1

if [[ "$WN_LOOSE_HEADING_COUNT" -eq 0 ]]; then
  # No What's New section of any kind. Either D-RS-5 = C (legitimate) or
  # the section is just missing (failure).
  if [[ "$WN_HAS_CHANGELOG_LINK" -eq 1 ]]; then
    record_skip "C-RS-16" "no 'What's new' section of any kind — N/A if D-RS-5 = C; CHANGELOG.md is linked"
  else
    record_fail "C-RS-16" "no 'What's New' section and no CHANGELOG.md link — add section per readme-structure.md → 'canonical format'"
  fi
elif [[ "$WN_ANY_HEADING_COUNT" -eq 0 ]]; then
  # Loose What's New heading exists but doesn't match "## What's New in v…" —
  # wrong shape, not an exemption. Point at the offender.
  OFFENDER=$(grep -niE "$WN_LOOSE_HEADING_RE" "$README" | head -1)
  record_fail "C-RS-16" "'What's new' heading is non-canonical — got: '${OFFENDER}'; want: '## What's New in v<semver>' per readme-structure.md → 'canonical format'"
else
  WN_PROBLEMS=()

  # 1) At least one heading must match the canonical shape
  if [[ "$WN_HEADING_COUNT" -eq 0 ]]; then
    # We have "## What's New in v..." lines but none in canonical shape — point
    # at one offender so the user can see what to fix.
    OFFENDER=$(grep -nE "$WN_ANY_HEADING_RE" "$README" | head -1)
    WN_PROBLEMS+=("non-canonical heading shape — got: '${OFFENDER}'; want: '## What's New in v<semver>' (no backticks, no date)")
  fi

  # 2) At most two canonical headings
  if [[ "$WN_HEADING_COUNT" -gt 2 ]]; then
    WN_PROBLEMS+=("$WN_HEADING_COUNT 'What's New' sections present — keep only the two most recent (older releases live in CHANGELOG.md)")
  fi

  # 3 & 4) Per-section bullet + sub-header scan
  # awk emits one line per offence: <kind>\t<line-number>\t<offending-text>
  # kinds: BAD_BULLET, SUBHEADER
  BULLET_OFFENCES=$(awk '
    BEGIN { in_section = 0 }
    {
      line = $0
      lineno = NR

      # Enter a What'\''s New section
      if (line ~ /^## What'\''s New in v/) {
        in_section = 1
        next
      }

      # Leave the section on any other H2
      if (in_section && line ~ /^## /) {
        in_section = 0
      }

      if (in_section) {
        # 4) ### sub-headers inside the section are not allowed
        if (line ~ /^### /) {
          print "SUBHEADER\t" lineno "\t" line
          next
        }

        # 3) Bullets must be "- **...** — ..." with a real em-dash
        if (line ~ /^[-*] /) {
          if (line !~ /^[-*] \*\*/) {
            print "BAD_BULLET\t" lineno "\t" substr(line, 1, 80)
            next
          }
          # Look for " — " (space, U+2014, space). awk handles UTF-8 bytes
          # transparently here; the em-dash is the literal 3-byte sequence.
          if (line !~ / \xe2\x80\x94 /) {
            print "BAD_BULLET\t" lineno "\t" substr(line, 1, 80)
            next
          }
        }
      }
    }
  ' "$README")

  if [[ -n "$BULLET_OFFENCES" ]]; then
    BAD_BULLETS=$(echo "$BULLET_OFFENCES" | grep -c '^BAD_BULLET' || true)
    SUBHEADERS=$(echo "$BULLET_OFFENCES" | grep -c '^SUBHEADER' || true)

    if [[ "$BAD_BULLETS" -gt 0 ]]; then
      FIRST_BAD=$(echo "$BULLET_OFFENCES" | grep '^BAD_BULLET' | head -1 | cut -f2,3 | tr '\t' ':')
      WN_PROBLEMS+=("$BAD_BULLETS bullet(s) miss the '- **…** — …' pattern (need bold lead phrase + true em-dash + prose). First: line $FIRST_BAD")
    fi
    if [[ "$SUBHEADERS" -gt 0 ]]; then
      FIRST_SUB=$(echo "$BULLET_OFFENCES" | grep '^SUBHEADER' | head -1 | cut -f2,3 | tr '\t' ':')
      WN_PROBLEMS+=("$SUBHEADERS '### ' sub-header(s) inside 'What's New' section — drop them; What's New is a flat bullet list. First: line $FIRST_SUB")
    fi
  fi

  if [[ "${#WN_PROBLEMS[@]}" -eq 0 ]]; then
    record_pass "C-RS-16 '## What's New in vX.Y.Z' section(s) follow canonical format ($WN_HEADING_COUNT section(s))"
  else
    # Join problems with a separator that survives the colour codes
    JOINED=""
    for p in "${WN_PROBLEMS[@]}"; do
      if [[ -z "$JOINED" ]]; then JOINED="$p"; else JOINED="$JOINED; $p"; fi
    done
    record_fail "C-RS-16" "$JOINED"
  fi
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo
echo "${C_INFO}== Summary ==${C_RESET}"
echo "  ${C_PASS}Pass${C_RESET}:    $PASS"
echo "  ${C_FAIL}Fail${C_RESET}:    $FAIL"
echo "  ${C_SKIP}Skip${C_RESET}:    $SKIP"
echo
echo "  Semi / manual checks NOT run by this script:"
echo "    [semi]   C-RS-6  (README 'What is it' is tight — needs paragraph judgment)"
echo "    [semi]   C-RS-7  (README 'What's new' links CHANGELOG)"
echo "    [semi]   C-RS-8  (deployed demo link present + returns 200)"
echo "    [manual] C-RS-9  (quick-start snippet actually runs in a clean install)"
echo "    [semi]   C-RS-10 (docs/usage.md covers full public surface)"
echo "    [semi]   C-RS-11 (docs/theming.md covers container + variables + color-scheme + layer)"
echo "    [semi]   C-RS-12 (docs/examples.md has ≥ 1 worked example beyond quick start)"
echo "    [semi]   C-RS-13 (docs/accessibility.md covers keyboard + ARIA + focus)"
echo "  Run the .checks.md prose for those, or use /validate-readme-structure."

[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
