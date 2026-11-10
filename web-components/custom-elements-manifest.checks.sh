#!/usr/bin/env bash
# custom-elements-manifest.checks.sh
#
# Mechanical Tier-1 ([auto]) checks for custom-elements-manifest.checks.md.
# Skips [semi] (C-CEM-10, C-CEM-11) and [manual] (C-CEM-12) checks.
#
# Applicability gate (D-CEM-1): a package with no `customElements.define`
# call in src/ is a Svelte / light-DOM component — the whole triad is N/A
# and every check is skipped.
#
# Usage:
#   ./custom-elements-manifest.checks.sh <component-package-path>
#
# Exit codes:
#   0   all auto checks passed (or triad N/A for a non-custom-element package)
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

PKG_JSON="$TARGET/package.json"
CONFIG_GLOB=("$TARGET"/custom-elements-manifest.config.*)
CEM="$TARGET/custom-elements.json"
WEBTYPES="$TARGET/web-types.json"
VSCODE_DATA="$TARGET/vscode.html-custom-data.json"

echo "${C_INFO}Component target:${C_RESET} $TARGET"
echo

# -----------------------------------------------------------------------------
# Applicability gate (D-CEM-1) — custom element or not?
# -----------------------------------------------------------------------------

if [[ ! -f "$PKG_JSON" ]]; then
  echo "${C_FAIL}ERROR${C_RESET} no package.json at $TARGET" >&2
  exit 2
fi

HAS_DEFINE=0
if [[ -d "$TARGET/src" ]] && \
   grep -rlqE "customElements\.define|registerComponent\(['\"]" "$TARGET/src" 2>/dev/null; then
  HAS_DEFINE=1
fi

if [[ "$HAS_DEFINE" -eq 0 ]]; then
  record_skip "C-CEM-*" "no customElements.define in src/ — Svelte / light-DOM component; triad N/A (D-CEM-1 = B)"
  echo
  echo "${C_INFO}== Summary ==${C_RESET}"
  echo "  ${C_PASS}Pass${C_RESET}:    $PASS"
  echo "  ${C_FAIL}Fail${C_RESET}:    $FAIL"
  echo "  ${C_SKIP}Skip${C_RESET}:    $SKIP"
  exit 0
fi

echo "${C_INFO}== Running [auto] checks (web-component detected) ==${C_RESET}"

# Helper: read a package.json expression via node, empty string on error.
# node runs with cwd = TARGET and a RELATIVE require — Windows node chokes on
# MSYS-style absolute paths (/c/…, /tmp/…) passed to require().
pkg() { ( cd "$TARGET" && node -e "try{const p=require('./package.json');process.stdout.write(String($1))}catch(e){}" ) 2>/dev/null; }
node_pkg() { ( cd "$TARGET" && node -e "$1" ) 2>/dev/null; }

# -----------------------------------------------------------------------------
# C-CEM-1 — analyzer + integration packages are devDependencies
# -----------------------------------------------------------------------------

MISSING_DEV=$(node_pkg "
  try {
    const d=require('./package.json').devDependencies||{};
    const want=['@custom-elements-manifest/analyzer','custom-element-vs-code-integration','custom-element-jet-brains-integration'];
    process.stdout.write(want.filter(p=>!(p in d)).join(' '));
  } catch(e) { process.stdout.write('ALL'); }
")

if [[ -z "$MISSING_DEV" ]]; then
  record_pass "C-CEM-1  analyzer + vscode + jetbrains packages in devDependencies"
else
  record_fail "C-CEM-1" "missing devDependencies: $MISSING_DEV"
fi

# -----------------------------------------------------------------------------
# C-CEM-2 — analyzer config file exists at the package root
# -----------------------------------------------------------------------------

if [[ -f "${CONFIG_GLOB[0]}" ]]; then
  record_pass "C-CEM-2  $(basename "${CONFIG_GLOB[0]}") present"
else
  record_fail "C-CEM-2" "no custom-elements-manifest.config.{mjs,js,cjs} at package root (or D-CEM-3 = B — verify generator scripts run under build)"
fi

# -----------------------------------------------------------------------------
# C-CEM-3 — custom-elements.json exists at the package root
# -----------------------------------------------------------------------------

if [[ -f "$CEM" ]]; then
  record_pass "C-CEM-3  custom-elements.json exists at package root"
else
  record_fail "C-CEM-3" "no custom-elements.json — run 'cem analyze' (this is the artifact everything points at)"
fi

# -----------------------------------------------------------------------------
# C-CEM-4 — package.json "customElements" field → existing manifest
# -----------------------------------------------------------------------------

CE_FIELD=$(pkg "p.customElements||''")
if [[ -z "$CE_FIELD" ]]; then
  record_fail "C-CEM-4" "package.json has no \"customElements\" field — the catalog + VS Code key off it; no listing without it"
elif [[ -f "$TARGET/$CE_FIELD" ]]; then
  record_pass "C-CEM-4  \"customElements\": \"$CE_FIELD\" → file exists"
else
  record_fail "C-CEM-4" "\"customElements\": \"$CE_FIELD\" is dangling (file not found)"
fi

# -----------------------------------------------------------------------------
# C-CEM-5 — package.json "web-types" field → existing web-types.json
# -----------------------------------------------------------------------------

WT_FIELD=$(pkg "p['web-types']||''")
if [[ -z "$WT_FIELD" ]]; then
  record_fail "C-CEM-5" "package.json has no \"web-types\" field — JetBrains auto-discovery needs it"
elif [[ -f "$TARGET/$WT_FIELD" ]]; then
  record_pass "C-CEM-5  \"web-types\": \"$WT_FIELD\" → file exists"
else
  record_fail "C-CEM-5" "\"web-types\": \"$WT_FIELD\" is dangling (file not found)"
fi

# -----------------------------------------------------------------------------
# C-CEM-6 — vscode.html-custom-data.json exists at the package root
# -----------------------------------------------------------------------------

if [[ -f "$VSCODE_DATA" ]]; then
  record_pass "C-CEM-6  vscode.html-custom-data.json exists at package root"
else
  record_fail "C-CEM-6" "no vscode.html-custom-data.json — VS Code HTML completion won't wire up"
fi

# -----------------------------------------------------------------------------
# C-CEM-7 — an analyze step exists and build depends on it
# -----------------------------------------------------------------------------

ANALYZE_STATUS=$(node_pkg "
  try {
    const s=require('./package.json').scripts||{};
    const re=/(cem|custom-elements-manifest)\s+analyze/;
    const anyAnalyze=Object.values(s).some(v=>re.test(v));
    const build=s.build||'';
    // build runs analyze directly, or delegates to the named analyze script
    const buildRuns=re.test(build)||/\banalyze\b/.test(build);
    if(!anyAnalyze) process.stdout.write('NO_ANALYZE');
    else if(!buildRuns) process.stdout.write('NO_BUILD_DEP');
    else process.stdout.write('OK');
  } catch(e){ process.stdout.write('NO_ANALYZE'); }
")

case "$ANALYZE_STATUS" in
  OK)           record_pass "C-CEM-7  analyze step present and build depends on it" ;;
  NO_BUILD_DEP) record_fail "C-CEM-7" "an analyze script exists but 'build' doesn't run it — the manifest can be built stale" ;;
  *)            record_fail "C-CEM-7" "no 'cem analyze' step in scripts — wire it into build so the manifest can't drift" ;;
esac

# -----------------------------------------------------------------------------
# C-CEM-8 — all three artifacts are shipped by the files field
# -----------------------------------------------------------------------------
# No `files` field → npm ships everything (pass, with a note). If present,
# each artifact must be covered by an entry (exact name or a dir prefix).

FILES_STATUS=$(node_pkg "
  try {
    const p=require('./package.json');
    const arts=['custom-elements.json','web-types.json','vscode.html-custom-data.json'];
    if(!Array.isArray(p.files)){ process.stdout.write('NO_FILES_FIELD'); }
    else {
      const files=p.files.map(f=>f.replace(/^\.\//,'').replace(/\/$/,''));
      const missing=arts.filter(a=>!files.some(f=>f===a || a.startsWith(f+'/')));
      process.stdout.write(missing.length?('MISSING:'+missing.join(',')):'OK');
    }
  } catch(e){ process.stdout.write('ERR'); }
")

case "$FILES_STATUS" in
  OK)             record_pass "C-CEM-8  files field ships all three CEM artifacts" ;;
  NO_FILES_FIELD) record_pass "C-CEM-8  no files field — npm packs everything (artifacts ship); consider an explicit files list" ;;
  MISSING:*)      record_fail "C-CEM-8" "files field omits: ${FILES_STATUS#MISSING:} — they won't reach the tarball" ;;
  *)              record_fail "C-CEM-8" "could not evaluate files field" ;;
esac

# -----------------------------------------------------------------------------
# C-CEM-9 — keywords include web-components + custom-elements
# -----------------------------------------------------------------------------

KW_MISSING=$(node_pkg "
  try {
    const k=(require('./package.json').keywords||[]).map(x=>String(x).toLowerCase());
    process.stdout.write(['web-components','custom-elements'].filter(t=>!k.includes(t)).join(' '));
  } catch(e){ process.stdout.write('web-components custom-elements'); }
")

if [[ -z "$KW_MISSING" ]]; then
  record_pass "C-CEM-9  keywords include web-components + custom-elements"
else
  record_fail "C-CEM-9" "keywords missing: $KW_MISSING — the catalog can't group the family into a collection"
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
echo "    [semi]   C-CEM-10 (manifest is fresh — re-run 'npm run analyze' and diff)"
echo "    [semi]   C-CEM-11 (manifest tag/attributes/events match the source)"
echo "    [semi]   C-CEM-13 (public-facing members carry /** */ JSDoc; enum values documented)"
echo "    [manual] C-CEM-12 (editor autocomplete works in VS Code + JetBrains)"
echo "  Run the .checks.md prose for those."

[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
