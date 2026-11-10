#!/usr/bin/env bash
# core-adoption.checks.sh
#
# Mechanical Tier-1 ([auto]) checks for core-adoption.checks.md:
# C-CA-1, 2, 4, 5, 8, 11, 13. Skips [semi] (C-CA-3, 6, 7, 9, 10) and [manual] (C-CA-12).
#
# Applicability gate (D-CA-1): web components only. A package with no custom element
# (no `extends BlissElement`, no `customElements.define`) is reported N/A (exit 0).
#
# Usage:
#   ./core-adoption.checks.sh <component-package-path>
#   (monorepo: the package folder, e.g. web-grid/packages/web-grid — not the repo root)
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
SRC="$TARGET/src"
[[ -d "$SRC" ]] || SRC="$TARGET"

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

# Source files: shipped .ts — outside tests / dist / node_modules / src/dev (dev playgrounds).
src_grep() {
  grep -rnE "$1" "$SRC" --include=*.ts 2>/dev/null \
    | grep -v "/node_modules/" | grep -v "/dist/" | grep -v "/src/dev/" | grep -vE "\.test\.ts:|\.spec\.ts:"
}

# The input row around a `file:line:` hit (rows often span several lines): 6 lines either side.
row_of() {
  local file="${1%%:*}" rest="${1#*:}"
  local line="${rest%%:*}"
  local from=$(( line > 6 ? line - 6 : 1 ))
  sed -n "${from},$(( line + 6 ))p" "$file"
}

# Keep the hits whose row does NOT match the pattern in $1.
rows_without() {
  local hit
  while IFS= read -r hit; do
    [[ -z "$hit" ]] && continue
    row_of "$hit" | grep -qE "$1" || echo "$hit"
  done
}

echo "${C_INFO}== core-adoption checks: $TARGET ==${C_RESET}"

# --- Gate (D-CA-1) -------------------------------------------------------------
if ! src_grep "extends BlissElement|customElements\.define|define\(" >/dev/null; then
  echo "${C_SKIP}N/A${C_RESET} no custom element found — Svelte / non-element package (D-CA-1 = B); see C-CA-12 (parity)."
  exit 0
fi

# --- C-CA-1 --------------------------------------------------------------------
if ! src_grep "extends BlissElement" >/dev/null; then
  record_fail "C-CA-1" "no class extends BlissElement"
else
  OWN=$(src_grep "static (get )?observedAttributes|attributeChangedCallback\s*\(")
  if [[ -n "$OWN" ]]; then record_fail "C-CA-1" "own attribute plumbing:"$'\n'"$OWN"
  else record_pass "C-CA-1 extends BlissElement, no own observedAttributes / attributeChangedCallback"; fi
fi

# --- C-CA-2 --------------------------------------------------------------------
BARE=$(src_grep "toBool\(\s*\)")
PRES=$(src_grep "toBool\('presence'\)" | rows_without "attribute: '(disabled|readonly)'")
if [[ -n "$BARE$PRES" ]]; then
  record_fail "C-CA-2" "toBool without a mode, or 'presence' outside disabled/readonly:"$'\n'"$BARE$PRES"
else
  record_pass "C-CA-2 every toBool names its mode; 'presence' only on disabled / readonly"
fi

# --- C-CA-4 --------------------------------------------------------------------
# A chained no-argument call (`state.tr.replaceSelectionWith(n).scrollIntoView()`) is
# ProseMirror's transaction method, not the DOM one.
SIV=$(src_grep "\.scrollIntoView\(" | grep -vE "\)\.scrollIntoView\(\)|core-adoption: allow")
if [[ -n "$SIV" ]]; then record_fail "C-CA-4" "scrollIntoView() — use scrollIntoContainer():"$'\n'"$SIV"
else record_pass "C-CA-4 no scrollIntoView() on inner elements"; fi

# --- C-CA-5 --------------------------------------------------------------------
COPY=$(src_grep "(function|private|#)\s*_?(findScrollableAncestor|findScrollContainer|scrollIntoContainer)\s*\(")
FUI=$(src_grep "from '@floating-ui/dom'")
if [[ -n "$COPY$FUI" ]]; then
  record_fail "C-CA-5" "private scroll helper or direct floating-ui import:"$'\n'"$COPY$FUI"
else
  record_pass "C-CA-5 no private scroll-container copy, no direct @floating-ui/dom import"
fi

# --- C-CA-8 --------------------------------------------------------------------
CON=$(src_grep "\bconsole\.(log|info|warn|error|debug)\(" | grep -v "core-adoption: allow")
if [[ -n "$CON" ]]; then record_fail "C-CA-8" "console.* in source — use the instance loggers:"$'\n'"$CON"
else record_pass "C-CA-8 no console.* in component source"; fi

# --- C-CA-11 -------------------------------------------------------------------
# Monorepo packages keep e2e/ + test/ at the repo root (two levels up).
E2E_ROOT="$TARGET"
[[ -d "$E2E_ROOT/e2e" ]] || { [[ -d "$TARGET/../../e2e" ]] && E2E_ROOT="$(cd "$TARGET/../.." && pwd)"; }
if [[ -d "$E2E_ROOT/e2e" ]]; then
  EX=$(grep -rnE "(goto\(|PAGE\s*=\s*)[^)]*examples-" "$E2E_ROOT/e2e" 2>/dev/null | grep -v "examples.spec.ts")
  if [[ -n "$EX" ]]; then record_fail "C-CA-11" "specs open example pages (use test/ fixtures):"$'\n'"$EX"
  elif ! compgen -G "$E2E_ROOT/test/*.html" >/dev/null && ! compgen -G "$E2E_ROOT/*/test/*.html" >/dev/null; then
    record_fail "C-CA-11" "no test/*.html fixture pages (looked in test/ and <site-root>/test/)"
  else record_pass "C-CA-11 e2e specs target test/ fixtures"; fi
else
  record_skip "C-CA-11" "no e2e/ folder"
fi

# --- C-CA-13 -------------------------------------------------------------------
if src_grep "formAssociated\s*=\s*true" >/dev/null; then
  NR=$(src_grep "attribute: 'disabled'" | rows_without "shouldReflect: true")
  if [[ -n "$NR" ]]; then record_fail "C-CA-13" "disabled does not reflect on a form-associated element:"$'\n'"$NR"
  else record_pass "C-CA-13 disabled reflects (form-associated)"; fi
else
  record_skip "C-CA-13" "not form-associated (D-CA-4 = B)"
fi

# --- C-CA-14 -------------------------------------------------------------------
BLISS_FILES=$(src_grep "extends BlissElement" | cut -d: -f1 | sort -u)
PUB=""
for f in $BLISS_FILES; do
  H=$(grep -nE "^\s*(public\s+)?(override\s+)?(async\s+)?(reinit|update|connect|disconnect|removedCallback|destroyCallback|environmentChanged|viewportChanged|sizeChanged|directionChanged|themeChanged|disabledChanged|setFormatError|engineConfig|createController|eventContext)\s*\(" "$f" | grep -vE "protected|private" | sed "s|^|$f:|")
  [[ -n "$H" ]] && PUB+="$H"$'
'
done
if [[ -n "$PUB" ]]; then record_fail "C-CA-14" "core hook overridden as public (keep it protected; batch writes = setAttributes()):"$'
'"$PUB"
else record_pass "C-CA-14 core hooks stay protected"; fi

# --- C-CA-15 -------------------------------------------------------------------
# Custom CSS the one canonical way: both input rows + createCustomStyles(), no private slot code.
if src_grep "extends BlissElement" >/dev/null; then
  CS_FAIL=""
  src_grep "configKey: 'customStyles'" >/dev/null || CS_FAIL+="missing input row customStyles (attribute custom-styles)"$'\n'
  src_grep "configKey: 'getCustomStylesCallback'" >/dev/null || CS_FAIL+="missing input row getCustomStylesCallback"$'\n'
  src_grep "createCustomStyles(<.*>)?\(" >/dev/null || CS_FAIL+="no createCustomStyles() call"$'\n'
  SLOT=$(src_grep "createStyleSlot\(|#applyCustomStyles.*createElement\('style'\)|data-[a-z]+-injected" | grep -v "core-adoption: allow")
  [[ -n "$SLOT" ]] && CS_FAIL+="private custom-CSS code (use createCustomStyles):"$'\n'"$SLOT"$'\n'
  # Every registered tag applies it: its class's file, or its direct base class's file (a shared
  # satellite base), calls createCustomStyles() — not just any one class in the package.
  NOCS=""
  while IFS= read -r reg; do
    [[ -z "$reg" ]] && continue
    tag=$(sed -nE "s/.*registerComponent\(\s*['\"]([a-z0-9-]+)['\"]\s*,\s*([A-Za-z0-9_]+).*/\1/p" <<<"$reg")
    cls=$(sed -nE "s/.*registerComponent\(\s*['\"]([a-z0-9-]+)['\"]\s*,\s*([A-Za-z0-9_]+).*/\2/p" <<<"$reg")
    [[ -z "$cls" ]] && continue
    def=$(src_grep "class $cls(<[^>]*>)? extends [A-Za-z0-9_]+" | head -1)
    file=${def%%:*}
    [[ -z "$file" ]] && continue
    grep -qE "createCustomStyles(<.*>)?\(" "$file" && continue
    base=$(sed -nE "s/.*class $cls(<[^>]*>)? extends ([A-Za-z0-9_]+).*/\2/p" <<<"$def" | head -1)
    if [[ -n "$base" && "$base" != "BlissElement" ]]; then
      bdef=$(src_grep "class $base(<[^>]*>)? extends " | head -1)
      [[ -n "$bdef" ]] && grep -qE "createCustomStyles(<.*>)?\(" "${bdef%%:*}" && continue
    fi
    NOCS+="$tag ($cls): no createCustomStyles() in its class or its base class"$'
'
  done < <(src_grep "registerComponent\(\s*['\"][a-z0-9-]+['\"]\s*,\s*[A-Za-z0-9_]+")
  [[ -n "$NOCS" ]] && CS_FAIL+="$NOCS"
  POS=$(grep -rnE -A8 "createCustomStyles(<.*>)?\(" "$SRC" --include=*.ts 2>/dev/null | grep -vE "\.test\.ts|/node_modules/|/dist/" | grep -E "position:")
  [[ -n "$POS" ]] && CS_FAIL+="createCustomStyles with a position option (use core's default):"$'\n'"$POS"$'\n'
  if [[ -n "$CS_FAIL" ]]; then record_fail "C-CA-15" "$CS_FAIL"
  else record_pass "C-CA-15 custom CSS via createCustomStyles, the canonical way"; fi
else
  record_skip "C-CA-15" "no BlissElement"
fi

# --- C-CA-16 -------------------------------------------------------------------
# Input properties typed: `export interface <ElementClass>… extends <…Config…> {}` merged into the class.
CLASSES=$(src_grep "export (abstract )?class [A-Za-z0-9_]+(<[^>]*>)? extends BlissElement" | sed -E 's/.*class ([A-Za-z0-9_]+).*/\1/' | sort -u)
if [[ -n "$CLASSES" ]]; then
  MISSING=""
  for c in $CLASSES; do
    src_grep "export interface $c(<[^{]*>)? extends [^{]*Config" >/dev/null || MISSING+="$c"$'\n'
  done
  if [[ -n "$MISSING" ]]; then record_fail "C-CA-16" "element class without the typed-inputs merge (export interface <Class> extends <ElementConfig> {}):"$'\n'"$MISSING"
  else record_pass "C-CA-16 input properties typed via the config-interface merge"; fi
else
  record_skip "C-CA-16" "no exported BlissElement class"
fi

# --- C-CA-17 -------------------------------------------------------------------
# Persisted UI state the one way: createStateStore() + storageKey / loadStateCallback / saveStateCallback rows;
# no own localStorage / sessionStorage code.
if src_grep "extends BlissElement|localStorage|sessionStorage" >/dev/null; then
  PS_FAIL=""
  OWN=$(src_grep "(localStorage|sessionStorage)\s*(\?\.|\.|\[)|typeof (localStorage|sessionStorage)" | grep -vE "^\S+:[0-9]+:\s*(//|\*|/\*)" | grep -v "core-adoption: allow")
  [[ -n "$OWN" ]] && PS_FAIL+="own localStorage / sessionStorage code (use createStateStore):"$'\n'"$OWN"$'\n'
  if src_grep "createStateStore(<.*>)?\(" >/dev/null; then
    src_grep "configKey: 'storageKey'" >/dev/null || PS_FAIL+="createStateStore without the input row storageKey (attribute storage-key)"$'\n'
    src_grep "configKey: 'loadStateCallback'" >/dev/null || PS_FAIL+="createStateStore without the input row loadStateCallback"$'\n'
    src_grep "configKey: 'saveStateCallback'" >/dev/null || PS_FAIL+="createStateStore without the input row saveStateCallback"$'\n'
  fi
  if [[ -n "$PS_FAIL" ]]; then record_fail "C-CA-17" "$PS_FAIL"
  else record_pass "C-CA-17 persisted UI state via createStateStore (or none)"; fi
else
  record_skip "C-CA-17" "no BlissElement, no storage code"
fi

# --- Summary -------------------------------------------------------------------
echo
echo "${C_INFO}== Summary ==${C_RESET}"
echo "  ${C_PASS}Pass${C_RESET}:    $PASS"
echo "  ${C_FAIL}Fail${C_RESET}:    $FAIL"
echo "  ${C_SKIP}Skip${C_RESET}:    $SKIP"
echo
echo "  Semi / manual checks NOT run by this script:"
echo "    [semi]   C-CA-3  (no 'invalid input table' warning on a running page)"
echo "    [semi]   C-CA-6  (beforeScrollCallback when the component scrolls on its own)"
echo "    [semi]   C-CA-7  (before*Callbacks go through runBeforeCallback*)"
echo "    [semi]   C-CA-9  (loaders via renderLoader)"
echo "    [semi]   C-CA-10 (search via /search)"
echo "    [manual] C-CA-12 (parity copies recorded in docs/parity.md)"
echo "  Run the .checks.md prose for those."

[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
