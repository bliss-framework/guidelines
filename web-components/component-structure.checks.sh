#!/usr/bin/env bash
# component-structure.checks.sh
#
# Mechanical Tier-1 ([auto]) checks for component-structure.checks.md.
# Skips [semi] (needs context) and [manual] (needs judgment) checks.
#
# Usage:
#   ./component-structure.checks.sh <component-package-path>
#
# Exit codes:
#   0   all auto checks passed
#   1   one or more auto checks failed
#   2   bad usage / target not found
#
# Detects web-component vs Svelte from filesystem signals so per-host
# checks (C-CST-1, C-CST-2) skip cleanly on Svelte targets.

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

# Normalize path
TARGET="$(cd "$TARGET" && pwd)"

PASS=0
FAIL=0
SKIP=0

# Color codes (fallback to plain if not a TTY)
if [[ -t 1 ]]; then
  C_PASS=$'\033[32m'    # green
  C_FAIL=$'\033[31m'    # red
  C_SKIP=$'\033[33m'    # yellow
  C_INFO=$'\033[36m'    # cyan
  C_RESET=$'\033[0m'
else
  C_PASS='' C_FAIL='' C_SKIP='' C_INFO='' C_RESET=''
fi

record_pass() { echo "${C_PASS}✅ PASS${C_RESET} $1"; PASS=$((PASS+1)); }
record_fail() { echo "${C_FAIL}❌ FAIL${C_RESET} $1 — $2"; FAIL=$((FAIL+1)); }
record_skip() { echo "${C_SKIP}⏭  SKIP${C_RESET} $1 — $2"; SKIP=$((SKIP+1)); }

# -----------------------------------------------------------------------------
# Detection prelude — web-component vs Svelte
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
  echo "       Looked for: src/lib/components/*.svelte (Svelte)," >&2
  echo "       customElements.define call in src/**/*.ts (web-component)." >&2
  exit 2
fi

echo "${C_INFO}Component target:${C_RESET} $TARGET"
if [[ "$IS_WEB_COMPONENT" -eq 1 ]]; then echo "${C_INFO}Detected:${C_RESET} web-component"; fi
if [[ "$IS_SVELTE" -eq 1 ]];        then echo "${C_INFO}Detected:${C_RESET} Svelte component"; fi
echo

# -----------------------------------------------------------------------------
# C-CST-1 — Element class with `Element` suffix (web-components only)
# -----------------------------------------------------------------------------
echo "${C_INFO}== Running [auto] checks ==${C_RESET}"

if [[ "$IS_WEB_COMPONENT" -eq 1 ]]; then
  # Accept `extends HTMLElement` directly, or `extends <PascalCaseAlias>`
  # (common pattern: SSR-safe BaseElement = HTMLElement || class {} stub).
  # Also accept the generic parameter form `class X<T> extends Y`.
  ELEMENT_CLASSES=$(grep -rhE "class\s+[A-Z][a-zA-Z0-9]*Element(<[^>]+>)?\s+extends\s+[A-Z][a-zA-Z0-9]+" \
                    "$TARGET/src" 2>/dev/null | wc -l)
  if [[ "$ELEMENT_CLASSES" -ge 1 ]]; then
    record_pass "C-CST-1  Element class with Element suffix exists ($ELEMENT_CLASSES match(es))"
  else
    record_fail "C-CST-1" "no class matching 'class \\w+Element extends \\w+' found in src/"
  fi
else
  record_skip "C-CST-1" "N/A for Svelte component"
fi

# -----------------------------------------------------------------------------
# C-CST-2 — Tag agrees with customElements.define (web-components only)
# -----------------------------------------------------------------------------

if [[ "$IS_WEB_COMPONENT" -eq 1 ]]; then
  TAGS=$(grep -rhE "customElements\.define\(['\"][^'\"]+" "$TARGET/src" 2>/dev/null | \
         grep -oE "['\"][^'\"]+['\"]" | head -1 | tr -d "'\"")
  if [[ -z "$TAGS" ]]; then
    record_fail "C-CST-2" "no customElements.define call found"
  elif ! [[ "$TAGS" =~ ^[a-z]+(-[a-z]+)+$ ]]; then
    record_fail "C-CST-2" "tag '$TAGS' is not kebab-case with mandatory hyphen"
  else
    record_pass "C-CST-2  customElements.define tag '$TAGS' is valid kebab-case"
  fi
else
  record_skip "C-CST-2" "N/A for Svelte component"
fi

# -----------------------------------------------------------------------------
# C-CST-3 / C-CST-11 — Logic class framework-agnostic
#   (For web-components: NO 'svelte' | 'react' | 'vue' imports anywhere in src/)
#   (For Svelte:        NO 'react' | 'vue' imports; 'svelte' runtime imports are
#    permitted in .svelte and .svelte.ts files; Logic .ts files outside those
#    extensions must not import from 'svelte' runtime — but $state/$derived
#    runes are *language* extensions, not runtime imports.)
# -----------------------------------------------------------------------------

if [[ "$IS_WEB_COMPONENT" -eq 1 ]]; then
  HITS=$(grep -rEn "^import\s+.*from\s+['\"](svelte|react|vue|vue/[^'\"]+)['\"]" \
         "$TARGET/src" 2>/dev/null | wc -l)
  if [[ "$HITS" -eq 0 ]]; then
    record_pass "C-CST-3  / C-CST-11  no framework-runtime imports in src/"
  else
    OFFENDERS=$(grep -rEn "^import\s+.*from\s+['\"](svelte|react|vue|vue/[^'\"]+)['\"]" \
                "$TARGET/src" 2>/dev/null | head -5 | sed 's|^|        |')
    record_fail "C-CST-3" "$HITS framework-runtime import(s) in src/ (web-component should be framework-agnostic)"
    printf "%s\n" "$OFFENDERS"
  fi
elif [[ "$IS_SVELTE" -eq 1 ]]; then
  # Svelte: react / vue forbidden anywhere. svelte runtime forbidden in plain .ts
  # files (allowed only in .svelte and .svelte.ts).
  HITS=$(grep -rEn "^import\s+.*from\s+['\"](react|vue|vue/[^'\"]+)['\"]" \
         "$TARGET/src" 2>/dev/null | wc -l)
  if [[ "$HITS" -ne 0 ]]; then
    OFFENDERS=$(grep -rEn "^import\s+.*from\s+['\"](react|vue|vue/[^'\"]+)['\"]" \
                "$TARGET/src" 2>/dev/null | head -5 | sed 's|^|        |')
    record_fail "C-CST-3" "$HITS non-svelte framework-runtime import(s) in Svelte project"
    printf "%s\n" "$OFFENDERS"
  else
    # Find plain .ts files (NOT .svelte.ts, NOT .svelte) that import svelte runtime
    PLAIN_HITS=$(find "$TARGET/src" -name "*.ts" ! -name "*.svelte.ts" 2>/dev/null | \
                 xargs -r grep -lE "^import\s+.*from\s+['\"]svelte['\"]" 2>/dev/null | wc -l)
    if [[ "$PLAIN_HITS" -gt 0 ]]; then
      record_fail "C-CST-11" "$PLAIN_HITS plain .ts file(s) import svelte runtime (allowed only in .svelte / .svelte.ts)"
    else
      record_pass "C-CST-3  / C-CST-11  Svelte-runtime imports confined to .svelte / .svelte.ts; no react/vue"
    fi
  fi
fi

# -----------------------------------------------------------------------------
# C-CST-4 — Service classes don't import each other
#   Heuristic: any .ts file under src/ that does NOT match the Element
#   (web-component.ts) or Logic class file pattern is treated as a candidate
#   Service file. We then check pairwise that no candidate imports another
#   candidate by relative path. types.ts / logger.ts / index.ts / vendor are
#   excluded.
# -----------------------------------------------------------------------------

SRC_DIR="$TARGET/src"
if [[ "$IS_SVELTE" -eq 1 ]]; then SRC_DIR="$TARGET/src/lib"; fi

if [[ -d "$SRC_DIR" ]]; then
  # Build candidate service-file list
  mapfile -t SERVICE_CANDIDATES < <(
    find "$SRC_DIR" -maxdepth 2 -name "*.ts" \
      ! -name "index.ts" \
      ! -name "web-component.ts" \
      ! -name "types.ts" \
      ! -name "logger.ts" \
      ! -name "constants*.ts" \
      ! -path "*/vendor/*" \
      ! -path "*/helpers/*" 2>/dev/null
  )

  # Identify the Logic class file by name heuristic (matches the package's
  # main feature; exclude generic names).
  LOGIC_FILE=""
  for f in "${SERVICE_CANDIDATES[@]}"; do
    name=$(basename "$f" .ts)
    # Logic files are typically the package's last name segment
    case "$name" in
      multiselect|grid|player|daterangepicker|tree|treeview|switch|datetimepicker)
        LOGIC_FILE="$f"; break ;;
    esac
  done

  # Remove the Logic file from candidates
  if [[ -n "$LOGIC_FILE" ]]; then
    NEW_CANDIDATES=()
    for f in "${SERVICE_CANDIDATES[@]}"; do
      [[ "$f" != "$LOGIC_FILE" ]] && NEW_CANDIDATES+=("$f")
    done
    SERVICE_CANDIDATES=("${NEW_CANDIDATES[@]}")
  fi

  CROSS_IMPORTS=0
  for a in "${SERVICE_CANDIDATES[@]}"; do
    a_base=$(basename "$a" .ts)
    for b in "${SERVICE_CANDIDATES[@]}"; do
      [[ "$a" == "$b" ]] && continue
      b_base=$(basename "$b" .ts)
      if grep -qE "from\s+['\"]\\./${b_base}(\.js)?['\"]" "$a" 2>/dev/null; then
        echo "        Service '$a_base' imports service '$b_base'"
        CROSS_IMPORTS=$((CROSS_IMPORTS+1))
      fi
    done
  done

  if [[ "$CROSS_IMPORTS" -eq 0 ]]; then
    record_pass "C-CST-4  service classes don't import each other (${#SERVICE_CANDIDATES[@]} candidate(s) inspected)"
  else
    record_fail "C-CST-4" "$CROSS_IMPORTS service-to-service import(s) detected"
  fi
else
  record_skip "C-CST-4" "src/ (or src/lib/) not found"
fi

# -----------------------------------------------------------------------------
# C-CST-5 — Side-layer files have no upward imports
#   Side layer = types.ts, logger.ts, constants*.ts, helpers/*.
#   Upward means importing from the Logic / Element / Service files we
#   identified above.
# -----------------------------------------------------------------------------

mapfile -t SIDE_FILES < <(
  find "$SRC_DIR" -maxdepth 3 \
    \( -name "types.ts" -o -name "logger.ts" -o -name "constants*.ts" \
       -o -path "*/helpers/*.ts" \) 2>/dev/null
)

UPWARD_IMPORTS=0
for sf in "${SIDE_FILES[@]}"; do
  sf_base=$(basename "$sf" .ts)
  # Build list of forbidden import targets
  FORBIDDEN_TARGETS=("web-component" "multiselect" "grid" "tree" "treeview" "player")
  for ft in "${FORBIDDEN_TARGETS[@]}"; do
    if grep -qE "from\s+['\"][./\\w-]*${ft}(\.js)?['\"]" "$sf" 2>/dev/null; then
      echo "        Side-layer '$sf_base' imports '${ft}'"
      UPWARD_IMPORTS=$((UPWARD_IMPORTS+1))
    fi
  done
done

if [[ "$UPWARD_IMPORTS" -eq 0 ]]; then
  record_pass "C-CST-5  side-layer files have no upward imports (${#SIDE_FILES[@]} file(s) inspected)"
else
  record_fail "C-CST-5" "$UPWARD_IMPORTS upward import(s) from side-layer file(s)"
fi

# -----------------------------------------------------------------------------
# C-CST-8 — TS interface suffixes match the closed set
#   Forbidden suffixes: Interface, Type, Data, Info, Object, Model
#   Forbidden prefix:   I + UpperCaseLetter (e.g. IUserProvider)
# -----------------------------------------------------------------------------

BAD_SUFFIXES=$(grep -rEn "^export\s+(interface|type)\s+[A-Z]\w+(Interface|Type|Data|Info|Object|Model)\b" \
               "$SRC_DIR" 2>/dev/null | wc -l)
I_PREFIXED=$(grep -rEn "^export\s+interface\s+I[A-Z]" "$SRC_DIR" 2>/dev/null | wc -l)
TOTAL_BAD=$((BAD_SUFFIXES + I_PREFIXED))

if [[ "$TOTAL_BAD" -eq 0 ]]; then
  record_pass "C-CST-8  TS interface / type suffixes match closed set"
else
  if [[ "$BAD_SUFFIXES" -gt 0 ]]; then
    grep -rEn "^export\s+(interface|type)\s+[A-Z]\w+(Interface|Type|Data|Info|Object|Model)\b" \
         "$SRC_DIR" 2>/dev/null | head -5 | sed 's|^|        |'
  fi
  if [[ "$I_PREFIXED" -gt 0 ]]; then
    grep -rEn "^export\s+interface\s+I[A-Z]" "$SRC_DIR" 2>/dev/null | head -5 | sed 's|^|        |'
  fi
  record_fail "C-CST-8" "$TOTAL_BAD type(s) use forbidden suffix or I-prefix"
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
echo "    [semi]   C-CST-7  (no premature Manager — needs PR-description context)"
echo "    [semi]   C-CST-10 (folder layout — needs README-deviation judgment)"
echo "    [manual] C-CST-6  (Element layer holds no business state)"
echo "    [manual] C-CST-9  (no premature interfaces)"
echo "  Run the .checks.md prose for those, or use /validate-component-structure."

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
