#!/usr/bin/env bash
# base-variables.checks.sh
#
# Mechanical Tier-1 ([auto]) checks for base-variables.checks.md.
# Skips [semi] (needs context) and [manual] (needs judgment) checks.
#
# Usage:
#   ./base-variables.checks.sh <component-package-path> [<css-prefix>]
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

if [[ -z "$CSS_PREFIX" ]] && [[ -f "$TARGET/component-variables.manifest.json" ]]; then
  CSS_PREFIX=$(grep -oE '"prefix"\s*:\s*"[a-z]+"' \
               "$TARGET/component-variables.manifest.json" 2>/dev/null | \
               head -1 | grep -oE '"[a-z]+"$' | tr -d '"')
fi

if [[ -z "$CSS_PREFIX" ]]; then
  echo "ERROR: CSS prefix not provided and not found in manifest" >&2
  exit 2
fi

echo "${C_INFO}Component target:${C_RESET} $TARGET"
echo "${C_INFO}CSS prefix:${C_RESET}      $CSS_PREFIX"
echo

echo "${C_INFO}== Running [auto] checks ==${C_RESET}"

# -----------------------------------------------------------------------------
# C-BV-1 — Every visible color resolves through a variable
#   Same as C-CSS-8. Re-run here for the base-variables triad.
# -----------------------------------------------------------------------------

mapfile -t HARDCODED < <(
  grep -nE "(background|color|border|box-shadow|fill|stroke):\s*(#[0-9a-f]|rgb)" \
    "$CSS_DIR"/*.css 2>/dev/null | \
    grep -vE "/variables\.css:|/dark-mode\.css:"
)

if [[ "${#HARDCODED[@]}" -eq 0 ]]; then
  record_pass "C-BV-1  every visible color resolves through a variable"
else
  printf "        %s\n" "${HARDCODED[@]:0:5}"
  record_fail "C-BV-1" "${#HARDCODED[@]} hardcoded color literal(s) in feature files"
fi

# -----------------------------------------------------------------------------
# C-BV-2 — Every var(--base-*) read has a fallback
#   A read with no fallback looks like `var(--base-foo)` with no comma inside.
# -----------------------------------------------------------------------------

# Strip block comments first to avoid false positives in docs.
STRIPPED=$(mktemp)
cat "$CSS_DIR"/*.css 2>/dev/null | \
  tr '\n' '\f' | \
  sed -E 's|/\*[^*]*\*+([^/*][^*]*\*+)*/||g' | \
  tr '\f' '\n' > "$STRIPPED"

# Pattern: var(--base-NAME) with NOTHING between the name and the closing paren.
NO_FALLBACK=$(grep -nE "var\(--base-[a-z][a-z0-9-]*\)" "$STRIPPED" 2>/dev/null | wc -l)
rm -f "$STRIPPED"

if [[ "$NO_FALLBACK" -eq 0 ]]; then
  record_pass "C-BV-2  every var(--base-*) read has a fallback"
else
  STRIPPED=$(mktemp)
  cat "$CSS_DIR"/*.css 2>/dev/null | \
    tr '\n' '\f' | \
    sed -E 's|/\*[^*]*\*+([^/*][^*]*\*+)*/||g' | \
    tr '\f' '\n' > "$STRIPPED"
  grep -nE "var\(--base-[a-z][a-z0-9-]*\)" "$STRIPPED" 2>/dev/null | head -5 | sed 's|^|        |'
  rm -f "$STRIPPED"
  record_fail "C-BV-2" "$NO_FALLBACK var(--base-*) read(s) without fallback"
fi

# -----------------------------------------------------------------------------
# C-BV-3 — :host (or container) declares every component-local variable
#   For every --<prefix>-NAME consumed, it must also be declared somewhere
#   under :host { ... } in variables.css (or .container).
# -----------------------------------------------------------------------------

VARS_FILE="$CSS_DIR/variables.css"
if [[ ! -f "$VARS_FILE" ]]; then
  record_skip "C-BV-3" "variables.css not found"
else
  # We only require a definition for variables consumed BARE — `var(--ms-X)`
  # with no fallback. Variables consumed with a fallback chain — `var(--ms-X,
  # var(--ms-Y, …))` — are deliberate consumer-override hooks and don't need
  # to be declared with a default (the chain resolves them).

  # Strip block comments so we don't pick up vars from docs.
  STRIPPED=$(mktemp)
  cat "$CSS_DIR"/*.css 2>/dev/null | \
    tr '\n' '\f' | \
    sed -E 's|/\*[^*]*\*+([^/*][^*]*\*+)*/||g' | \
    tr '\f' '\n' > "$STRIPPED"

  # Consumed BARE: var(--<prefix>-NAME) with no comma before ')'.
  CONSUMED_BARE=$(grep -hoE "var\(--${CSS_PREFIX}-[a-z][a-z0-9-]*\)" "$STRIPPED" 2>/dev/null | \
                  grep -oE "\-\-${CSS_PREFIX}-[a-z][a-z0-9-]*" | sort -u)
  rm -f "$STRIPPED"

  # Defined (any line that declares --<prefix>-X: value)
  DEFINED=$(grep -hE "^\s*--${CSS_PREFIX}-[a-z][a-z0-9-]*:" "$VARS_FILE" 2>/dev/null | \
            grep -oE "\-\-${CSS_PREFIX}-[a-z][a-z0-9-]*" | sort -u)

  if [[ -z "$CONSUMED_BARE" ]]; then
    record_pass "C-BV-3  no bare --${CSS_PREFIX}-* reads (all have fallback chains)"
  else
    MISSING=()
    while IFS= read -r v; do
      [[ -z "$v" ]] && continue
      if ! echo "$DEFINED" | grep -qFx -- "$v"; then
        MISSING+=("$v")
      fi
    done <<< "$CONSUMED_BARE"

    if [[ "${#MISSING[@]}" -eq 0 ]]; then
      C_COUNT=$(echo "$CONSUMED_BARE" | wc -l)
      record_pass "C-BV-3  every bare-consumed --${CSS_PREFIX}-* var is defined ($C_COUNT vars; fallback-chained reads are exempt)"
    else
      printf "        bare-read but not defined: %s\n" "${MISSING[@]:0:5}"
      record_fail "C-BV-3" "${#MISSING[@]} --${CSS_PREFIX}-* var(s) bare-read but not defined"
    fi
  fi
fi

# -----------------------------------------------------------------------------
# C-BV-5 — Manifest exists and is exported
# -----------------------------------------------------------------------------

MANIFEST="$TARGET/component-variables.manifest.json"
PKG="$TARGET/package.json"

if [[ ! -f "$MANIFEST" ]]; then
  record_fail "C-BV-5" "component-variables.manifest.json missing at package root"
elif [[ ! -f "$PKG" ]]; then
  record_skip "C-BV-5" "package.json missing — can't verify export"
elif grep -qE '"\./manifest"' "$PKG" 2>/dev/null || \
     grep -qE '"component-variables.manifest.json"' "$PKG" 2>/dev/null; then
  record_pass "C-BV-5  manifest exists and is exported via package.json"
else
  record_fail "C-BV-5" "manifest exists but is not exported in package.json"
fi

# -----------------------------------------------------------------------------
# C-BV-6 — Manifest entries match the code
#   Every baseVariables[].name should be read in variables.css.
#   Every componentVariables[].name should be defined on the container.
#   Requires `jq` if available; falls back to a tolerant regex parse otherwise.
# -----------------------------------------------------------------------------

if [[ ! -f "$MANIFEST" ]]; then
  record_skip "C-BV-6" "manifest not found"
elif [[ ! -f "$VARS_FILE" ]]; then
  record_skip "C-BV-6" "variables.css not found"
else
  if command -v jq >/dev/null 2>&1; then
    MANIFEST_BASE=$(jq -r '.baseVariables[]?.name // empty' "$MANIFEST" 2>/dev/null)
    MANIFEST_COMP=$(jq -r '.componentVariables[]?.name // empty' "$MANIFEST" 2>/dev/null)
  else
    # Fallback: greedy regex
    MANIFEST_BASE=$(grep -oE '"name"\s*:\s*"base-[^"]+"' "$MANIFEST" 2>/dev/null | \
                    grep -oE '"base-[^"]+' | tr -d '"')
    MANIFEST_COMP=$(grep -oE "\"name\"\s*:\s*\"${CSS_PREFIX}-[^\"]+\"" "$MANIFEST" 2>/dev/null | \
                    grep -oE "\"${CSS_PREFIX}-[^\"]+" | tr -d '"')
  fi

  PHANTOM_BASE=()
  while IFS= read -r v; do
    [[ -z "$v" ]] && continue
    if ! grep -qE "var\(--${v}[,)]" "$VARS_FILE" 2>/dev/null; then
      PHANTOM_BASE+=("$v")
    fi
  done <<< "$MANIFEST_BASE"

  PHANTOM_COMP=()
  while IFS= read -r v; do
    [[ -z "$v" ]] && continue
    if ! grep -qE "^\s*--${v}\s*:" "$VARS_FILE" 2>/dev/null; then
      PHANTOM_COMP+=("$v")
    fi
  done <<< "$MANIFEST_COMP"

  TOTAL_PHANTOM=$((${#PHANTOM_BASE[@]} + ${#PHANTOM_COMP[@]}))
  if [[ "$TOTAL_PHANTOM" -eq 0 ]]; then
    record_pass "C-BV-6  manifest entries match the code (no phantoms)"
  else
    if [[ "${#PHANTOM_BASE[@]}" -gt 0 ]]; then
      printf "        manifest baseVariables not read in CSS: %s\n" "${PHANTOM_BASE[*]:0:5}"
    fi
    if [[ "${#PHANTOM_COMP[@]}" -gt 0 ]]; then
      printf "        manifest componentVariables not defined in CSS: %s\n" "${PHANTOM_COMP[*]:0:5}"
    fi
    record_fail "C-BV-6" "$TOTAL_PHANTOM manifest entry(ies) don't match the code"
  fi
fi

# -----------------------------------------------------------------------------
# C-BV-9 — No --base-* reads outside variables.css (feature files use --<prefix>-*)
# -----------------------------------------------------------------------------

mapfile -t BASE_OUTSIDE < <(
  grep -nE "var\(--base-" "$CSS_DIR"/*.css 2>/dev/null | \
    grep -vE "/variables\.css:"
)

if [[ "${#BASE_OUTSIDE[@]}" -eq 0 ]]; then
  record_pass "C-BV-9  no --base-* reads outside variables.css"
else
  printf "        %s\n" "${BASE_OUTSIDE[@]:0:5}"
  record_fail "C-BV-9" "${#BASE_OUTSIDE[@]} --base-* read(s) outside variables.css"
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
echo "    [semi]   C-BV-4  (prefix uniqueness — needs cross-repo check)"
echo "    [semi]   C-BV-7  (fallback chains match canonical patterns)"
echo "    [semi]   C-BV-12 (CHANGELOG entry — concreteness is judgment)"
echo "    [semi]   C-BV-13 (input controls consume --base-input-size-*-height)"
echo "    [semi]   C-BV-14 (tooltip geometry consumes --base-tooltip-* scale)"
echo "    [manual] C-BV-8  (README documents the contract)"
echo "    [manual] C-BV-10 (standalone render — browser)"
echo "    [manual] C-BV-11 (theme override end-to-end — browser)"
echo "  Run the .checks.md prose for those, or use /validate-base-variables."

[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
