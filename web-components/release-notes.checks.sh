#!/usr/bin/env bash
# release-notes.checks.sh
#
# Mechanical Tier-1 ([auto]) checks for release-notes.checks.md.
# Runs C-RN-1 … C-RN-9. Skips [semi] C-RN-10 / C-RN-11 and [manual]
# C-RN-12 (they need npm / judgment).
#
# Usage:
#   ./release-notes.checks.sh <component-package-path>
#
# The package path is the directory holding package.json and
# release-notes/. CHANGELOG.md and README.md are looked up there first,
# then in the git workspace root (monorepos keep them at the root).
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
  echo
  echo "  Checks NOT run by this script:"
  echo "    [semi]   C-RN-10 (Requirements match package.json), C-RN-11 (baseline)"
  echo "    [manual] C-RN-12 (notes cover the CHANGELOG)"
  echo "  Run the .checks.md prose for those."
}

echo "${C_INFO}Component target:${C_RESET} $TARGET"
echo

# Find a file in the package, else in the workspace root.
find_doc() {
  local name="$1"
  if [[ -f "$TARGET/$name" ]]; then echo "$TARGET/$name"; return; fi
  local root
  root="$(git -C "$TARGET" rev-parse --show-toplevel 2>/dev/null)" || return
  [[ -f "$root/$name" ]] && echo "$root/$name"
}

NOTES_DIR="$TARGET/release-notes"
CHANGELOG="$(find_doc CHANGELOG.md)"
README="$(find_doc README.md)"
PKG_JSON="$TARGET/package.json"

if [[ ! -d "$NOTES_DIR" ]]; then
  record_fail "C-RN-1" "no release-notes/ folder — the convention isn't adopted yet; write the notes for the next publish (D-RN-3)"
  record_skip "C-RN-2 … C-RN-9" "nothing to check without release-notes/"
  print_summary
  exit 1
fi

VERSION_RE='^[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?$'

shopt -s nullglob
NOTE_PATHS=("$NOTES_DIR"/*)
shopt -u nullglob

NOTE_FILES=()     # valid "<version>.md" paths
NOTE_VERSIONS=()  # their versions
BAD_NAMES=()
for P in "${NOTE_PATHS[@]}"; do
  NAME="$(basename "$P")"
  BASE="${NAME%.md}"
  if [[ -f "$P" && "$NAME" == *.md && "$BASE" =~ $VERSION_RE ]]; then
    NOTE_FILES+=("$P"); NOTE_VERSIONS+=("$BASE")
  else
    BAD_NAMES+=("      $NAME")
  fi
done

has_notes() {
  local v
  for v in "${NOTE_VERSIONS[@]}"; do [[ "$v" == "$1" ]] && return 0; done
  return 1
}

# -----------------------------------------------------------------------------
# C-RN-1 — every [PUBLISHED] version since adoption has notes
# -----------------------------------------------------------------------------

if [[ -z "$CHANGELOG" ]]; then
  record_skip "C-RN-1" "no CHANGELOG.md found in the package or workspace root"
elif [[ ${#NOTE_VERSIONS[@]} -eq 0 ]]; then
  record_fail "C-RN-1" "release-notes/ has no <version>.md files"
else
  # CHANGELOG headings, top-down: "<version>\t<published 0|1>"
  HEADINGS=$(grep -E '^## \[[0-9]+\.[0-9]+\.[0-9]+[^]]*\]' "$CHANGELOG" \
             | sed -E 's/^## \[([^]]+)\].*/\1\t&/' \
             | awk -F'\t' '{ print $1 "\t" ($2 ~ /\[PUBLISHED\][[:space:]]*$/ ? 1 : 0) }')

  # The adoption point: the lowest CHANGELOG heading that has a notes file.
  OLDEST_LINE=0; N=0
  while IFS=$'\t' read -r V PUB; do
    N=$((N+1))
    has_notes "$V" && OLDEST_LINE=$N
  done <<< "$HEADINGS"

  MISSING=(); PENDING=""
  N=0
  while IFS=$'\t' read -r V PUB; do
    N=$((N+1))
    [[ "$N" -gt "$OLDEST_LINE" ]] && break
    has_notes "$V" && continue
    if [[ "$PUB" == 1 ]]; then MISSING+=("      $V"); else PENDING="$V"; fi
  done <<< "$HEADINGS"

  if [[ "$OLDEST_LINE" -eq 0 ]]; then
    record_fail "C-RN-1" "no notes file matches a CHANGELOG version heading"
  elif [[ ${#MISSING[@]} -eq 0 ]]; then
    record_pass "C-RN-1  every published version since adoption has notes"
  else
    record_fail "C-RN-1" "published versions without release-notes/<version>.md (⚠️ exception only if it never reached npm):
$(printf '%s\n' "${MISSING[@]}")"
  fi

  # The WIP section (topmost, unpublished) without notes: pending, not a failure.
  WIP=$(printf '%s\n' "$HEADINGS" | head -1)
  WIP_V="${WIP%%$'\t'*}"; WIP_PUB="${WIP##*$'\t'}"
  if [[ "$WIP_PUB" == 0 ]] && ! has_notes "$WIP_V"; then
    echo "${C_INFO}   info${C_RESET}  WIP $WIP_V has no notes yet — /publish drafts them (Step 1)"
  fi
fi

# -----------------------------------------------------------------------------
# C-RN-2 — file names are exact versions
# -----------------------------------------------------------------------------

if [[ ${#BAD_NAMES[@]} -eq 0 ]]; then
  record_pass "C-RN-2  every file in release-notes/ is <version>.md"
else
  record_fail "C-RN-2" "not a '<X.Y.Z[-rcNN]>.md' file name:
$(printf '%s\n' "${BAD_NAMES[@]}")"
fi

# Headings outside code fences: "<line>\t<level>\t<text>".
list_headings() {
  awk '/^(```|~~~)/ { fence = !fence; next }
       !fence && /^#+ / { level = index($0, " ") - 1; print NR "\t" level "\t" substr($0, level + 2) }' "$1"
}

# GitHub heading slug: lowercase; ASCII punctuation except - and _ dropped;
# common Unicode punctuation dropped; spaces -> "-". Duplicates get -1, -2, …
# (handled by the caller).
slugify() {
  awk '{
    s = tolower($0)
    gsub(/[!"#$%&'"'"'()*+,.\/:;<=>?@\[\\\]^`{|}~]/, "", s)
    gsub(/—|–|·|→|←|…|“|”|‘|’|×|✅|❌/, "", s)
    gsub(/ /, "-", s)
    print s
  }'
}

CANON_ORDER=("Contents" "Requirements" "Upgrade checklist" "Breaking changes" "Behaviour changes" "New features" "New API" "Visible changes without a migration" "Fixes" "Internal")

canon_index() {
  local h="$1" i
  [[ "$h" == "New features — "* ]] && h="New features"
  for i in "${!CANON_ORDER[@]}"; do
    [[ "${CANON_ORDER[$i]}" == "$h" ]] && { echo "$i"; return; }
  done
  echo "-1"
}

HDR_FAILS=(); SEC_FAILS=(); TOC_FAILS=(); ANCHOR_FAILS=(); TASK_FAILS=()

for F in "${NOTE_FILES[@]}"; do
  NAME="$(basename "$F")"; V="${NAME%.md}"
  CONTENT="$(tr -d '\r' < "$F")"

  # --- C-RN-3 — header -------------------------------------------------------
  LINE1="$(printf '%s\n' "$CONTENT" | head -1)"
  if [[ ! "$LINE1" =~ ^#\ .+\ ${V//./\\.}\ —\ Release\ Notes$ ]]; then
    HDR_FAILS+=("      $NAME: title '$LINE1' — want '# <Display Name> $V — Release Notes'")
  fi
  STATUS="$(printf '%s\n' "$CONTENT" | head -8 | grep -m1 -E '^\*\*Released:\*\* [0-9]{4}-[0-9]{2}-[0-9]{2} · ')"
  if [[ -z "$STATUS" ]]; then
    HDR_FAILS+=("      $NAME: no '**Released:** YYYY-MM-DD · …' status line under the title")
  elif [[ "$V" == *-rc* ]]; then
    [[ "$STATUS" == *'**Pre-release**'* && "$STATUS" == *'@rc'* ]] \
      || HDR_FAILS+=("      $NAME: an rc's status line says **Pre-release** with an '@rc' install command")
  else
    [[ "$STATUS" == *'**Stable**'* ]] \
      || HDR_FAILS+=("      $NAME: a final's status line says **Stable**")
  fi
  HEADER_BLOCK="$(printf '%s\n' "$CONTENT" | awk '/^## /{ exit } { print }')"
  printf '%s\n' "$HEADER_BLOCK" | tr '\n' ' ' | grep -qE '\]\(https://[^)]*CHANGELOG\.md[^)]*\)' \
    || HDR_FAILS+=("      $NAME: header has no absolute https:// link to CHANGELOG.md")

  # --- C-RN-4 — sections ------------------------------------------------------
  H2S="$(printf '%s\n' "$CONTENT" | awk '/^(```|~~~)/ { fence = !fence; next } !fence && /^## / { print substr($0, 4) }')"
  for REQ in "Contents" "Requirements" "Upgrade checklist"; do
    printf '%s\n' "$H2S" | grep -qxF "$REQ" || SEC_FAILS+=("      $NAME: missing '## $REQ'")
  done
  LAST=-1
  while IFS= read -r H; do
    [[ -z "$H" ]] && continue
    IDX="$(canon_index "$H")"
    if [[ "$IDX" -lt 0 ]]; then
      SEC_FAILS+=("      $NAME: '## $H' is not a canonical section")
    elif [[ "$IDX" -lt "$LAST" ]]; then
      SEC_FAILS+=("      $NAME: '## $H' is out of order")
    else
      LAST="$IDX"
    fi
  done <<< "$H2S"

  # --- C-RN-5 / C-RN-6 — contents and anchors --------------------------------
  TMP_F="$(mktemp)"; printf '%s\n' "$CONTENT" > "$TMP_F"
  SLUGS="$(list_headings "$TMP_F" | cut -f3 | slugify \
           | awk '{ n = seen[$0]++; print (n ? $0 "-" n : $0) }')"

  CONTENTS_LINKS="$(printf '%s\n' "$CONTENT" \
    | awk '/^## Contents/ { on = 1; next } on && /^## / { exit } on' \
    | grep -oE '\]\(#[^)]+\)' | sed -E 's/^\]\(#//; s/\)$//')"
  AFTER_SLUGS="$(printf '%s\n' "$CONTENT" \
    | awk '/^(```|~~~)/ { fence = !fence; next } /^## Contents/ { on = 1; next } on && !fence && /^## / { print substr($0, 4) }' \
    | slugify)"
  if [[ "$CONTENTS_LINKS" != "$AFTER_SLUGS" ]]; then
    TOC_FAILS+=("      $NAME: Contents [$(echo $CONTENTS_LINKS | tr ' ' ',')] ≠ sections [$(echo $AFTER_SLUGS | tr ' ' ',')]")
  fi

  while IFS= read -r A; do
    [[ -z "$A" ]] && continue
    printf '%s\n' "$SLUGS" | grep -qxF "$A" || ANCHOR_FAILS+=("      $NAME: #$A")
  done < <(awk '/^(```|~~~)/ { fence = !fence; next } !fence' "$TMP_F" \
           | grep -oE '\]\(#[^)]+\)' | sed -E 's/^\]\(#//; s/\)$//' | sort -u)

  # --- C-RN-7 — checklist task boxes -----------------------------------------
  ITEMS="$(awk '/^## Upgrade checklist/ { on = 1; next } on && /^## / { exit } on && /^[-*] / { print }' "$TMP_F")"
  if [[ -z "$ITEMS" ]]; then
    TASK_FAILS+=("      $NAME: Upgrade checklist has no items (use '- [ ] Nothing required: …')")
  else
    while IFS= read -r ITEM; do
      [[ "$ITEM" == '- [ ] '* ]] || TASK_FAILS+=("      $NAME: ${ITEM:0:70}")
    done <<< "$ITEMS"
  fi
  rm -f "$TMP_F"
done

report() {  # <id> <pass text> <fail text> <array name>
  local -n arr="$4"
  if [[ ${#arr[@]} -eq 0 ]]; then
    record_pass "$1  $2"
  else
    record_fail "$1" "$3:
$(printf '%s\n' "${arr[@]}")"
  fi
}

if [[ ${#NOTE_FILES[@]} -eq 0 ]]; then
  record_skip "C-RN-3 … C-RN-7" "no notes files to check"
else
  report "C-RN-3" "headers: title, status line, absolute CHANGELOG link" "header problems" HDR_FAILS
  report "C-RN-4" "required sections present, canonical and in order" "section problems" SEC_FAILS
  report "C-RN-5" "Contents lists every section in order" "Contents doesn't match the sections" TOC_FAILS
  report "C-RN-6" "every #anchor resolves" "anchors with no matching heading" ANCHOR_FAILS
  report "C-RN-7" "Upgrade-checklist items are '- [ ]' task boxes" "checklist items that aren't task boxes" TASK_FAILS
fi

# -----------------------------------------------------------------------------
# C-RN-8 — release-notes ships in the tarball
# -----------------------------------------------------------------------------

if [[ ! -f "$PKG_JSON" ]]; then
  record_skip "C-RN-8" "no package.json at the target"
elif ! grep -qE '"files"[[:space:]]*:' "$PKG_JSON"; then
  record_pass "C-RN-8  no 'files' field — everything ships, release-notes included"
elif sed -n '/"files"[[:space:]]*:/,/\]/p' "$PKG_JSON" | grep -qE '"\.?/?release-notes/?(\*\*?)?"'; then
  record_pass "C-RN-8  package.json files includes release-notes"
else
  record_fail "C-RN-8" "package.json files doesn't list \"release-notes\" — the upgrade guide won't ship (N/A if D-RN-2 = B)"
fi

# -----------------------------------------------------------------------------
# C-RN-9 — README What's New sections link their notes
# -----------------------------------------------------------------------------

if [[ -z "$README" ]]; then
  record_skip "C-RN-9" "no README.md found"
else
  WN_FAILS=()
  while IFS=$'\t' read -r V BODY; do
    [[ -z "$V" ]] && continue
    has_notes "$V" || continue
    [[ "$BODY" == *"release-notes/$V.md"* ]] || WN_FAILS+=("      What's New in v$V doesn't link release-notes/$V.md")
  done < <(tr -d '\r' < "$README" | awk '
    /^## What'\''s New in v/ { if (v) print v "\t" body; v = substr($0, 19); body = ""; next }
    v && /^## / { print v "\t" body; v = "" ; next }
    v { body = body " " $0 }
    END { if (v) print v "\t" body }')
  report "C-RN-9" "README What's New sections link their notes" "What's New sections without an upgrade-guide link" WN_FAILS
fi

print_summary

[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
