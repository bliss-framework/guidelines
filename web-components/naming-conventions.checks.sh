#!/usr/bin/env bash
# naming-conventions.checks.sh
#
# Mechanical Tier-1 ([auto]) checks for naming-conventions.checks.md.
# Skips [semi] (needs context) and [manual] (needs judgment) checks.
#
# Usage:
#   ./naming-conventions.checks.sh <component-package-path> [<css-prefix>]
#
#   <css-prefix> is required for C-NC-8 (BEM-with-prefix check). If omitted,
#   we attempt to read it from component-variables.manifest.json.
#
# Exit codes:
#   0   all auto checks passed
#   1   one or more auto checks failed
#   2   bad usage / target not found
#
# Detects web-component vs Svelte from filesystem signals so per-host
# checks (C-NC-1, C-NC-2) skip cleanly on Svelte targets. A package with
# TypeScript sources but no element (a headless store, a runtime library) is a
# library: the TS API checks run, the element checks skip. A package with
# neither (a CSS-only token library) has nothing to check and exits 0.

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

PASS=0
FAIL=0
SKIP=0

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
# Detection prelude
# -----------------------------------------------------------------------------

IS_SVELTE=0
IS_WEB_COMPONENT=0

if [[ -d "$TARGET/src/lib/components" ]] && \
   find "$TARGET/src/lib" -maxdepth 4 -name "*.svelte" -print -quit 2>/dev/null | grep -q .; then
  IS_SVELTE=1
fi

if find "$TARGET/src" -maxdepth 3 -name "*.ts" -print0 2>/dev/null | \
   xargs -0 grep -lE "customElements\.define|registerComponent\(['\"]" 2>/dev/null | grep -q .; then
  IS_WEB_COMPONENT=1
fi

IS_LIBRARY=0
if [[ "$IS_SVELTE" -eq 0 && "$IS_WEB_COMPONENT" -eq 0 ]]; then
  if find "$TARGET/src" -name "*.ts" ! -name "*.d.ts" -print -quit 2>/dev/null | grep -q .; then
    IS_LIBRARY=1
  else
    echo "${C_INFO}Target:${C_RESET} $TARGET"
    echo "${C_SKIP}⏭  SKIP${C_RESET} all — no custom element, Svelte component or TypeScript sources (nothing to check)"
    exit 0
  fi
fi

# Try to discover CSS prefix from manifest if not provided
if [[ -z "$CSS_PREFIX" ]] && [[ -f "$TARGET/component-variables.manifest.json" ]]; then
  CSS_PREFIX=$(grep -oE '"prefix"\s*:\s*"[a-z]+"' \
               "$TARGET/component-variables.manifest.json" 2>/dev/null | \
               head -1 | grep -oE '"[a-z]+"$' | tr -d '"')
fi

SRC_DIR="$TARGET/src"
CSS_DIR="$TARGET/src/css"
if [[ "$IS_SVELTE" -eq 1 ]]; then
  SRC_DIR="$TARGET/src/lib"
  CSS_DIR="$TARGET/src/lib/styles"
fi

echo "${C_INFO}Component target:${C_RESET} $TARGET"
if [[ "$IS_WEB_COMPONENT" -eq 1 ]]; then echo "${C_INFO}Detected:${C_RESET} web-component"; fi
if [[ "$IS_SVELTE" -eq 1 ]];        then echo "${C_INFO}Detected:${C_RESET} Svelte component"; fi
if [[ "$IS_LIBRARY" -eq 1 ]];       then echo "${C_INFO}Detected:${C_RESET} library (TypeScript, no custom element)"; fi
NOT_ELEMENT_REASON="N/A for Svelte component"
[[ "$IS_LIBRARY" -eq 1 ]] && NOT_ELEMENT_REASON="no custom element (library)"
echo "${C_INFO}CSS prefix:${C_RESET} ${CSS_PREFIX:-<unknown>}"
echo

# -----------------------------------------------------------------------------
# C-NC-1 — Custom-element tag is hyphenated and prefixed (web-component only)
# -----------------------------------------------------------------------------
echo "${C_INFO}== Running [auto] checks ==${C_RESET}"

if [[ "$IS_WEB_COMPONENT" -eq 1 ]]; then
  TAG=$(grep -rhE "(customElements\.define|registerComponent)\(['\"][^'\"]+" "$SRC_DIR" 2>/dev/null | \
        grep -oE "['\"][^'\"]+['\"]" | head -1 | tr -d "'\"")
  if [[ -z "$TAG" ]]; then
    record_fail "C-NC-1" "no customElements.define call found"
  elif ! [[ "$TAG" =~ ^[a-z]+(-[a-z]+)+$ ]]; then
    record_fail "C-NC-1" "tag '$TAG' is not kebab-case with mandatory hyphen"
  else
    record_pass "C-NC-1  custom-element tag '$TAG' is valid kebab-case"
  fi
else
  record_skip "C-NC-1" "$NOT_ELEMENT_REASON"
fi

# -----------------------------------------------------------------------------
# C-NC-2 — CustomEvent names are bare and short (web-component only)
# -----------------------------------------------------------------------------

if [[ "$IS_WEB_COMPONENT" -eq 1 ]]; then
  # Raw CustomEvents plus core's this.emit('name').
  EVENT_NAMES=$(grep -rhEo "(new CustomEvent|\.emit)\(['\"][^'\"]+['\"]" "$SRC_DIR" 2>/dev/null | \
                grep -oE "['\"][^'\"]+['\"]" | tr -d "'\"" | sort -u)
  # Native events that cross shadow DOM — a component event must not reuse them.
  COMPOSED_NATIVE_RE='^(click|dblclick|auxclick|contextmenu|focus|blur|focusin|focusout|keydown|keyup|keypress|input|beforeinput|copy|cut|paste|drop|wheel|pointer[a-z]+|mouse[a-z]+|touch[a-z]+|drag[a-z]*|composition[a-z]+)$'
  # Past-tense-looking adjectives that are fine as an event-name segment.
  ED_ALLOWED_RE='^(checked|selected|expanded|collapsed|focused|disabled|enabled)$'
  if [[ -z "$EVENT_NAMES" ]]; then
    record_skip "C-NC-2" "no CustomEvent dispatches found"
  else
    BAD=""
    while IFS= read -r name; do
      [[ -z "$name" ]] && continue
      if ! [[ "$name" =~ ^[a-z]+(-[a-z]+)*$ ]]; then
        BAD="${BAD}${name}, "
      fi
      # Also flag on* prefix or Event suffix
      if [[ "$name" =~ ^on[A-Z] ]] || [[ "$name" =~ Event$ ]]; then
        BAD="${BAD}${name} (decorated), "
      fi
      if [[ "$name" =~ $COMPOSED_NATIVE_RE ]]; then
        BAD="${BAD}${name} (composed native name), "
      fi
      # No component prefix (needs the CSS prefix argument, e.g. `cp`).
      if [[ -n "$CSS_PREFIX" ]] && [[ "$name" == "$CSS_PREFIX"-* ]]; then
        BAD="${BAD}${name} (component prefix), "
      fi
      # Present tense: the last segment must not be a past participle.
      last="${name##*-}"
      if [[ "$last" =~ ed$ ]] && ! [[ "$last" =~ $ED_ALLOWED_RE ]]; then
        BAD="${BAD}${name} (past tense), "
      fi
    done <<< "$EVENT_NAMES"
    if [[ -z "$BAD" ]]; then
      EVENT_COUNT=$(echo "$EVENT_NAMES" | wc -l)
      record_pass "C-NC-2  $EVENT_COUNT event name(s) bare, present tense, no native clash"
    else
      record_fail "C-NC-2" "non-bare CustomEvent name(s): ${BAD%, }"
    fi
  fi
else
  record_skip "C-NC-2" "$NOT_ELEMENT_REASON"
fi

# -----------------------------------------------------------------------------
# C-NC-3 — Boolean Config/Props fields use is*/should*/has*/can* prefix
#   Data-model interfaces (MultiSelectOption, LTreeNode, etc.) are exempt —
#   they follow HTML convention (`disabled`, `selected`, `checked` …).
#
#   Strategy: walk each file line by line; track the current interface name
#   from the most recent `interface X` or `type X = {` declaration; flag
#   boolean fields only when the enclosing interface is a Config / Props /
#   Settings / Spec shape (NOT Option / Node / Item / Row / Entry / Record /
#   Model — those are data shapes).
# -----------------------------------------------------------------------------

mapfile -t TYPE_FILES < <(
  find "$SRC_DIR" \( -name "types.ts" -o -name "*.svelte" -o -name "*.svelte.ts" \) 2>/dev/null
)

if [[ "${#TYPE_FILES[@]}" -eq 0 ]]; then
  record_skip "C-NC-3" "no types.ts / .svelte files found"
else
  # Filter: keep only boolean fields inside Config / Props-shaped interfaces.
  # Use an awk pass to track interface context.
  BAD_BOOLS=$(awk '
    /^\s*(export\s+)?interface\s+[A-Z][a-zA-Z0-9]*/ {
      match($0, /interface\s+([A-Z][a-zA-Z0-9]*)/, arr)
      iface = arr[1]
      # Data-model shapes — skip booleans inside these
      if (iface ~ /(Option|Node|Item|Row|Entry|Record|Model|Result)$/) {
        skip = 1
      } else {
        skip = 0
      }
      depth = 0
      parens = 0
      next
    }
    /\{/ { depth++ }
    /\}/ {
      depth--
      if (depth <= 0) iface = ""
    }
    # Inside an open `(` (a signature spanning lines) a `name: boolean,` line is a
    # PARAMETER, not a field. `parens` is the depth at the start of the line.
    skip == 0 && iface != "" && parens <= 0 && /^\s+[a-zA-Z_][a-zA-Z0-9_]*\??:\s+boolean/ {
      match($0, /^\s+([a-zA-Z_][a-zA-Z0-9_]*)/, m)
      name = m[1]
      if (name !~ /^(is|has|can|should)[A-Z]/) {
        print name " (in " iface ")"
      }
    }
    {
      code = $0
      sub(/\/\/.*/, "", code)
      parens += gsub(/\(/, "(", code) - gsub(/\)/, ")", code)
      if (parens < 0) parens = 0
    }
  ' "${TYPE_FILES[@]}" 2>/dev/null)

  TOTAL_BOOLEANS=$(grep -hcE "^\s+[a-zA-Z_][a-zA-Z0-9_]*\??:\s+boolean" \
                   "${TYPE_FILES[@]}" 2>/dev/null | \
                   awk 'BEGIN{s=0} {s+=$1} END{print s}')

  if [[ -z "$BAD_BOOLS" ]]; then
    record_pass "C-NC-3  Config/Props boolean fields all use is*/has*/can*/should* prefix ($TOTAL_BOOLEANS total booleans scanned, data-model interfaces exempt)"
  else
    echo "$BAD_BOOLS" | sed 's|^|        |'
    BAD_COUNT=$(echo "$BAD_BOOLS" | wc -l)
    record_fail "C-NC-3" "$BAD_COUNT Config/Props boolean field(s) without prefix"
  fi
fi

# -----------------------------------------------------------------------------
# C-NC-4 (auto portion) — *Callback fields must not be fire-and-forget (=> void)
#   The seam is the return value: a function whose return is ignored is an
#   event (on*), not a callback. A void-returning *Callback is an event
#   wearing the wrong suffix → rename to on*.
#   before*Callback interceptors are EXEMPT — their return (false / modified
#   args) is consumed. So are content providers: a render*Callback, or any
#   *Callback that receives an HTMLElement, writes its result into the element it gets
#   (renderNodeCallback(node, container), ctx.containerElement).
#   The on*-returns-a-value half stays [semi].
#
#   Per field: the FIELD name only (not `…Callback` inside a type name such as
#   NodeRenderCallbackContext), and the return type after the parameter list's
#   own `)`, so a returned cleanup `=> () => void` isn't read as `=> void`.
# -----------------------------------------------------------------------------

if [[ "${#TYPE_FILES[@]}" -eq 0 ]]; then
  record_skip "C-NC-4" "no types files found (auto portion)"
else
  VOID_CALLBACKS=$(awk '
    match($0, /^[ \t]+[a-z][a-zA-Z0-9]*Callback\??:[ \t]*/) {
      name = $0
      sub(/^[ \t]+/, "", name)
      sub(/\??:.*/, "", name)
      rest = substr($0, RLENGTH + 1)
      if (substr(rest, 1, 2) == "((") rest = substr(rest, 2)   # ((…) => …) | null
      if (substr(rest, 1, 1) != "(") next
      level = 0
      for (i = 1; i <= length(rest); i++) {
        c = substr(rest, i, 1)
        if (c == "(") level++
        else if (c == ")") { level--; if (level == 0) break }
      }
      if (level != 0) next
      params = substr(rest, 2, i - 2)
      returned = substr(rest, i + 1)
      if (returned !~ /^[ \t]*=>[ \t]*(void|Promise<void>)[ \t]*([;,)|]|$)/) next
      if (name ~ /^render[A-Z]/ || params ~ /HTMLElement/) next
      print name
    }
  ' "${TYPE_FILES[@]}" 2>/dev/null | grep -vE "^before" | sort -u)
  if [[ -z "$VOID_CALLBACKS" ]]; then
    record_pass "C-NC-4  no fire-and-forget (=> void) *Callback fields (auto portion; on*-returns-value half is [semi])"
  else
    echo "$VOID_CALLBACKS" | sed 's|^|        |'
    BAD_CB_COUNT=$(echo "$VOID_CALLBACKS" | wc -l)
    record_fail "C-NC-4" "$BAD_CB_COUNT void-returning *Callback field(s) — these are events, rename to on*"
  fi
fi

# -----------------------------------------------------------------------------
# C-NC-6 — Data extractors use get*Callback + *Member pair
#   For every *Member field, expect a matching get*Callback (capitalized).
# -----------------------------------------------------------------------------

if [[ "${#TYPE_FILES[@]}" -eq 0 ]]; then
  record_skip "C-NC-6" "no types files found"
else
  MEMBER_FIELDS=$(grep -hEn "^\s+[a-z][a-zA-Z0-9]*Member\??:" "${TYPE_FILES[@]}" 2>/dev/null | \
                  grep -oE "[a-z][a-zA-Z0-9]*Member" | sort -u)
  CALLBACK_FIELDS=$(grep -hEn "^\s+get[A-Z][a-zA-Z0-9]*Callback\??:" "${TYPE_FILES[@]}" 2>/dev/null | \
                    grep -oE "get[A-Z][a-zA-Z0-9]*Callback" | sort -u)

  if [[ -z "$MEMBER_FIELDS" && -z "$CALLBACK_FIELDS" ]]; then
    record_skip "C-NC-6" "no *Member or get*Callback fields found (D-NC-7 = D?)"
  else
    UNPAIRED=""
    while IFS= read -r mem; do
      [[ -z "$mem" ]] && continue
      # Strip "Member" suffix and capitalize first letter to build expected getter name
      root="${mem%Member}"
      root_cap="$(echo "${root:0:1}" | tr '[:lower:]' '[:upper:]')${root:1}"
      expected="get${root_cap}Callback"
      if ! echo "$CALLBACK_FIELDS" | grep -qx "$expected"; then
        UNPAIRED="${UNPAIRED}${mem} (expected ${expected}), "
      fi
    done <<< "$MEMBER_FIELDS"

    if [[ -z "$UNPAIRED" ]]; then
      MEM_COUNT=$(echo "$MEMBER_FIELDS" | wc -l)
      record_pass "C-NC-6  $MEM_COUNT *Member field(s) each paired with get*Callback"
    else
      record_fail "C-NC-6" "unpaired *Member field(s): ${UNPAIRED%, }"
    fi
  fi
fi

# -----------------------------------------------------------------------------
# C-NC-8 — CSS classes use BEM with component prefix
# -----------------------------------------------------------------------------

if [[ -z "$CSS_PREFIX" ]]; then
  record_skip "C-NC-8" "CSS prefix not provided and not found in manifest (pass as 2nd arg)"
elif [[ ! -d "$CSS_DIR" ]]; then
  record_skip "C-NC-8" "CSS directory not found at $CSS_DIR"
else
  # Strip:
  #   - CSS comments (/* ... */, possibly multi-line) — filenames and URLs
  #     in comments are not selectors.
  #   - content inside :host-context(...) and :host([...]) — those are
  #     *consumer* selectors (framework theme classes like .dark, .light,
  #     attribute selectors), not component-emitted classes.
  STRIPPED=$(mktemp)
  # Concatenate CSS, then strip block comments using sed in multiline mode
  # (process the joined stream so /* ... \n ... */ spans are removed).
  # Also strip url(...), 'string literals', "string literals" — those are
  # consumer-facing strings, not selectors.
  cat "$CSS_DIR"/*.css 2>/dev/null | \
    tr '\n' '\f' | \
    sed -E 's|/\*[^*]*\*+([^/*][^*]*\*+)*/||g' | \
    tr '\f' '\n' | \
    sed -E "s/url\([^)]*\)//g; s/'[^']*'//g; s/\"[^\"]*\"//g" | \
    sed -E 's/:host-context\([^)]*\)//g; s/:host\(\[[^]]*\]\)//g' \
    > "$STRIPPED"

  # BEM shapes accepted:
  #   .<prefix>                       — bare block
  #   .<prefix>--<modifier>           — block modifier
  #   .<prefix>__<element>            — block element
  #   .<prefix>__<element>--<modifier> — block element modifier
  #   .<prefix>-container             — Svelte container class
  mapfile -t BAD_CLASSES < <(
    grep -hEo "\.[a-z][a-z0-9_-]+" "$STRIPPED" 2>/dev/null | sort -u | \
      grep -vE "^\.(${CSS_PREFIX}(__[a-z][a-z0-9-]*)?(--[a-z][a-z0-9-]*)?|${CSS_PREFIX}-container)$"
  )
  rm -f "$STRIPPED"

  if [[ "${#BAD_CLASSES[@]}" -eq 0 ]]; then
    record_pass "C-NC-8  all CSS classes follow BEM with prefix '$CSS_PREFIX'"
  else
    # First 10 offenders
    printf "        %s\n" "${BAD_CLASSES[@]:0:10}"
    record_fail "C-NC-8" "${#BAD_CLASSES[@]} class(es) don't follow BEM with prefix .${CSS_PREFIX}"
  fi
fi

# -----------------------------------------------------------------------------
# C-NC-9 — Internal methods use handle*, stored refs use *Handler
#   Heuristic: examine the Logic class file(s) for method signatures and field
#   declarations. We don't enforce that *every* internal method is a handler —
#   only that no internal method handling a DOM event uses a different prefix.
# -----------------------------------------------------------------------------

mapfile -t LOGIC_FILES < <(
  find "$SRC_DIR" -maxdepth 3 -name "*.ts" 2>/dev/null | \
    xargs -r grep -lE "class\s+[A-Z]\w+" 2>/dev/null
)

if [[ "${#LOGIC_FILES[@]}" -eq 0 ]]; then
  record_skip "C-NC-9" "no class files found"
else
  # Look for the misused patterns: method names that take `(e:` or `(event:` an
  # Event-like type and don't start with `handle`.
  BAD_HANDLERS=$(grep -hEn "^\s+(private|protected|public)?\s*[a-z]\w+\s*\(\s*(e|event|ev|evt):\s*[A-Z]\w*Event" \
                 "${LOGIC_FILES[@]}" 2>/dev/null | \
                 grep -vE "handle[A-Z]\w*\s*\(" | wc -l)

  # Also check stored references: fields whose type is `((...) => void) | null`
  # or similar should end with Handler if they hold a DOM listener.
  # That's a softer heuristic and likely produces false positives, so we
  # report a count, not pass/fail.
  if [[ "$BAD_HANDLERS" -eq 0 ]]; then
    record_pass "C-NC-9  internal DOM event handler methods use handle* prefix"
  else
    grep -hEn "^\s+(private|protected|public)?\s*[a-z]\w+\s*\(\s*(e|event|ev|evt):\s*[A-Z]\w*Event" \
         "${LOGIC_FILES[@]}" 2>/dev/null | grep -vE "handle[A-Z]\w*\s*\(" | head -5 | sed 's|^|        |'
    record_fail "C-NC-9" "$BAD_HANDLERS internal handler method(s) don't use handle* prefix"
  fi
fi

# -----------------------------------------------------------------------------
# C-NC-11 — TS interface suffixes match closed set
#   Same as C-CST-8 — duplicated here so this script is usable standalone.
# -----------------------------------------------------------------------------

BAD_SUFFIXES=$(grep -rEn "^export\s+(interface|type)\s+[A-Z]\w+(Interface|Type|Data|Info|Object|Model)\b" \
               "$SRC_DIR" 2>/dev/null | wc -l)
I_PREFIXED=$(grep -rEn "^export\s+interface\s+I[A-Z]" "$SRC_DIR" 2>/dev/null | wc -l)
TOTAL_BAD=$((BAD_SUFFIXES + I_PREFIXED))

if [[ "$TOTAL_BAD" -eq 0 ]]; then
  record_pass "C-NC-11 TS interface / type suffixes match closed set"
else
  if [[ "$BAD_SUFFIXES" -gt 0 ]]; then
    grep -rEn "^export\s+(interface|type)\s+[A-Z]\w+(Interface|Type|Data|Info|Object|Model)\b" \
         "$SRC_DIR" 2>/dev/null | head -5 | sed 's|^|        |'
  fi
  if [[ "$I_PREFIXED" -gt 0 ]]; then
    grep -rEn "^export\s+interface\s+I[A-Z]" "$SRC_DIR" 2>/dev/null | head -5 | sed 's|^|        |'
  fi
  record_fail "C-NC-11" "$TOTAL_BAD type(s) use forbidden suffix or I-prefix"
fi

# -----------------------------------------------------------------------------
# C-NC-13 — showMessage takes a variant with the contract's role names (D-NC-23)
#   Only for a component that shows messages. Flags the message kind declared
#   as `type` / `severity` / `level` / `kind` of a Message* type, and a status
#   union that says 'error' instead of 'danger'.
# -----------------------------------------------------------------------------

if ! grep -rqE "showMessage\s*\(" "$SRC_DIR" --include=*.ts 2>/dev/null; then
  record_skip "C-NC-13" "component shows no messages (no showMessage)"
else
  MESSAGE_KIND_FIELDS=$(grep -rEn "^\s*(type|severity|level|kind)\??\s*:\s*Message\w*" "$SRC_DIR" --include=*.ts 2>/dev/null)
  ERROR_UNIONS=$(grep -rEn "'info'" "$SRC_DIR" --include=*.ts 2>/dev/null | grep "'warning'" | grep "'error'")
  BAD_MESSAGE_LINES=$(printf '%s\n%s\n' "$MESSAGE_KIND_FIELDS" "$ERROR_UNIONS" | grep .)
  BAD_MESSAGE_COUNT=$(printf '%s' "$BAD_MESSAGE_LINES" | grep -c .)
  if [[ "$BAD_MESSAGE_COUNT" -eq 0 ]]; then
    record_pass "C-NC-13 message kind is 'variant' with the contract's role names"
  else
    printf '%s\n' "$BAD_MESSAGE_LINES" | head -5 | sed 's|^|        |'
    record_fail "C-NC-13" "$BAD_MESSAGE_COUNT message kind declaration(s) — use variant?: MessageVariant ('info' | 'success' | 'warning' | 'danger')"
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
echo "    [semi]   C-NC-4  (on* fields must return void — needs return-type reading; void-*Callback half is auto above)"
echo "    [semi]   C-NC-5  (interceptors use before*Callback — needs return-type heuristic)"
echo "    [semi]   C-NC-7  (ATTRIBUTE_TABLE drives observedAttributes — needs reading impl)"
echo "    [semi]   C-NC-12 (no magic strings inline — needs duplicate-detection + judgment)"
echo "    [manual] C-NC-10 (validate* vs check* per their semantics)"
echo "  Run the .checks.md prose for those, or use /validate-naming-conventions."

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
