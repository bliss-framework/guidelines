#!/usr/bin/env bash
# theme-container.checks.sh
#
# Mechanical Tier-1 ([auto]) checks for theme-container.checks.md.
# Skips [semi] (needs context) and [manual] (needs judgment) checks.
#
# Usage:
#   ./theme-container.checks.sh <component-package-path> [<css-prefix>]
#
# Exit codes:
#   0   all auto checks passed
#   1   one or more auto checks failed
#   2   bad usage / target not found

set -u

TARGET="${1:-}"
CSS_PREFIX="${2:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <component-package-path> [<css-prefix>]" >&2
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

# -----------------------------------------------------------------------------
# Detection
# -----------------------------------------------------------------------------

IS_SVELTE=0
IS_WEB_COMPONENT=0

if [[ -d "$TARGET/src/lib/components" ]] && \
   find "$TARGET/src/lib" -maxdepth 4 -name "*.svelte" -print -quit 2>/dev/null | grep -q .; then
  IS_SVELTE=1
fi

if find "$TARGET/src" -maxdepth 3 -name "*.ts" -print0 2>/dev/null | \
   xargs -0 grep -lE "customElements\.define" 2>/dev/null | grep -q .; then
  IS_WEB_COMPONENT=1
fi

if [[ "$IS_SVELTE" -eq 0 && "$IS_WEB_COMPONENT" -eq 0 ]]; then
  echo "ERROR: could not detect web-component or Svelte component in $TARGET" >&2
  exit 2
fi

# CSS dir + prefix
if [[ "$IS_SVELTE" -eq 1 ]]; then
  CSS_DIR="$TARGET/src/lib/styles"
else
  CSS_DIR="$TARGET/src/css"
fi
if [[ ! -d "$CSS_DIR" ]]; then
  echo "ERROR: CSS directory not found at $CSS_DIR" >&2
  exit 2
fi

if [[ -z "$CSS_PREFIX" ]] && [[ -f "$TARGET/component-variables.manifest.json" ]]; then
  CSS_PREFIX=$(grep -oE '"prefix"\s*:\s*"[a-z]+"' \
               "$TARGET/component-variables.manifest.json" 2>/dev/null | \
               head -1 | grep -oE '"[a-z]+"$' | tr -d '"')
fi

if [[ -z "$CSS_PREFIX" ]]; then
  echo "ERROR: CSS prefix not provided and not found in manifest (pass as 2nd arg)" >&2
  exit 2
fi

# Container selector pattern
if [[ "$IS_WEB_COMPONENT" -eq 1 ]]; then
  CONTAINER_SEL=":host"
  CONTAINER_REGEX=":host"
else
  CONTAINER_SEL=".${CSS_PREFIX}-container"
  CONTAINER_REGEX="\\.${CSS_PREFIX}-container"
fi

echo "${C_INFO}Component target:${C_RESET} $TARGET"
if [[ "$IS_WEB_COMPONENT" -eq 1 ]]; then echo "${C_INFO}Detected:${C_RESET} web-component"; fi
if [[ "$IS_SVELTE" -eq 1 ]];        then echo "${C_INFO}Detected:${C_RESET} Svelte component"; fi
echo "${C_INFO}CSS prefix:${C_RESET} $CSS_PREFIX"
echo "${C_INFO}Container:${C_RESET}  $CONTAINER_SEL"
echo

echo "${C_INFO}== Running [auto] checks ==${C_RESET}"

# -----------------------------------------------------------------------------
# C-TC-1 — No --<prefix>-* on :root / html / body
# -----------------------------------------------------------------------------

mapfile -t BAD_ROOT < <(
  grep -rnE "(^|\s):root\s*\{|^\s*html\s*\{|^\s*body\s*\{" "$CSS_DIR"/*.css 2>/dev/null | \
    awk -F: '{print $1":"$2}'
)

# For each :root/html/body block found, scan the next 30 lines for --<prefix>-* declarations.
HIT_COUNT=0
HIT_DETAILS=""
for entry in "${BAD_ROOT[@]}"; do
  file="${entry%:*}"
  lineno="${entry##*:}"
  [[ -z "$lineno" ]] && continue
  # Read 30 lines starting at the matched line
  block=$(awk -v start="$lineno" -v end=$((lineno+30)) 'NR>=start && NR<=end' "$file" 2>/dev/null)
  # Check for --<prefix>-* declarations in this slice
  if echo "$block" | grep -qE "^\s*--${CSS_PREFIX}-[a-z][a-z0-9-]*:"; then
    HIT_COUNT=$((HIT_COUNT+1))
    HIT_DETAILS="${HIT_DETAILS}        $file:$lineno (--${CSS_PREFIX}-* in root/html/body block)\n"
  fi
done

if [[ "$HIT_COUNT" -eq 0 ]]; then
  record_pass "C-TC-1  no --${CSS_PREFIX}-* declarations on :root / html / body"
else
  printf "${HIT_DETAILS}"
  record_fail "C-TC-1" "$HIT_COUNT root-level block(s) declare --${CSS_PREFIX}-*"
fi

# -----------------------------------------------------------------------------
# C-TC-3 — --<prefix>-bg chains through --base-main-bg with light-dark()
# -----------------------------------------------------------------------------

VARS="$CSS_DIR/variables.css"
if [[ ! -f "$VARS" ]]; then
  record_skip "C-TC-3" "variables.css not found"
else
  # Look for: --<prefix>-bg: var(--base-main-bg, light-dark(<color>, <color>));
  if grep -qE "^\s*--${CSS_PREFIX}-bg\s*:\s*var\(\s*--base-main-bg\s*,\s*light-dark\(" "$VARS" 2>/dev/null; then
    record_pass "C-TC-3  --${CSS_PREFIX}-bg chains through --base-main-bg with light-dark()"
  else
    # Maybe present but not in canonical form
    if grep -qE "^\s*--${CSS_PREFIX}-bg\s*:" "$VARS" 2>/dev/null; then
      grep -nE "^\s*--${CSS_PREFIX}-bg\s*:" "$VARS" 2>/dev/null | head -1 | sed 's|^|        |'
      record_fail "C-TC-3" "--${CSS_PREFIX}-bg exists but doesn't chain through --base-main-bg with light-dark()"
    else
      record_skip "C-TC-3" "no --${CSS_PREFIX}-bg declaration found (D-TC-3 = B/C — wrapper or transparent)"
    fi
  fi
fi

# -----------------------------------------------------------------------------
# C-TC-5 — Per-instance data-theme selectors exist (dark AND light)
# -----------------------------------------------------------------------------

if [[ "$IS_WEB_COMPONENT" -eq 1 ]]; then
  DARK_SEL=":host\\(\\[data-theme=\"dark\"\\]\\)"
  LIGHT_SEL=":host\\(\\[data-theme=\"light\"\\]\\)"
else
  DARK_SEL="\\.${CSS_PREFIX}-container\\[data-theme=\"dark\"\\]"
  LIGHT_SEL="\\.${CSS_PREFIX}-container\\[data-theme=\"light\"\\]"
fi

DARK_HITS=$(grep -rEc "$DARK_SEL" "$CSS_DIR"/*.css 2>/dev/null | \
            awk -F: 'BEGIN{s=0} {s+=$2} END{print s}')
LIGHT_HITS=$(grep -rEc "$LIGHT_SEL" "$CSS_DIR"/*.css 2>/dev/null | \
             awk -F: 'BEGIN{s=0} {s+=$2} END{print s}')

if [[ "$DARK_HITS" -gt 0 ]] && [[ "$LIGHT_HITS" -gt 0 ]]; then
  record_pass "C-TC-5  per-instance data-theme selectors exist (dark: $DARK_HITS, light: $LIGHT_HITS)"
elif [[ "$DARK_HITS" -eq 0 ]] && [[ "$LIGHT_HITS" -eq 0 ]]; then
  record_fail "C-TC-5" "no [data-theme=\"dark\"] or [data-theme=\"light\"] selectors found"
elif [[ "$DARK_HITS" -eq 0 ]]; then
  record_fail "C-TC-5" "dark selector missing (only light present — asymmetric)"
else
  record_fail "C-TC-5" "light selector missing (only dark present — asymmetric)"
fi

# -----------------------------------------------------------------------------
# C-TC-7 — display: block (or inline-block) on container; not contents
# -----------------------------------------------------------------------------

# Find display declarations within a container-selector block; we approximate
# by scanning each CSS file for the container selector, then looking at the
# next 30 lines for a `display:` declaration.

CONTAINER_PATTERN="^\s*${CONTAINER_REGEX}\s*[\{,]"
mapfile -t CONTAINER_BLOCKS < <(
  grep -rnE "$CONTAINER_PATTERN" "$CSS_DIR"/*.css 2>/dev/null | \
    awk -F: '{print $1":"$2}'
)

FOUND_DISPLAY=0
FOUND_CONTENTS=0
for entry in "${CONTAINER_BLOCKS[@]}"; do
  file="${entry%:*}"
  lineno="${entry##*:}"
  [[ -z "$lineno" ]] && continue
  block=$(awk -v start="$lineno" -v end=$((lineno+30)) 'NR>=start && NR<=end' "$file" 2>/dev/null)
  if echo "$block" | grep -qE "^\s*display\s*:\s*contents"; then
    FOUND_CONTENTS=1
  fi
  if echo "$block" | grep -qE "^\s*display\s*:\s*(block|inline-block|flex|inline-flex|grid)"; then
    FOUND_DISPLAY=1
  fi
done

if [[ "$FOUND_CONTENTS" -eq 1 ]]; then
  record_fail "C-TC-7" "display: contents declared on container (forbidden — breaks host as layout box)"
elif [[ "$FOUND_DISPLAY" -eq 1 ]]; then
  record_pass "C-TC-7  container has valid display declaration"
else
  record_fail "C-TC-7" "no display declaration found on container $CONTAINER_SEL"
fi

# -----------------------------------------------------------------------------
# C-TC-15 — FOUC rule tag matches customElements.define (web-component only)
# -----------------------------------------------------------------------------

if [[ "$IS_WEB_COMPONENT" -eq 1 ]]; then
  BASE="$CSS_DIR/base.css"
  if [[ ! -f "$BASE" ]]; then
    record_skip "C-TC-15" "base.css not found"
  else
    # Tag(s) used in :not(:defined) rules
    NOT_DEFINED_TAGS=$(grep -hEo "^\s*[a-z][a-z0-9-]+\s*:not\(:defined\)" "$BASE" 2>/dev/null | \
                       grep -oE "^[a-z][a-z0-9-]+" | sort -u)
    # Registered tag(s) from TS source
    DEFINED_TAGS=$(grep -rhE "customElements\.define\(['\"][^'\"]+" "$TARGET/src" 2>/dev/null | \
                   grep -oE "['\"][^'\"]+['\"]" | tr -d "'\"" | sort -u)

    if [[ -z "$NOT_DEFINED_TAGS" ]]; then
      # No FOUC rule — could be D-TC-9 = B (no FOUC prevention)
      record_skip "C-TC-15" "no <tag>:not(:defined) rule found in base.css (D-TC-9 = B?)"
    elif [[ -z "$DEFINED_TAGS" ]]; then
      record_fail "C-TC-15" "FOUC rule found but no customElements.define call in src/"
    else
      # Every :not(:defined) tag must appear in DEFINED_TAGS, and vice versa
      MISMATCH=""
      while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue
        if ! echo "$DEFINED_TAGS" | grep -qx "$tag"; then
          MISMATCH="${MISMATCH}        FOUC rule for '$tag' but no customElements.define('$tag', ...) found\n"
        fi
      done <<< "$NOT_DEFINED_TAGS"
      while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue
        if ! echo "$NOT_DEFINED_TAGS" | grep -qx "$tag"; then
          MISMATCH="${MISMATCH}        customElements.define('$tag') but no FOUC rule for it\n"
        fi
      done <<< "$DEFINED_TAGS"

      if [[ -z "$MISMATCH" ]]; then
        record_pass "C-TC-15 FOUC rule tag(s) match customElements.define"
      else
        printf "${MISMATCH}"
        record_fail "C-TC-15" "FOUC tag(s) don't match registered tag(s)"
      fi
    fi
  fi
else
  record_skip "C-TC-15" "N/A for Svelte component"
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
echo "    [semi]   C-TC-2  (default background — three patterns to recognize)"
echo "    [semi]   C-TC-4  (no bare color-scheme on container — needs selector classification)"
echo "    [semi]   C-TC-6  (dark/light overrides target container — needs selector read)"
echo "    [semi]   C-TC-8  (positioning context — multi-path)"
echo "    [semi]   C-TC-9  (single root container — needs .svelte read for Svelte)"
echo "    [semi]   C-TC-10 (Svelte theme prop forwards — needs .svelte read)"
echo "    [manual] C-TC-11 (README documents container contract)"
echo "    [manual] C-TC-12 (subtree theming smoke test — browser)"
echo "    [manual] C-TC-13 (standalone render works — browser)"
echo "    [manual] C-TC-14 (per-instance override — browser)"
echo "  Run the .checks.md prose for those, or use /validate-theme-container."

[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
