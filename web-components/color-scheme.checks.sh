#!/usr/bin/env bash
# color-scheme.checks.sh
#
# Mechanical Tier-1 ([auto]) checks for color-scheme.checks.md.
# Skips [semi] (needs context) and [manual] (needs judgment) checks.
#
# Usage:
#   ./color-scheme.checks.sh <component-package-path>
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

echo "${C_INFO}Component target:${C_RESET} $TARGET"
echo "${C_INFO}CSS directory:${C_RESET}   $CSS_DIR"
echo

echo "${C_INFO}== Running [auto] checks ==${C_RESET}"

# -----------------------------------------------------------------------------
# C-CS-2 — light-dark() in color fallbacks
#   variables.css color fallbacks should be light-dark() wrapped, not bare hex.
# -----------------------------------------------------------------------------

VARS="$CSS_DIR/variables.css"
if [[ ! -f "$VARS" ]]; then
  record_skip "C-CS-2" "variables.css not found"
else
  # Strip comments first
  STRIPPED=$(mktemp)
  cat "$VARS" | \
    tr '\n' '\f' | \
    sed -E 's|/\*[^*]*\*+([^/*][^*]*\*+)*/||g' | \
    tr '\f' '\n' > "$STRIPPED"

  # Find var(--base-X, #color) patterns — bare hex fallbacks (not wrapped in
  # light-dark()). Skip the documented exceptions, colors the base-css-variables
  # contract keeps the same in both modes:
  #   2.0  --base-<role>-color (the role's fill: primary, secondary, success,
  #        danger, warning, info) and --base-on-<role>-text-color (text on it)
  #   1.x  accent-color* and *-on-accent (removed in 2.0; kept so components
  #        not yet migrated don't fail here)
  # The role's other steps (-hover, -active, -bg-subtle, -text-color) differ
  # per mode, so they are not exempt.
  ROLES='primary|secondary|success|danger|warning|info'
  ALL_BARE=$(grep -nE "var\(--base-[a-z-]+,\s*#[0-9a-f]{3,8}\s*\)" "$STRIPPED" 2>/dev/null | \
             grep -vE "var\(--base-(($ROLES)-color|on-($ROLES)-text-color)," | \
             grep -vE "var\(--base-(accent-color|text-color-on-accent|color-on-accent|text-on-accent)" || true)
  if [[ -z "$ALL_BARE" ]]; then
    BARE_HEX=0
  else
    BARE_HEX=$(echo "$ALL_BARE" | wc -l | tr -d ' ')
  fi
  rm -f "$STRIPPED"

  if [[ "$BARE_HEX" -eq 0 ]]; then
    record_pass "C-CS-2  color fallbacks use light-dark() (role fill / on-role text exceptions excluded)"
  else
    echo "$ALL_BARE" | head -5 | sed 's|^|        |'
    record_fail "C-CS-2" "$BARE_HEX non-exempt bare-hex color fallback(s) not wrapped in light-dark()"
  fi
fi

# -----------------------------------------------------------------------------
# C-CS-5 — Contrast test fixture exists
#   Conventional locations: docs/test/dark-mode.html or e2e/dark-mode.spec.ts
# -----------------------------------------------------------------------------

FOUND_FIXTURE=0
LOCATIONS=()
for path in \
    "$TARGET/docs/test/dark-mode.html" \
    "$TARGET/docs/dark-mode.html" \
    "$TARGET/e2e/dark-mode.spec.ts" \
    "$TARGET/e2e/dark-mode.spec.js" \
    "$TARGET/test/dark-mode.html" \
    "$TARGET/test/dark-mode.spec.ts" \
    "$TARGET/examples-theming.html"; do
  if [[ -f "$path" ]]; then
    FOUND_FIXTURE=1
    LOCATIONS+=("$path")
  fi
done

if [[ "$FOUND_FIXTURE" -eq 1 ]]; then
  record_pass "C-CS-5  contrast test fixture exists (${LOCATIONS[0]})"
else
  record_fail "C-CS-5" "no dark-mode fixture found at conventional locations"
fi

# -----------------------------------------------------------------------------
# C-CS-10 (partial) — Hardcoded colors in dedicated tooltip CSS files
#   The full check is [semi] — needs portal-propagation verification.
#   This script catches the smoking-gun case the web-grid bug shipped with:
#   a dedicated tooltip CSS file (e.g. `tooltip.css`) declaring
#   `background: #...` or `color: #...` directly instead of via a var chain.
#   variables.css and dark-mode.css are excluded — they're the only files
#   allowed to hold color literals (per C-CSS-8).
# -----------------------------------------------------------------------------

TOOLTIP_CSS_FILES=$(find "$CSS_DIR" -type f -name "*tooltip*.css" 2>/dev/null | \
                    grep -vE "(variables|dark-mode)\.css$" || true)

if [[ -z "$TOOLTIP_CSS_FILES" ]]; then
  record_skip "C-CS-10" "no dedicated tooltip CSS file detected — run /validate-color-scheme for the full [semi] check (in-shadow / portal / native paths)"
else
  TOTAL_BARE=0
  FAILED_FILES=()
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    STRIPPED=$(mktemp)
    cat "$f" | tr '\n' '\f' | \
      sed -E 's|/\*[^*]*\*+([^/*][^*]*\*+)*/||g' | tr '\f' '\n' > "$STRIPPED"
    BARE=$(grep -cE "(background|background-color|color|border-color)\s*:\s*#[0-9a-f]{3,8}" "$STRIPPED" 2>/dev/null | head -1 || echo 0)
    rm -f "$STRIPPED"
    [[ -z "$BARE" ]] && BARE=0
    if [[ "$BARE" -gt 0 ]]; then
      TOTAL_BARE=$((TOTAL_BARE + BARE))
      FAILED_FILES+=("$f ($BARE literal(s))")
    fi
  done <<< "$TOOLTIP_CSS_FILES"

  if [[ "$TOTAL_BARE" -eq 0 ]]; then
    record_pass "C-CS-10 (auto portion) tooltip CSS file(s) have no hardcoded color literals — verify portal-propagation via the [semi] path"
  else
    for entry in "${FAILED_FILES[@]}"; do
      echo "        $entry"
    done
    record_fail "C-CS-10" "$TOTAL_BARE hardcoded color literal(s) in tooltip CSS file(s) — replace with var(--<prefix>-tooltip-*, var(--base-tooltip-*, light-dark(...))) chain"
  fi
fi

# -----------------------------------------------------------------------------
# C-CS-3 — the canonical theme block (web components on core)
#   :host([data-context-theme="dark"|"light"]) then :host([data-theme="dark"|"light"]),
#   each setting color-scheme, per-instance AFTER context in the same file.
# C-CS-11 — no retired theme mechanisms
#   :host-context( / prefers-color-scheme / a second per-instance switch in CSS,
#   matchMedia('(prefers-color-scheme…') in the sources.
# Comments are stripped first, so explanatory comments that name them pass.
# -----------------------------------------------------------------------------

if [[ "$IS_SVELTE" -eq 1 ]]; then
  record_skip "C-CS-3" "Svelte component — container rules per theme-container.md"
  record_skip "C-CS-11" "Svelte component — container rules per theme-container.md"
else
  CS_TMP=$(mktemp -d)
  # One comment-stripped copy per CSS file (same stripping as C-CS-2)
  while IFS= read -r f; do
    rel="${f#"$CSS_DIR"/}"
    mkdir -p "$CS_TMP/$(dirname "$rel")"
    tr '\n' '\f' < "$f" | sed -E 's|/\*[^*]*\*+([^/*][^*]*\*+)*/||g' | tr '\f' '\n' > "$CS_TMP/$rel"
  done < <(find "$CSS_DIR" -name "*.css" -type f 2>/dev/null)

  # Line of the first `<selector> … {` block that sets the given color-scheme, in one file.
  # A selector list (`:host([data-theme="dark"]), .x[data-theme="dark"] {`) counts.
  rule_line() {  # $1 file, $2 attribute, $3 value
    awk -v attr="$2" -v val="$3" '
      BEGIN { pat = ":host\\(\\[" attr "=[\"\x27]" val "[\"\x27]\\]\\)" }
      $0 ~ pat { start = NR; insel = 1 }
      insel && /\{/ { inblock = 1; insel = 0 }
      inblock && $0 ~ ("color-scheme:[[:space:]]*" val) { print start; exit }
      inblock && /\}/ { inblock = 0; start = 0 }
    ' "$1"
  }

  CANON_FILE=""; CANON_OK=0; CANON_ORDER_BAD=0
  while IFS= read -r f; do
    cd_=$(rule_line "$f" "data-context-theme" "dark"); cl_=$(rule_line "$f" "data-context-theme" "light")
    td_=$(rule_line "$f" "data-theme" "dark");         tl_=$(rule_line "$f" "data-theme" "light")
    if [[ -n "$cd_" && -n "$cl_" && -n "$td_" && -n "$tl_" ]]; then
      CANON_FILE="${f#"$CS_TMP"/}"
      ctx_max=$(( cd_ > cl_ ? cd_ : cl_ )); inst_min=$(( td_ < tl_ ? td_ : tl_ ))
      if [[ "$inst_min" -gt "$ctx_max" ]]; then CANON_OK=1; else CANON_ORDER_BAD=1; fi
      break
    fi
  done < <(find "$CS_TMP" -name "*.css" -type f)

  if [[ "$CANON_OK" -eq 1 ]]; then
    record_pass "C-CS-3  canonical theme block (data-context-theme, then data-theme) in $CANON_FILE"
  elif [[ "$CANON_ORDER_BAD" -eq 1 ]]; then
    record_fail "C-CS-3" "$CANON_FILE has the four rules but data-theme is not declared after data-context-theme (the per-instance switch must win)"
  else
    record_fail "C-CS-3" "no file has all four rules: :host([data-context-theme=\"dark\"|\"light\"]) and :host([data-theme=\"dark\"|\"light\"]) setting color-scheme (see color-scheme.md → The canonical block)"
  fi

  RETIRED=$(grep -rnE ':host-context\(|prefers-color-scheme|:host\(\[(data-bs-theme|theme)[]=]|:host\(\.(dark|light)\)' "$CS_TMP" 2>/dev/null | sed "s|^$CS_TMP/||" || true)
  JS_DETECT=$(grep -rnE "matchMedia\([^)]*prefers-color-scheme" "$TARGET/src" --include=*.ts --include=*.js 2>/dev/null \
              | grep -vE '\.(test|spec)\.(ts|js):' | sed "s|^$TARGET/||" || true)
  rm -rf "$CS_TMP"

  if [[ -z "$RETIRED" && -z "$JS_DETECT" ]]; then
    record_pass "C-CS-11 no retired theme mechanisms (:host-context, prefers-color-scheme, JS detection, second per-instance switch)"
  else
    [[ -n "$RETIRED" ]] && echo "$RETIRED" | head -6 | sed 's|^|        css: |'
    [[ -n "$JS_DETECT" ]] && echo "$JS_DETECT" | head -4 | sed 's|^|        js:  |'
    N=$(printf '%s\n%s\n' "$RETIRED" "$JS_DETECT" | grep -c . || true)
    record_fail "C-CS-11" "$N retired theme mechanism(s) — core detects the page signal (data-context-theme); data-theme is the only per-instance switch"
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
echo "    [semi]   C-CS-1  (no bare :host { color-scheme } — needs selector classification)"
echo "    [semi]   C-CS-6  (Playwright contrast assertions — requires running tests)"
echo "    [semi]   C-CS-9  (CHANGELOG entry — concreteness is judgment)"
echo "    [semi]   C-CS-10 (full tooltip check — needs portal-propagation verification;"
echo "                     hardcoded-color smoking gun is auto-checked above when a"
echo "                     dedicated tooltip CSS file exists)"
echo "    [manual] C-CS-4  (per-instance override works — browser)"
echo "    [manual] C-CS-7  (visual smoke test — browser)"
echo "    [manual] C-CS-8  (README documents the theming contract)"
echo "  Run the .checks.md prose for those, or use /validate-color-scheme."

[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
