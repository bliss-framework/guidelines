#!/usr/bin/env bash
# css-structure.checks.sh
#
# Mechanical Tier-1 ([auto]) checks for css-structure.checks.md.
# Skips [semi] (needs context) and [manual] (needs judgment) checks.
#
# Usage:
#   ./css-structure.checks.sh <component-package-path> [<css-prefix>]
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
if [[ -d "$TARGET/src/lib/components" ]] && \
   find "$TARGET/src/lib" -maxdepth 4 -name "*.svelte" -print -quit 2>/dev/null | grep -q .; then
  IS_SVELTE=1
fi

if [[ "$IS_SVELTE" -eq 1 ]]; then
  CSS_DIR="$TARGET/src/lib/styles"
else
  CSS_DIR="$TARGET/src/css"
fi

if [[ ! -d "$CSS_DIR" ]]; then
  echo "ERROR: CSS directory not found at $CSS_DIR" >&2
  exit 2
fi

# Try to discover CSS prefix from manifest if not provided
if [[ -z "$CSS_PREFIX" ]] && [[ -f "$TARGET/component-variables.manifest.json" ]]; then
  CSS_PREFIX=$(grep -oE '"prefix"\s*:\s*"[a-z]+"' \
               "$TARGET/component-variables.manifest.json" 2>/dev/null | \
               head -1 | grep -oE '"[a-z]+"$' | tr -d '"')
fi

echo "${C_INFO}Component target:${C_RESET} $TARGET"
echo "${C_INFO}CSS directory:${C_RESET}   $CSS_DIR"
echo "${C_INFO}CSS prefix:${C_RESET}      ${CSS_PREFIX:-<unknown>}"
echo

echo "${C_INFO}== Running [auto] checks ==${C_RESET}"

# -----------------------------------------------------------------------------
# C-CSS-1 — Canonical file set present
#   Tier-1: main.css, variables.css, base.css, dark-mode.css
#   Tier-2: controls.css, floating.css, states.css, animations.css
# -----------------------------------------------------------------------------

CANONICAL=(main.css variables.css base.css dark-mode.css \
           controls.css floating.css states.css animations.css)
MISSING=()
for f in "${CANONICAL[@]}"; do
  [[ -f "$CSS_DIR/$f" ]] || MISSING+=("$f")
done
if [[ "${#MISSING[@]}" -eq 0 ]]; then
  record_pass "C-CSS-1  canonical file set present (8/8 files)"
else
  printf "        missing: %s\n" "${MISSING[*]}"
  record_fail "C-CSS-1" "${#MISSING[@]} canonical file(s) missing"
fi

# -----------------------------------------------------------------------------
# C-CSS-2 — No underscore-prefixed file names
# -----------------------------------------------------------------------------

UNDERSCORED=$(find "$CSS_DIR" -maxdepth 1 -name "_*.css" 2>/dev/null | wc -l)
if [[ "$UNDERSCORED" -eq 0 ]]; then
  record_pass "C-CSS-2  no underscore-prefixed file names"
else
  find "$CSS_DIR" -maxdepth 1 -name "_*.css" 2>/dev/null | sed 's|^|        |'
  record_fail "C-CSS-2" "$UNDERSCORED underscore-prefixed file(s)"
fi

# -----------------------------------------------------------------------------
# C-CSS-3 — @layer declared and used
# -----------------------------------------------------------------------------

MAIN="$CSS_DIR/main.css"
if [[ ! -f "$MAIN" ]]; then
  record_skip "C-CSS-3" "main.css not found"
else
  LAYER_COUNT=$(grep -cE "^\s*@layer\s+variables\s*,\s*component\s*,\s*overrides\s*;" "$MAIN" 2>/dev/null)
  IMPORT_COUNT=$(grep -cE "^\s*@import\s" "$MAIN" 2>/dev/null)
  IMPORT_NO_LAYER=$(grep -E "^\s*@import\s" "$MAIN" 2>/dev/null | \
                    grep -cvE "layer\s*\(" || true)
  if [[ "$LAYER_COUNT" -eq 1 ]] && [[ "$IMPORT_NO_LAYER" -eq 0 ]]; then
    record_pass "C-CSS-3  @layer declared and every @import uses layer()"
  else
    if [[ "$LAYER_COUNT" -ne 1 ]]; then
      record_fail "C-CSS-3" "expected exactly 1 '@layer variables, component, overrides;' declaration, found $LAYER_COUNT"
    fi
    if [[ "$IMPORT_NO_LAYER" -gt 0 ]]; then
      grep -nE "^\s*@import\s" "$MAIN" 2>/dev/null | \
        grep -vE "layer\s*\(" | head -5 | sed 's|^|        |'
      record_fail "C-CSS-3" "$IMPORT_NO_LAYER @import line(s) without layer()"
    fi
  fi
fi

# -----------------------------------------------------------------------------
# C-CSS-4 — Empty Tier-2 file has stub comment
# -----------------------------------------------------------------------------

MISSING_STUB=()
for f in controls.css floating.css states.css animations.css; do
  path="$CSS_DIR/$f"
  [[ -f "$path" ]] || continue
  # If file has any non-blank non-comment content, skip
  if grep -qE "^[^/\s]" "$path" 2>/dev/null; then continue; fi
  # File is "empty" (only comments/whitespace) — must have a stub on line 1
  head -1 "$path" | grep -qE "^\s*/\*.*\*/\s*$|^\s*/\*" || MISSING_STUB+=("$f")
done

if [[ "${#MISSING_STUB[@]}" -eq 0 ]]; then
  record_pass "C-CSS-4  empty Tier-2 files have stub comments"
else
  printf "        missing stub in: %s\n" "${MISSING_STUB[*]}"
  record_fail "C-CSS-4" "${#MISSING_STUB[@]} empty file(s) without stub comment"
fi

# -----------------------------------------------------------------------------
# C-CSS-5 — Every file imported by main.css
# -----------------------------------------------------------------------------

if [[ ! -f "$MAIN" ]]; then
  record_skip "C-CSS-5" "main.css not found"
else
  ORPHANS=()
  for f in "$CSS_DIR"/*.css; do
    base=$(basename "$f")
    [[ "$base" == "main.css" ]] && continue
    if ! grep -qE "@import.*['\"]\./${base}['\"]" "$MAIN" 2>/dev/null; then
      ORPHANS+=("$base")
    fi
  done
  if [[ "${#ORPHANS[@]}" -eq 0 ]]; then
    record_pass "C-CSS-5  every file imported by main.css"
  else
    printf "        orphan: %s\n" "${ORPHANS[*]}"
    record_fail "C-CSS-5" "${#ORPHANS[@]} orphan file(s) not imported"
  fi
fi

# -----------------------------------------------------------------------------
# C-CSS-6 — Section banners on files > 100 lines
# -----------------------------------------------------------------------------

LONG_NO_BANNERS=()
for f in "$CSS_DIR"/*.css; do
  base=$(basename "$f")
  [[ "$base" == "main.css" ]] && continue
  lines=$(wc -l < "$f")
  if [[ "$lines" -gt 100 ]]; then
    grep -qE "=========|==========" "$f" || LONG_NO_BANNERS+=("$base ($lines lines)")
  fi
done

if [[ "${#LONG_NO_BANNERS[@]}" -eq 0 ]]; then
  record_pass "C-CSS-6  section banners present on files > 100 lines"
else
  printf "        %s\n" "${LONG_NO_BANNERS[@]}"
  record_fail "C-CSS-6" "${#LONG_NO_BANNERS[@]} long file(s) without section banners"
fi

# -----------------------------------------------------------------------------
# C-CSS-7 — BEM convention followed
#   Same regex as C-NC-8 in naming-conventions.checks.sh.
# -----------------------------------------------------------------------------

if [[ -z "$CSS_PREFIX" ]]; then
  record_skip "C-CSS-7" "CSS prefix not provided and not found in manifest (pass as 2nd arg)"
else
  STRIPPED=$(mktemp)
  cat "$CSS_DIR"/*.css 2>/dev/null | \
    tr '\n' '\f' | \
    sed -E 's|/\*[^*]*\*+([^/*][^*]*\*+)*/||g' | \
    tr '\f' '\n' | \
    sed -E "s/url\([^)]*\)//g; s/'[^']*'//g; s/\"[^\"]*\"//g" | \
    sed -E 's/:host-context\([^)]*\)//g; s/:host\(\[[^]]*\]\)//g' \
    > "$STRIPPED"

  mapfile -t BAD_BEM < <(
    grep -hEo "\.[a-z][a-z0-9_-]+" "$STRIPPED" 2>/dev/null | sort -u | \
      grep -vE "^\.(${CSS_PREFIX}(__[a-z][a-z0-9-]*)?(--[a-z][a-z0-9-]*)?|${CSS_PREFIX}-container)$"
  )
  rm -f "$STRIPPED"

  if [[ "${#BAD_BEM[@]}" -eq 0 ]]; then
    record_pass "C-CSS-7  BEM convention followed (prefix '$CSS_PREFIX')"
  else
    printf "        %s\n" "${BAD_BEM[@]:0:10}"
    record_fail "C-CSS-7" "${#BAD_BEM[@]} class(es) don't follow BEM with prefix .${CSS_PREFIX}"
  fi
fi

# -----------------------------------------------------------------------------
# C-CSS-8 — No hardcoded colors in feature files
#   variables.css and dark-mode.css are the only files that may hold literals.
# -----------------------------------------------------------------------------

mapfile -t HARDCODED < <(
  grep -nE "(background|color|border|box-shadow|fill|stroke):\s*(#[0-9a-f]|rgb)" \
    "$CSS_DIR"/*.css 2>/dev/null | \
    grep -vE "/variables\.css:|/dark-mode\.css:"
)

if [[ "${#HARDCODED[@]}" -eq 0 ]]; then
  record_pass "C-CSS-8  no hardcoded colors in feature files"
else
  printf "        %s\n" "${HARDCODED[@]:0:5}"
  record_fail "C-CSS-8" "${#HARDCODED[@]} hardcoded color literal(s) in feature files"
fi

# -----------------------------------------------------------------------------
# C-CSS-11 — main.css has no rules
# -----------------------------------------------------------------------------

if [[ ! -f "$MAIN" ]]; then
  record_skip "C-CSS-11" "main.css not found"
else
  # Strip block comments first; then any remaining non-@-prefixed,
  # non-blank line is a "rule" (a selector or property declaration).
  STRIPPED_MAIN=$(mktemp)
  cat "$MAIN" | \
    tr '\n' '\f' | \
    sed -E 's|/\*[^*]*\*+([^/*][^*]*\*+)*/||g' | \
    tr '\f' '\n' > "$STRIPPED_MAIN"
  RULE_LINES=$(grep -E "^[^@/[:space:]]" "$STRIPPED_MAIN" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$RULE_LINES" -eq 0 ]]; then
    record_pass "C-CSS-11 main.css contains only @layer / @import / comments"
  else
    grep -nE "^[^@/[:space:]]" "$STRIPPED_MAIN" 2>/dev/null | head -5 | sed 's|^|        |'
    record_fail "C-CSS-11" "$RULE_LINES selector rule(s) in main.css"
  fi
  rm -f "$STRIPPED_MAIN"
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
echo "    [semi]   C-CSS-10 (layer contract documented in README — accuracy is judgment)"
echo "    [semi]   C-CSS-12 (bundle size sanity — requires running the build)"
echo "    [manual] C-CSS-9  (no mixed-bag files — requires reading each file)"
echo "  Run the .checks.md prose for those, or use /validate-css-structure."

[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
