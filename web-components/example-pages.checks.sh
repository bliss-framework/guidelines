#!/usr/bin/env bash
# example-pages.checks.sh
#
# Mechanical Tier-1 ([auto]) checks for example-pages.checks.md.
# Runs C-EP-1, C-EP-2, C-EP-3. Skips [manual] C-EP-4 (no renumbering —
# needs a diff against the last release).
#
# Applicability: N/A (exit 0) when the package has no examples-*.html.
#
# Usage:
#   ./example-pages.checks.sh <component-package-path>
#
# Exit codes:
#   0   all auto checks passed (or triad N/A)
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
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_PASS=$'\033[32m'; C_FAIL=$'\033[31m'; C_SKIP=$'\033[33m'
  C_INFO=$'\033[36m'; C_RESET=$'\033[0m'
else
  C_PASS='' C_FAIL='' C_SKIP='' C_INFO='' C_RESET=''
fi

record_pass() { echo "${C_PASS}✅ PASS${C_RESET} $1"; PASS=$((PASS+1)); }
record_fail() { echo "${C_FAIL}❌ FAIL${C_RESET} $1 — $2"; FAIL=$((FAIL+1)); }
record_skip() { echo "${C_SKIP}⏭  SKIP${C_RESET} $1 — $2"; SKIP=$((SKIP+1)); }

print_summary() {
  echo
  echo "${C_INFO}== Summary ==${C_RESET}"
  echo "  ${C_PASS}Pass${C_RESET}:    $PASS"
  echo "  ${C_FAIL}Fail${C_RESET}:    $FAIL"
  echo "  ${C_SKIP}Skip${C_RESET}:    $SKIP"
}

echo "${C_INFO}Component target:${C_RESET} $TARGET"
echo

shopt -s nullglob
PAGES=("$TARGET"/examples-*.html)
shopt -u nullglob

if [[ ${#PAGES[@]} -eq 0 ]]; then
  record_skip "C-EP-*" "no examples-*.html pages — triad N/A"
  print_summary
  exit 0
fi

# One line per <h2>: "<page>\t<heading text up to the first tag>".
# Newlines are folded first so a heading split over lines still matches;
# <script> bodies are dropped (headings built in JS can't be read statically).
HEADINGS=""
for PAGE in "${PAGES[@]}"; do
  PAGE_NAME="$(basename "$PAGE")"
  while IFS= read -r HEADING_TEXT; do
    HEADINGS+="${PAGE_NAME}"$'\t'"${HEADING_TEXT}"$'\n'
  done < <(tr '\r\n' '  ' < "$PAGE" \
           | awk 'BEGIN { RS = "</script>" } { start = index($0, "<script"); print (start ? substr($0, 1, start - 1) : $0) }' \
           | grep -oE '<h2[^>]*>[^<]*' \
           | sed -E 's/^<h2[^>]*>//; s/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/ /g')
done

# The text stops at the first tag, so 'TH07 · <code>…' leaves 'TH07 ·'.
CODE_PATTERN='^[A-Z]{2,3}[0-9]{2,3} ·( |$)'

# -----------------------------------------------------------------------------
# C-EP-1 — every example <h2> carries a code (a plain "Summary" is exempt)
# -----------------------------------------------------------------------------

UNCODED=$(printf '%s' "$HEADINGS" \
          | awk -F'\t' -v pattern="$CODE_PATTERN" '$2 !~ pattern && $2 !~ /^Summary$/ { print "      " $1 ": <h2>" $2 }')

if [[ -z "$UNCODED" ]]; then
  record_pass "C-EP-1  every example <h2> carries a code"
else
  N=$(printf '%s\n' "$UNCODED" | grep -c . || true)
  record_fail "C-EP-1" "$N <h2> without a '<CODE><NN> · ' code (e.g. 'TH07 · Title'):
$UNCODED"
fi

# Coded headings only: "<page>\t<prefix>\t<code>".
CODES=$(printf '%s' "$HEADINGS" \
        | awk -F'\t' -v pattern="$CODE_PATTERN" '$2 ~ pattern {
            code = $2; sub(/ .*/, "", code)
            prefix = code; sub(/[0-9]+$/, "", prefix)
            print $1 "\t" prefix "\t" code }')

# -----------------------------------------------------------------------------
# C-EP-2 — each prefix belongs to one page
# -----------------------------------------------------------------------------

SHARED_PREFIXES=$(printf '%s\n' "$CODES" | awk -F'\t' 'NF { print $2 "\t" $1 }' | sort -u \
                  | awk -F'\t' '{ pages[$1] = pages[$1] ? pages[$1] ", " $2 : $2; count[$1]++ }
                                END { for (p in count) if (count[p] > 1) print "      " p ": " pages[p] }')

if [[ -z "$SHARED_PREFIXES" ]]; then
  record_pass "C-EP-2  every prefix belongs to one page"
else
  record_fail "C-EP-2" "prefix used on more than one page — a code must identify its page:
$SHARED_PREFIXES"
fi

MULTI_PREFIX_PAGES=$(printf '%s\n' "$CODES" | awk -F'\t' 'NF { print $1 "\t" $2 }' | sort -u \
                     | awk -F'\t' '{ prefixes[$1] = prefixes[$1] ? prefixes[$1] ", " $2 : $2; count[$1]++ }
                                   END { for (p in count) if (count[p] > 1) print "      " p ": " prefixes[p] }')
if [[ -n "$MULTI_PREFIX_PAGES" ]]; then
  echo "${C_INFO}   info${C_RESET}  pages owning more than one prefix (allowed — confirm each block is separate, D-EP-1):"
  printf '%s\n' "$MULTI_PREFIX_PAGES"
fi

# -----------------------------------------------------------------------------
# C-EP-3 — no duplicate codes
# -----------------------------------------------------------------------------

DUPLICATES=$(printf '%s\n' "$CODES" | awk -F'\t' 'NF { seen[$3] = seen[$3] ? seen[$3] ", " $1 : $1; count[$3]++ }
                                               END { for (c in count) if (count[c] > 1) print "      " c ": " seen[c] }')

if [[ -z "$DUPLICATES" ]]; then
  record_pass "C-EP-3  no duplicate codes"
else
  record_fail "C-EP-3" "code used on more than one <h2> — give the newer one the next free number:
$DUPLICATES"
fi

print_summary
echo
echo "  Manual checks NOT run by this script:"
echo "    [manual] C-EP-4  (no code renumbered or reused — diff against the last release)"
echo "  Run the .checks.md prose for those."

[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
