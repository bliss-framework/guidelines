#!/usr/bin/env bash
# publish-command.checks.sh
#
# Mechanical Tier-1 ([auto]) checks for publish-command.checks.md.
# Verifies that a component's .claude/commands/publish.md matches the
# canonical structure defined in publish-command.md.
#
# Usage:
#   ./publish-command.checks.sh <component-repo-path>
#
# Env vars:
#   PUBLISH_REFERENCE  Path to the reference publish.md whose canonical
#                      blocks are treated as the source of truth for
#                      md5 comparisons. Defaults to
#                      C:/Git/KM/web-multiselect/.claude/commands/publish.md
#                      (or, if that's missing, the first publish.md the
#                      script finds under C:/Git/KM/).
#
# Exit codes:
#   0   all auto checks passed
#   1   one or more auto checks failed
#   2   bad usage / target not found

set -u

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <component-repo-path>" >&2
  exit 2
fi
if [[ ! -d "$TARGET" ]]; then
  echo "ERROR: target directory not found: $TARGET" >&2
  exit 2
fi
TARGET="$(cd "$TARGET" && pwd)"

PUBLISH_FILE="$TARGET/.claude/commands/publish.md"

# Default reference: web-multiselect (the file every other component was aligned to)
DEFAULT_REF="C:/Git/KM/web-multiselect/.claude/commands/publish.md"
REFERENCE="${PUBLISH_REFERENCE:-$DEFAULT_REF}"
if [[ ! -f "$REFERENCE" ]]; then
  # Fallback: look anywhere under C:/Git/KM/
  REFERENCE=$(find /c/Git/KM -path '*/.claude/commands/publish.md' 2>/dev/null | head -1)
fi

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

echo "${C_INFO}Component target:${C_RESET} $TARGET"
echo "${C_INFO}Reference:${C_RESET}       $REFERENCE"
echo

echo "${C_INFO}== Running [auto] checks ==${C_RESET}"

# -----------------------------------------------------------------------------
# C-PC-0 — publish.md exists at .claude/commands/
# -----------------------------------------------------------------------------

if [[ -f "$PUBLISH_FILE" ]]; then
  record_pass "C-PC-0  publish.md exists at .claude/commands/"
else
  record_fail "C-PC-0" "no .claude/commands/publish.md at $TARGET — scaffold from publish-command.md"
  echo
  echo "${C_INFO}== Summary ==${C_RESET}"
  echo "  ${C_PASS}Pass${C_RESET}:    $PASS"
  echo "  ${C_FAIL}Fail${C_RESET}:    $FAIL"
  echo "  ${C_SKIP}Skip${C_RESET}:    $SKIP"
  exit 1
fi

# Quick sanity: bail if the reference file is missing or unreadable
if [[ ! -f "$REFERENCE" ]]; then
  echo "${C_FAIL}ERROR${C_RESET} reference publish.md not found ($REFERENCE) — set PUBLISH_REFERENCE env var"
  exit 2
fi

# -----------------------------------------------------------------------------
# Helper: extract a heading-bounded block from a markdown file.
#   extract_block <file> <start_regex> <end_regex>
# Prints the lines between (and including) the start match and the line
# *before* the next match of end_regex. If end_regex is empty, prints to EOF.
# -----------------------------------------------------------------------------
extract_block() {
  local file="$1" start_re="$2" end_re="$3"
  if [[ -z "$end_re" ]]; then
    awk -v s="$start_re" 'BEGIN{found=0} $0 ~ s {found=1} found {print}' "$file"
  else
    awk -v s="$start_re" -v e="$end_re" '
      BEGIN { found = 0 }
      $0 ~ s { found = 1; print; next }
      found && $0 ~ e { exit }
      found { print }
    ' "$file"
  fi
}

# -----------------------------------------------------------------------------
# C-PC-1 — Canonical section headings present in order
# -----------------------------------------------------------------------------

EXPECTED_HEADINGS=(
  '^## Argument \[canonical\]$'
  '^## Repo layout \[per-repo\]$'
  '^## CHANGELOG convention in this repo \[canonical\]$'
  '^## Resolve versions \[canonical\]$'
  '^## Steps \(in order\)$'
  '^### 1\. Sanity checks \[canonical\]$'
  '^### 2\. Bump version \(if needed\) \[canonical\]$'
  '^### 3\. Finalize CHANGELOG \[canonical\]$'
  '^### 4\. Update README "What.s New" — only if version changed \[canonical\]$'
  '^### 5\. Validate README reflects the release \[canonical\]$'
  '^### 6\. Validate CHANGELOG entries match recent work \[canonical\]$'
  '^### 7\. Run tests \[per-repo\]$'
  '^### 8\. Build the package \[per-repo\]$'
  '^### 9\. Verify the package contents \[per-repo\]$'
  '^### 10\. Commit \[canonical\]$'
  '^### 11\. Report \[canonical\]$'
  '^## Things not to do \[canonical\]$'
)

MISSING_HEADINGS=()
OUT_OF_ORDER=0
LAST_LINE=0

for re in "${EXPECTED_HEADINGS[@]}"; do
  LINE=$(grep -nE "$re" "$PUBLISH_FILE" | head -1 | cut -d: -f1)
  if [[ -z "$LINE" ]]; then
    # Friendly form for the report
    FRIENDLY=$(echo "$re" | sed -E 's/^\^//; s/\$$//; s/\\\././g; s/\\\(/(/g; s/\\\)/)/g; s/\\\[/[/g; s/\\\]/]/g; s/What\.s/What\x27s/')
    MISSING_HEADINGS+=("$FRIENDLY")
  else
    if (( LINE < LAST_LINE )); then
      OUT_OF_ORDER=1
    fi
    LAST_LINE=$LINE
  fi
done

if [[ "${#MISSING_HEADINGS[@]}" -eq 0 && "$OUT_OF_ORDER" -eq 0 ]]; then
  record_pass "C-PC-1  canonical section headings present in order (${#EXPECTED_HEADINGS[@]} headings)"
elif [[ "${#MISSING_HEADINGS[@]}" -gt 0 ]]; then
  record_fail "C-PC-1" "missing or wrongly-tagged headings: ${MISSING_HEADINGS[*]}"
else
  record_fail "C-PC-1" "canonical headings present but out of order — match spec section order in publish-command.md"
fi

# -----------------------------------------------------------------------------
# C-PC-2 — npm view registry pre-check present
# -----------------------------------------------------------------------------

HAS_NPM_VIEW_AT_VERSION=0
HAS_NPM_VIEW_LATEST=0

grep -qE "npm view .+@<NEW_VERSION>"        "$PUBLISH_FILE" && HAS_NPM_VIEW_AT_VERSION=1
grep -qE "npm view .+ version( |$)"         "$PUBLISH_FILE" && HAS_NPM_VIEW_LATEST=1

if [[ "$HAS_NPM_VIEW_AT_VERSION" -eq 1 && "$HAS_NPM_VIEW_LATEST" -eq 1 ]]; then
  record_pass "C-PC-2  npm view registry pre-check present (both calls)"
else
  MISSING=()
  [[ "$HAS_NPM_VIEW_AT_VERSION" -eq 0 ]] && MISSING+=("npm view <PKG>@<NEW_VERSION> (the 'already published?' check)")
  [[ "$HAS_NPM_VIEW_LATEST"     -eq 0 ]] && MISSING+=("npm view <PKG> version (the 'registry drifted?' check)")
  record_fail "C-PC-2" "missing: ${MISSING[*]} — add to Step 1 per publish-command.md"
fi

# -----------------------------------------------------------------------------
# C-PC-3 — Version resolution table byte-identical to canonical
# -----------------------------------------------------------------------------
#
# The table block we compare is the four data rows of the decision table
# (the rows starting with `| \`rc\``, `| \`release\``, `| \`patch\``, etc.).
# These have NO per-repo substitutions — they're pure semver logic.

TABLE_REGEX='^\| `(rc|release|patch|minor|major)`'
TARGET_TABLE=$(grep -E "$TABLE_REGEX" "$PUBLISH_FILE")
REF_TABLE=$(grep -E "$TABLE_REGEX" "$REFERENCE")

if [[ -z "$TARGET_TABLE" ]]; then
  record_fail "C-PC-3" "version-resolution table rows not found — Section 'Resolve versions' missing or restructured"
else
  TARGET_MD5=$(echo "$TARGET_TABLE" | md5sum | cut -d' ' -f1)
  REF_MD5=$(echo "$REF_TABLE" | md5sum | cut -d' ' -f1)

  if [[ "$TARGET_MD5" == "$REF_MD5" ]]; then
    record_pass "C-PC-3  version-resolution table byte-identical to canonical"
  else
    record_fail "C-PC-3" "version-resolution table differs from canonical (target md5: $TARGET_MD5, reference md5: $REF_MD5) — see publish-command.md Section 4"
  fi
fi

# -----------------------------------------------------------------------------
# C-PC-4 — Canonical "Things not to do" first-10 bullets byte-identical
# -----------------------------------------------------------------------------
#
# Compare the contiguous `^- \*\*Do not` bullets at the top of the
# `## Things not to do` section. Per-repo extras come *after* (under a
# `### Repo-specific don'ts` sub-heading) and don't count.

extract_things_block() {
  local f="$1"
  awk '
    BEGIN { in_section = 0; in_bullets = 0 }
    /^## Things not to do/ { in_section = 1; next }
    in_section && /^### / { exit }      # next sub-heading: stop
    in_section && /^## /  { exit }      # next H2: stop
    in_section && /^- \*\*/ { in_bullets = 1; print; next }
    in_bullets && /^$/ { exit }         # blank line after bullets: stop
    in_bullets && /^- / { print }
  ' "$f"
}

TARGET_THINGS=$(extract_things_block "$PUBLISH_FILE")
REF_THINGS=$(extract_things_block "$REFERENCE")

if [[ -z "$TARGET_THINGS" ]]; then
  record_fail "C-PC-4" "'Things not to do' section has no bullets — missing canonical text"
else
  TARGET_MD5=$(echo "$TARGET_THINGS" | md5sum | cut -d' ' -f1)
  REF_MD5=$(echo "$REF_THINGS" | md5sum | cut -d' ' -f1)
  TARGET_COUNT=$(echo "$TARGET_THINGS" | wc -l)
  REF_COUNT=$(echo "$REF_THINGS" | wc -l)

  if [[ "$TARGET_MD5" == "$REF_MD5" ]]; then
    record_pass "C-PC-4  'Things not to do' first-$TARGET_COUNT bullets byte-identical to canonical"
  else
    record_fail "C-PC-4" "'Things not to do' canonical bullets differ from reference (target: $TARGET_COUNT bullets / md5 $TARGET_MD5, reference: $REF_COUNT bullets / md5 $REF_MD5)"
  fi
fi

# -----------------------------------------------------------------------------
# C-PC-5 — Canonical "What's New" format reference present in Step 1
# -----------------------------------------------------------------------------

HAS_RS_REF=0
HAS_C_RS_16=0

grep -qE "readme-structure\.md.*canonical format" "$PUBLISH_FILE" && HAS_RS_REF=1
grep -qE "C-RS-16"                                "$PUBLISH_FILE" && HAS_C_RS_16=1

if [[ "$HAS_RS_REF" -eq 1 && "$HAS_C_RS_16" -eq 1 ]]; then
  record_pass "C-PC-5  Step 1 references canonical What's New format (readme-structure.md + C-RS-16)"
else
  MISSING=()
  [[ "$HAS_RS_REF"  -eq 0 ]] && MISSING+=("link to readme-structure.md 'canonical format'")
  [[ "$HAS_C_RS_16" -eq 0 ]] && MISSING+=("explicit C-RS-16 reference")
  record_fail "C-PC-5" "missing: ${MISSING[*]} — Step 1's draft-What's-New block must point at readme-structure.md and name C-RS-16"
fi

# -----------------------------------------------------------------------------
# C-PC-6 — Commit message format declared in Step 10
# -----------------------------------------------------------------------------

HAS_COMMIT_SUBJECT=0
HAS_CO_AUTHORED=0

grep -qE "^vNEW_VERSION - <one-line summary"            "$PUBLISH_FILE" && HAS_COMMIT_SUBJECT=1
grep -qE "Co-Authored-By: Claude Opus 4\.7"             "$PUBLISH_FILE" && HAS_CO_AUTHORED=1

if [[ "$HAS_COMMIT_SUBJECT" -eq 1 && "$HAS_CO_AUTHORED" -eq 1 ]]; then
  record_pass "C-PC-6  commit message format declared in Step 10"
else
  MISSING=()
  [[ "$HAS_COMMIT_SUBJECT" -eq 0 ]] && MISSING+=("'vNEW_VERSION - <one-line summary>' subject template")
  [[ "$HAS_CO_AUTHORED"    -eq 0 ]] && MISSING+=("'Co-Authored-By: Claude Opus 4.7 (1M context)' trailer")
  record_fail "C-PC-6" "missing in Step 10: ${MISSING[*]}"
fi

# -----------------------------------------------------------------------------
# C-PC-7 — Publish-command spec reference present at top of file
# -----------------------------------------------------------------------------

# Look in the first 30 lines for the reference
TOP=$(head -30 "$PUBLISH_FILE")
if echo "$TOP" | grep -qE "web-components/publish-command\.md"; then
  record_pass "C-PC-7  references publish-command.md spec at top of file"
else
  record_fail "C-PC-7" "no reference to 'web-components/publish-command.md' in the first 30 lines — add intro paragraph anchoring this file to the spec"
fi

# -----------------------------------------------------------------------------
# C-PC-8 — Section [canonical] / [per-repo] tags match the spec table
# -----------------------------------------------------------------------------
#
# Each expected heading appears in EXPECTED_HEADINGS above with its tag baked
# in; if C-PC-1 passed all headings, the tags are already correct. This check
# verifies that a [canonical] tag isn't applied to a [per-repo] section or
# vice versa (the regex match in C-PC-1 already enforces this — so this is a
# direct restatement that aggregates the result).

# Re-walk: enumerate any "## " or "### " heading and check its tag.
TAG_PROBLEMS=()
declare -A WANT_TAG=(
  ["## Argument"]="canonical"
  ["## Repo layout"]="per-repo"
  ["## CHANGELOG convention in this repo"]="canonical"
  ["## Resolve versions"]="canonical"
  ["### 1. Sanity checks"]="canonical"
  ["### 2. Bump version (if needed)"]="canonical"
  ["### 3. Finalize CHANGELOG"]="canonical"
  ["### 5. Validate README reflects the release"]="canonical"
  ["### 6. Validate CHANGELOG entries match recent work"]="canonical"
  ["### 7. Run tests"]="per-repo"
  ["### 8. Build the package"]="per-repo"
  ["### 9. Verify the package contents"]="per-repo"
  ["### 10. Commit"]="canonical"
  ["### 11. Report"]="canonical"
  ["## Things not to do"]="canonical"
)

for heading in "${!WANT_TAG[@]}"; do
  want="${WANT_TAG[$heading]}"
  # find the actual line
  actual=$(grep -F "$heading " "$PUBLISH_FILE" | head -1)
  if [[ -z "$actual" ]]; then
    # Already flagged by C-PC-1
    continue
  fi
  if ! echo "$actual" | grep -qE "\[$want\]$"; then
    TAG_PROBLEMS+=("'$heading' should carry [$want] — got: '$actual'")
  fi
done

if [[ "${#TAG_PROBLEMS[@]}" -eq 0 ]]; then
  record_pass "C-PC-8  section [canonical]/[per-repo] tags match spec"
else
  record_fail "C-PC-8" "tag mismatch(es): ${TAG_PROBLEMS[*]}"
fi

# -----------------------------------------------------------------------------
# C-PC-9 — Draft What's New uses 5–8 bullet count
# -----------------------------------------------------------------------------

if grep -qE "5.{1,3}8 scannable bullets" "$PUBLISH_FILE"; then
  record_pass "C-PC-9  Step 1 draft-What's-New uses 5–8 bullet count target"
else
  record_fail "C-PC-9" "Step 1 draft block doesn't use '5–8 scannable bullets' — older 5–7 phrasing or other variant detected"
fi

# -----------------------------------------------------------------------------
# C-PC-10 — Step 10 stage-list mentions CHANGELOG + README + package.json
# -----------------------------------------------------------------------------

# Extract just the Step 10 block
STEP10_BLOCK=$(awk '
  /^### 10\. Commit/ { in_block = 1; next }
  in_block && /^### / { exit }
  in_block && /^## /  { exit }
  in_block { print }
' "$PUBLISH_FILE")

STAGE_MISSING=()
echo "$STEP10_BLOCK" | grep -qE "CHANGELOG\.md"   || STAGE_MISSING+=("CHANGELOG.md")
echo "$STEP10_BLOCK" | grep -qE "README\.md"      || STAGE_MISSING+=("README.md")
echo "$STEP10_BLOCK" | grep -qE "package\.json"   || STAGE_MISSING+=("package.json")

if [[ "${#STAGE_MISSING[@]}" -eq 0 ]]; then
  record_pass "C-PC-10 Step 10 stage list mentions CHANGELOG + README + package.json"
else
  record_fail "C-PC-10" "Step 10 stage list missing: ${STAGE_MISSING[*]}"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo
echo "${C_INFO}== Summary ==${C_RESET}"
echo "  ${C_PASS}Pass${C_RESET}:    $PASS"
echo "  ${C_FAIL}Fail${C_RESET}:    $FAIL"
echo "  ${C_SKIP}Skip${C_RESET}:    $SKIP"

[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
