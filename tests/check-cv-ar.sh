#!/usr/bin/env bash
#
# Checks for the Arabic example CV (examples/cv-ar.tex).
#
# Usage:  tests/check-cv-ar.sh        (from anywhere; paths are resolved)
#
# Each check maps to a requirement of the Arabic example:
#   1. it builds through the documented entry point (make cv-ar)
#   2. the result is exactly one page
#   3. only the core sections render; the secondary ones are commented out
#   4. the RTL layout is real: short Arabic lines hug the RIGHT margin
#   5. embedded Latin runs keep left-to-right order
#   6. no real person's data: placeholder identity only
#   7. Font Awesome 7 is what the sources use, and every icon name resolves in it
#
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail=0
pass() { printf 'PASS  %s\n' "$1"; }
bad()  { printf 'FAIL  %s\n' "$1"; fail=1; }

PDF=examples/cv-ar.pdf
LOG=examples/cv-ar.log

printf '== 1. build through the documented entry point ==\n'
rm -f "$PDF" examples/cv-ar.aux examples/cv-ar.log examples/cv-ar.out
if make cv-ar >"$TMP/build.log" 2>&1; then
  pass "make cv-ar exited 0"
else
  bad "make cv-ar failed"
  tail -25 "$TMP/build.log"
  exit 1
fi

if [ -s "$PDF" ]; then pass "PDF produced and non-empty"
else bad "PDF missing or empty"; exit 1; fi

[ "$(grep -c '^!' "$LOG")" = "0" ] \
  && pass "no LaTeX errors in the build log" \
  || bad "LaTeX errors in the build log"

[ "$(grep -c 'Missing character' "$LOG")" = "0" ] \
  && pass "no missing glyphs" \
  || bad "missing glyphs (font lacks a needed character)"

[ "$(grep -c 'endL or .endR problem' "$LOG")" = "0" ] \
  && pass "no bidi direction imbalance" \
  || bad "bidi \\endL/\\endR imbalance reported"

printf '\n== 2. exactly one page ==\n'
pages=$(pdfinfo "$PDF" | awk '/^Pages/{print $2}')
[ "$pages" = "1" ] && pass "page count is 1" || bad "page count is '$pages', expected 1"

printf '\n== 3. core sections only ==\n'
for f in summary experience skills education; do
  [ -s "examples/cv-ar/$f.tex" ] \
    && pass "core section file present: cv-ar/$f.tex" \
    || bad "missing core section file cv-ar/$f.tex"
done

# Every \cvsection in the Arabic CV must actually reach the page.
python3 - "$PDF" examples/cv-ar "$TMP" <<'PY'
import sys, re, glob, os, subprocess, unicodedata
pdf, secdir, tmp = sys.argv[1], sys.argv[2], sys.argv[3]
text = subprocess.run(["pdftotext","-layout",pdf,"-"],capture_output=True,text=True).stdout

BIDI = dict.fromkeys(map(ord, "\u202a\u202b\u202c\u202d\u202e\u200e\u200f\u2066\u2067\u2068\u2069"), None)
def norm(s):
    return unicodedata.normalize("NFKC", s.translate(BIDI))

ntext = norm(text)
titles = []
for p in sorted(glob.glob(os.path.join(secdir, "*.tex"))):
    for m in re.finditer(r"\\cvsection\{([^}]*)\}", open(p, encoding="utf-8").read()):
        titles.append(m.group(1).strip())

ok = True
for t in titles:
    tn = norm(t)
    # Arabic is extracted in visual order, so accept the reversed form too.
    if tn in ntext or tn[::-1] in ntext:
        print(f"PASS  section heading rendered: {t}")
    else:
        print(f"FAIL  section heading missing from page: {t}")
        ok = False

arabic_letters = sum(1 for c in ntext if "\u0600" <= c <= "\u06ff")
if arabic_letters > 200:
    print(f"PASS  body text is Arabic ({arabic_letters} Arabic letters in the text layer)")
else:
    print(f"FAIL  body text does not look Arabic ({arabic_letters} Arabic letters)")
    ok = False
sys.exit(0 if ok else 1)
PY
[ $? -eq 0 ] || fail=1

# Secondary sections: no active \input of them, and their files have no live code.
secondary="extracurricular honors certificates presentation writing committees"
for s in $secondary; do
  if grep -qE "^\s*\\\\input\{cv/$s\.tex\}" examples/cv.tex; then
    bad "examples/cv.tex still inputs the secondary section cv/$s.tex"
  else
    pass "secondary section not included: cv/$s.tex"
  fi
  if [ "$(grep -vcE '^\s*(%|$)' "examples/cv/$s.tex")" = "0" ]; then
    pass "secondary section fully commented out: cv/$s.tex"
  else
    bad "secondary section still has active content: cv/$s.tex"
  fi
done

# English secondary headings must not appear on the Arabic page.
for h in "Honors" "Certificates" "Presentation" "Writing" "Program Committees" "Extracurricular"; do
  if pdftotext -layout "$PDF" - | grep -qi "$h"; then
    bad "secondary heading leaked onto the page: $h"
  else
    pass "secondary heading absent from the page: $h"
  fi
done

printf '\n== 4/5. RTL geometry and bidi order ==\n'
pdftotext -bbox "$PDF" "$TMP/bbox.xml"
python3 - "$TMP/bbox.xml" examples/cv-ar.tex <<'PY'
import sys, re, xml.etree.ElementTree as ET
from collections import defaultdict
import unicodedata

bbox, doc = sys.argv[1], sys.argv[2]
NS = "{http://www.w3.org/1999/xhtml}"
pg = ET.parse(bbox).getroot().findall(f".//{NS}page")[0]
W, H = float(pg.get("width")), float(pg.get("height"))
words = [(float(w.get("xMin")), float(w.get("xMax")), float(w.get("yMin")),
          float(w.get("yMax")), w.text or "") for w in pg.findall(f"{NS}word")]

# Derive the text margins from the page itself rather than from config.
left_margin = min(w[0] for w in words)
right_margin = max(w[1] for w in words)

lines = defaultdict(list)
for w in words:
    lines[round(w[2], 1)].append(w)

def is_arabic(s):
    # pdftotext emits Arabic as presentation forms (U+FE70..U+FEFF); normalise to
    # base Arabic letters before measuring, otherwise every line looks non-Arabic.
    s = unicodedata.normalize("NFKC", s)
    letters = [c for c in s if c.isalpha()]
    if not letters:
        return False
    return sum(1 for c in letters if "\u0600" <= c <= "\u06ff") / len(letters) >= 0.8

hug_right = hug_left = 0
right_examples = []
for y in sorted(lines):
    ws = lines[y]
    txt = "".join(w[4] for w in ws)
    x0 = min(w[0] for w in ws)
    x1 = max(w[1] for w in ws)
    if not is_arabic(txt):
        continue
    if (x1 - x0) > 0.5 * W:          # only SHORT lines are informative
        continue
    if (right_margin - x1) <= 15 and (x0 - left_margin) > 0.25 * W:
        hug_right += 1
        right_examples.append(txt[:40])
    if (x0 - left_margin) <= 15 and (right_margin - x1) > 0.25 * W:
        hug_left += 1

ok = True
print(f"INFO  page {W:.1f}x{H:.1f}, derived margins left={left_margin:.1f} right={right_margin:.1f}")
if hug_right >= 2:
    print(f"PASS  {hug_right} short Arabic line(s) hug the RIGHT margin (mirror of LTR)")
    for e in right_examples[:4]:
        print(f"        e.g. {e!r}")
else:
    print(f"FAIL  only {hug_right} short Arabic line(s) hug the right margin (need >=2)")
    ok = False
if hug_left == 0:
    print("PASS  no short Arabic line hugs the LEFT margin (RTL confirmed, not LTR)")
else:
    print(f"FAIL  {hug_left} short Arabic line(s) hug the LEFT margin - layout is LTR, not RTL")
    ok = False

# Latin runs must keep left-to-right character order.
src = open(doc, encoding="utf-8").read()
m = re.search(r"\\newcommand\{\\cvemail\}\{([^}]*)\}", src)
email = m.group(1).strip() if m else ""
pdftext = __import__("subprocess").run(
    ["pdftotext", "-layout", "examples/cv-ar.pdf", "-"], capture_output=True, text=True).stdout
if email and email in pdftext and email[::-1] not in pdftext:
    print(f"PASS  Latin run keeps LTR order: {email}")
else:
    print(f"FAIL  Latin run not found in LTR order in the text layer: {email!r}")
    ok = False
sys.exit(0 if ok else 1)
PY
[ $? -eq 0 ] || fail=1

printf '\n== 6. placeholder identity, no real person data ==\n'
UPSTREAM='Claud|posquit0|10-9030-1843|\+82|Mapo-gu'
# Field values in the CV documents (comment lines are attribution and stay).
for f in examples/cv-ar.tex examples/cv.tex; do
  hits=$(grep -vE '^\s*%' "$f" | grep -nE "$UPSTREAM" || true)
  if [ -z "$hits" ]; then
    pass "no upstream author identity in field values of $f"
  else
    bad "upstream author identity in $f: $hits"
  fi
done
if pdftotext -layout "$PDF" - | grep -qE "$UPSTREAM"; then
  bad "upstream author identity present in the built PDF text layer"
else
  pass "upstream author identity absent from the built PDF text layer"
fi

# The CV must define a person and at least one contact field, on placeholder values.
python3 - examples/cv-ar.tex <<'PY'
import sys, re
src = open(sys.argv[1], encoding="utf-8").read()
checks = [
    (r"\\newcommand\{\\cvname\}\{[^}]*\S[^}]*\}", "a person's name is defined"),
    (r"\\newcommand\{\\cvemail\}\{[^}]*\}", "at least one contact field is defined"),
    (r"\\newcommand\{\\cvemail\}\{[^}]*@example\.com\}", "contact field uses the reserved example.com domain"),
]
ok = True
for pattern, label in checks:
    if re.search(pattern, src):
        print(f"PASS  {label}")
    else:
        print(f"FAIL  {label}")
        ok = False
sys.exit(0 if ok else 1)
PY
[ $? -eq 0 ] || fail=1

printf '\n== 7. Font Awesome 7 ==\n'
if grep -rn "fontawesome6" --include='*.tex' --include='*.cls' . | grep -q .; then
  bad "a LaTeX source still requires fontawesome6"
else
  pass "no LaTeX source requires fontawesome6"
fi
grep -q "fontawesome7" examples/cv-ar.tex \
  && pass "the Arabic CV loads fontawesome7" \
  || bad "the Arabic CV does not load fontawesome7"
grep -q "fontawesome7" awesome-cv.cls \
  && pass "the class loads fontawesome7" \
  || bad "the class does not load fontawesome7"

FA7_MAP=$(dirname "$(kpsewhich fontawesome7.sty)")/fontawesome7-mapping.def
if [ -f "$FA7_MAP" ]; then
  pass "fontawesome7 is installed (${FA7_MAP})"
  python3 - "$FA7_MAP" <<'PY'
import sys, re, glob, os
mapping = open(sys.argv[1], encoding="utf-8", errors="ignore").read()
# Names defined by the class itself rather than by Font Awesome.
LOCAL = {"faAlt"}
bad = []
used = 0
files = glob.glob("**/*.cls", recursive=True) + glob.glob("**/*.tex", recursive=True)
for p in files:
    for i, line in enumerate(open(p, encoding="utf-8", errors="ignore"), 1):
        code = line.split("%")[0]
        for name in re.findall(r"\\(fa[A-Z][A-Za-z0-9]*)", code):
            if name in LOCAL:
                continue
            used += 1
            if f"\\{name}" not in mapping and name not in mapping:
                bad.append(f"{p}:{i}: \\{name}")
if bad:
    print(f"FAIL  {len(bad)} Font Awesome name(s) used but absent from Font Awesome 7:")
    for b in sorted(set(bad))[:15]:
        print("        " + b)
    sys.exit(1)
print(f"PASS  all {used} Font Awesome icon references resolve in Font Awesome 7")
PY
  [ $? -eq 0 ] || fail=1
else
  bad "fontawesome7 mapping not found via kpsewhich"
fi

printf '\n== summary ==\n'
if [ "$fail" = "0" ]; then
  echo "ALL CHECKS PASSED"
else
  echo "SOME CHECKS FAILED"
fi
exit $fail
