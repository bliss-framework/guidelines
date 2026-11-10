#!/usr/bin/env bash
# responsive-overlay.checks.sh
#
# Mechanical Tier-1 ([auto]) checks for responsive-overlay.checks.md.
# Runs C-RO-2, C-RO-4, C-RO-8, and the auto slice of C-RO-9 (landscape
# left/right safe-area red flag). Skips the rest of [semi] (C-RO-1, 3, 5,
# 6, 7, 12, 13, 14) and [manual] (C-RO-10, 11) checks.
#
# Applicability gate (D-RO-1): a component with no opened floating
# panel / overlay is inline — the whole triad is N/A. This script makes
# a best-effort detection and, when it finds no panel signals, reports
# the triad N/A and skips (exit 0). Unlike the CEM gate this is a
# heuristic, so it warns rather than asserts — confirm with C-RO-1.
#
# Usage:
#   ./responsive-overlay.checks.sh <component-package-path> [css-prefix]
#
# Exit codes:
#   0   all auto checks passed (or triad heuristically N/A)
#   1   one or more auto checks failed
#   2   bad usage / target not found

set -u

TARGET="${1:-}"
PREFIX="${2:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <component-package-path> [css-prefix]" >&2
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

# Locate the CSS source dir (src/css, else src, else the package root).
CSS_DIR="$TARGET/src/css"
[[ -d "$CSS_DIR" ]] || CSS_DIR="$TARGET/src"
[[ -d "$CSS_DIR" ]] || CSS_DIR="$TARGET"

echo "${C_INFO}Component target:${C_RESET} $TARGET"
echo "${C_INFO}CSS dir:${C_RESET}          $CSS_DIR"
[[ -n "$PREFIX" ]] && echo "${C_INFO}Prefix:${C_RESET}           $PREFIX"
echo

# -----------------------------------------------------------------------------
# Applicability gate (D-RO-1, heuristic) — does the component open a panel?
# -----------------------------------------------------------------------------

# Signals of an OPENED panel: a panel-named class, or JS that anchors / presents
# one (floating-ui, core's resolvePresentation, Popover API, <dialog>, a dialog /
# listbox role). Plain `position: absolute|fixed`, getBoundingClientRect and
# matchMedia are NOT signals — tooltips, drag ghosts, pseudo-element overlays
# (`::after { inset: 0 }`) and layout code use them too.
HAS_PANEL=0
if grep -rqEi "__(panel|dropdown|menu|popup|calendar|listbox|overlay)\b" "$CSS_DIR" 2>/dev/null; then
  HAS_PANEL=1
elif [[ -d "$TARGET/src" ]] && \
     grep -rqE "computePosition|resolvePresentation|showPopover|showModal|popover=|role=[\"']?(dialog|listbox)|['\"](dialog|listbox)['\"]" \
       "$TARGET/src" --include=*.ts --include=*.js 2>/dev/null; then
  HAS_PANEL=1
fi

if [[ "$HAS_PANEL" -eq 0 ]]; then
  record_skip "C-RO-*" "no floating-panel signals (no panel class, no anchoring / presentation / popover / dialog code) — likely inline; triad N/A (D-RO-1 = B). Confirm with C-RO-1."
  echo
  echo "${C_INFO}== Summary ==${C_RESET}"
  echo "  ${C_PASS}Pass${C_RESET}:    $PASS"
  echo "  ${C_FAIL}Fail${C_RESET}:    $FAIL"
  echo "  ${C_SKIP}Skip${C_RESET}:    $SKIP"
  exit 0
fi

echo "${C_INFO}== Running [auto] checks (panel detected) ==${C_RESET}"

# -----------------------------------------------------------------------------
# C-RO-2 — phone breakpoint media query present, single source
# -----------------------------------------------------------------------------

# Only the literal after `max-width:` — not the min-width of a range query.
MQ_LITERALS=$(grep -rhoEi "@media[^{]*max-width:\s*[0-9]+px" "$CSS_DIR" 2>/dev/null \
              | grep -oEi "max-width:\s*[0-9]+px" | grep -oE "[0-9]+px" | sort -u)
MQ_COUNT=$(printf '%s\n' "$MQ_LITERALS" | grep -c "px" || true)

# Core's resolvePresentation picks the phone presentation in JS from the device
# class (touch-primary + the shorter viewport side) — there is no phone @media,
# and the max-width queries left are layout tiers inside a presentation.
IS_JS_PRESENTATION=0
if [[ -d "$TARGET/src" ]] && \
   grep -rqE "resolvePresentation\(" "$TARGET/src" --include=*.ts --include=*.js 2>/dev/null; then
  IS_JS_PRESENTATION=1
fi

if [[ "$IS_JS_PRESENTATION" -eq 1 ]]; then
  TIERS=$(printf '%s' "$MQ_LITERALS" | tr '\n' ' ')
  record_pass "C-RO-2  phone presentation comes from core's resolvePresentation (JS device class, D-RO-3 = C) — no phone @media to check${TIERS:+; layout tiers not counted: $TIERS}"
elif [[ "$MQ_COUNT" -eq 0 ]]; then
  record_fail "C-RO-2" "no '@media (max-width: Npx)' block — the panel never switches to phone presentation"
elif [[ "$MQ_COUNT" -eq 1 ]]; then
  record_pass "C-RO-2  single phone breakpoint: $(printf '%s' "$MQ_LITERALS")"
else
  # Multiple distinct max-width literals — could be a legit layered set,
  # but flag it: the phone-vs-anchored switch should key off one value.
  record_fail "C-RO-2" "multiple distinct max-width literals ($(printf '%s' "$MQ_LITERALS" | tr '\n' ' ')) — keep the phone breakpoint in one place (anti-pattern #6). Verify manually if this is intentional."
fi

# -----------------------------------------------------------------------------
# C-RO-4 — no static vh/vw in overlay sizing (must be dvh/dvw)
# -----------------------------------------------------------------------------

BAD_VH=$(grep -rnEi "[^a-z0-9]([0-9]+(\.[0-9]+)?)(vh|vw)\b" "$CSS_DIR" 2>/dev/null \
         | grep -viE "d(vh|vw)|s(vh|vw)|l(vh|vw)" || true)

if [[ -z "$BAD_VH" ]]; then
  record_pass "C-RO-4  no bare vh/vw (dynamic viewport units used)"
else
  N=$(printf '%s\n' "$BAD_VH" | grep -c ":" || true)
  record_fail "C-RO-4" "$N bare vh/vw occurrence(s) — use dvh/dvw so the panel bottom isn't clipped behind the URL bar:
$(printf '%s' "$BAD_VH" | sed 's/^/      /')"
fi

# -----------------------------------------------------------------------------
# C-RO-8 — overscroll-behavior: contain on the scroll container
# -----------------------------------------------------------------------------

if grep -rqEi "overscroll-behavior(-y)?:\s*(contain|none)" "$CSS_DIR" 2>/dev/null; then
  record_pass "C-RO-8  overscroll-behavior: contain/none present"
else
  record_fail "C-RO-8" "no 'overscroll-behavior: contain' — scroll at the list edge will chain to the page behind (unless D-RO-10 = B <dialog>/Popover top-layer; cite it)"
fi

# -----------------------------------------------------------------------------
# C-RO-9 (auto slice) — landscape safe-area red flag: a full-screen sheet
# (fixed + full dynamic-viewport width/height) with NO left/right inset will
# clip its rows under the landscape side nav bar / camera cutout (constraint
# #4, anti-pattern #7). This is the mechanical part of the [semi] C-RO-9;
# top/bottom coverage still needs the prose read.
# -----------------------------------------------------------------------------

HAS_FULLSCREEN=$(grep -rlEi "100dv[hw]|inset:\s*0" "$CSS_DIR" 2>/dev/null | head -1 || true)
if [[ -n "$HAS_FULLSCREEN" ]]; then
  if grep -rqEi "env\(safe-area-inset-(left|right)\)" "$CSS_DIR" 2>/dev/null; then
    record_pass "C-RO-9  full-screen sheet insets left/right (landscape safe-area handled) — confirm top/bottom via prose"
  else
    record_fail "C-RO-9" "full-screen sheet detected but NO env(safe-area-inset-left|right) anywhere in CSS — its rows/search will clip under the landscape side nav bar / camera cutout (anti-pattern #7). Add box-sizing:border-box + four-edge env() on the sheet (constraint #4)."
  fi
else
  record_skip "C-RO-9" "no full-screen sheet signals (100dvh/dvw / inset:0) — confirm applicability via prose"
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
echo "    [semi]   C-RO-1  (applicability gate — confirm the panel is real)"
echo "    [semi]   C-RO-3  (full-screen block uses fixed/inset + dvh/dvw)"
echo "    [semi]   C-RO-5  (positioning engine yields — !important or matchMedia)"
echo "    [semi]   C-RO-6  (explicit close affordance in full-screen)"
echo "    [semi]   C-RO-7  (touch targets >= 44px in phone mode)"
echo "    [semi]   C-RO-9  (top/bottom safe-area on chrome — left/right auto-checked above)"
echo "    [semi]   C-RO-12 (BEM + variable discipline for the mode)"
echo "    [semi]   C-RO-13 (docs cover responsive behavior + viewport-meta duties)"
echo "    [semi]   C-RO-14 (CHANGELOG entry)"
echo "    [manual] C-RO-10 (soft-keyboard behavior on device/emulator)"
echo "    [manual] C-RO-11 (visual smoke test — phone full-screen, tablet anchored)"
echo "  Run the .checks.md prose for those."

[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
