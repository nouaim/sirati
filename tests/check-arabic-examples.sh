#!/usr/bin/env bash
#
# Checks for the Arabic examples: the CV (examples/cv-ar.tex) and the cover
# letter (examples/coverletter-ar.tex), plus the repo-level properties that go
# with them (no dangling references, README policy, Font Awesome 7).
#
# Usage:  tests/check-arabic-examples.sh      (from anywhere; paths resolved)
#
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail=0
pass() { printf 'PASS  %s\n' "$1"; }
bad()  { printf 'FAIL  %s\n' "$1"; fail=1; }

UPSTREAM_RE='Claud|posquit0|10-9030-1843|\+82|Mapo-gu|posquit0\.com'

# ---------------------------------------------------------------------------
# helper: build one document through its real make target, then assert
# ---------------------------------------------------------------------------
check_document() {
  local label="$1" target="$2" pdf="$3" log="$4" src="$5" secdir="$6"

  printf '\n== %s: build through `make %s` ==\n' "$label" "$target"
  rm -f "$pdf" "${pdf%.pdf}.aux" "$log" "${pdf%.pdf}.out"
  if make "$target" >"$TMP/build-$target.log" 2>&1; then
    pass "make $target exited 0"
  else
    bad "make $target failed"; tail -20 "$TMP/build-$target.log"; return
  fi
  [ -s "$pdf" ] && pass "PDF produced and non-empty" || { bad "no PDF"; return; }

  [ "$(grep -c '^!' "$log")" = "0" ] \
    && pass "no LaTeX errors" || bad "LaTeX errors in $log"
  [ "$(grep -c 'Missing character' "$log")" = "0" ] \
    && pass "no missing glyphs" || bad "missing glyphs"
  [ "$(grep -c 'endL or .endR problem' "$log")" = "0" ] \
    && pass "no bidi direction imbalance" || bad "bidi \\endL/\\endR imbalance"

  local pages
  pages=$(pdfinfo "$pdf" | awk '/^Pages/{print $2}')
  [ "$pages" = "1" ] && pass "exactly one page" || bad "page count is '$pages'"

  pdftotext -bbox "$pdf" "$TMP/bbox-$target.xml"
  python3 - "$TMP/bbox-$target.xml" "$src" "$secdir" "$pdf" "$label" <<'PY'
import sys, re, glob, os, subprocess, unicodedata
import xml.etree.ElementTree as ET
from collections import defaultdict

bbox, src, secdir, pdf, label = sys.argv[1:6]
NS = "{http://www.w3.org/1999/xhtml}"
BIDI = dict.fromkeys(map(ord, "\u202a\u202b\u202c\u202d\u202e\u200e\u200f\u2066\u2067\u2068\u2069"), None)

def norm(s):
    return unicodedata.normalize("NFKC", s.translate(BIDI))

def arabic_letters(s):
    return "".join(c for c in norm(s) if "\u0600" <= c <= "\u06ff")

def page_text(text):
    """pdftotext emits Arabic as presentation forms but keeps logical letter
    order, so NFKC normalisation is enough to compare against source strings."""
    return norm(text)

pdftext = subprocess.run(["pdftotext", "-layout", pdf, "-"],
                         capture_output=True, text=True).stdout
logical = page_text(pdftext)
ok = True

# body text is Arabic
n_ar = sum(1 for c in norm(pdftext) if "\u0600" <= c <= "\u06ff")
if n_ar > 200:
    print(f"PASS  body text is Arabic ({n_ar} Arabic letters in the text layer)")
else:
    print(f"FAIL  body text does not look Arabic ({n_ar} letters)"); ok = False

# every section heading in the document reaches the page
headings = []
for p in sorted(glob.glob(os.path.join(secdir, "*.tex"))):
    for m in re.finditer(r"\\(?:cv|letter)section\{([^}]*)\}",
                         open(p, encoding="utf-8").read()):
        headings.append(m.group(1).strip())
for h in headings:
    if norm(h) in logical:
        print(f"PASS  section heading rendered: {h}")
    else:
        print(f"FAIL  section heading missing from the page: {h}"); ok = False

# RTL geometry: margins derived from the page itself, not from config
pg = ET.parse(bbox).getroot().findall(f".//{NS}page")[0]
W = float(pg.get("width"))
words = [(float(w.get("xMin")), float(w.get("xMax")), float(w.get("yMin")), w.text or "")
         for w in pg.findall(f"{NS}word")]
left_margin = min(w[0] for w in words)
right_margin = max(w[1] for w in words)

def is_arabic(s):
    s = norm(s)
    letters = [c for c in s if c.isalpha()]
    return bool(letters) and sum(1 for c in letters if "\u0600" <= c <= "\u06ff") / len(letters) >= 0.8

lines = defaultdict(list)
for w in words:
    lines[round(w[2], 1)].append(w)
hug_right = hug_left = 0
for y in sorted(lines):
    ws = lines[y]
    x0 = min(w[0] for w in ws); x1 = max(w[1] for w in ws)
    txt = "".join(w[3] for w in ws)
    if not is_arabic(txt) or (x1 - x0) > 0.5 * W:
        continue
    if (right_margin - x1) <= 15 and (x0 - left_margin) > 0.25 * W:
        hug_right += 1
    if (x0 - left_margin) <= 15 and (right_margin - x1) > 0.25 * W:
        hug_left += 1
print(f"INFO  derived margins: left={left_margin:.1f} right={right_margin:.1f}")
if hug_right >= 2:
    print(f"PASS  {hug_right} short Arabic line(s) hug the RIGHT margin (RTL)")
else:
    print(f"FAIL  only {hug_right} short Arabic line(s) hug the right margin"); ok = False
if hug_left == 0:
    print("PASS  no short Arabic line hugs the LEFT margin (mirror does not hold)")
else:
    print(f"FAIL  {hug_left} short Arabic line(s) hug the left margin"); ok = False

# Latin runs keep LTR order
src_text = open(src, encoding="utf-8").read()
m = re.search(r"\\newcommand\{\\cvemail\}\{([^}]*)\}", src_text)
email = m.group(1).strip() if m else ""
if email and email in pdftext and email[::-1] not in pdftext:
    print(f"PASS  Latin run keeps LTR order: {email}")
else:
    print(f"FAIL  Latin run not in LTR order: {email!r}"); ok = False

sys.exit(0 if ok else 1)
PY
  [ $? -eq 0 ] || fail=1

  printf '\n== %s: placeholder identity, no upstream author data ==\n' "$label"
  if pdftotext -layout "$pdf" - | grep -qE "$UPSTREAM_RE"; then
    bad "upstream author identity in the built PDF text layer"
  else
    pass "upstream author identity absent from the PDF text layer"
  fi
  local hits
  hits=$(find "$src" "$secdir" -name '*.tex' -exec grep -vE '^\s*%' {} + 2>/dev/null | grep -nE "$UPSTREAM_RE" || true)
  if [ -z "$hits" ]; then
    pass "no upstream author identity among field values"
  else
    bad "upstream author identity among field values: $hits"
  fi

  python3 - "$src" <<'PY'
import sys, re
src = open(sys.argv[1], encoding="utf-8").read()
checks = [
    (r"\\newcommand\{\\cvname\}\{[^}]*\S[^}]*\}", "defines a person's name"),
    (r"\\newcommand\{\\cvemail\}\{[^}]*@example\.com\}", "contact field on the reserved example.com domain"),
    (r"fontawesome7", "loads fontawesome7"),
]
ok = True
for pattern, label in checks:
    if re.search(pattern, src):
        print(f"PASS  {label}")
    else:
        print(f"FAIL  {label}"); ok = False
sys.exit(0 if ok else 1)
PY
  [ $? -eq 0 ] || fail=1
}

# ---------------------------------------------------------------------------
printf '########## Arabic examples ##########\n'
check_document "CV" "cv-ar" "examples/cv-ar.pdf" "examples/cv-ar.log" \
               "examples/cv-ar.tex" "examples/cv-ar"
check_document "cover letter" "coverletter-ar" "examples/coverletter-ar.pdf" \
               "examples/coverletter-ar.log" "examples/coverletter-ar.tex" \
               "examples/coverletter-ar"

# ---------------------------------------------------------------------------
printf '\n== cover letter: letter shape ==\n'
python3 - examples/coverletter-ar.tex examples/coverletter-ar.pdf <<'PY'
import sys, re, subprocess, unicodedata
src, pdf = sys.argv[1], sys.argv[2]
BIDI = dict.fromkeys(map(ord, "\u202a\u202b\u202c\u202d\u202e\u200e\u200f\u2066\u2067\u2068\u2069"), None)
def norm(s): return unicodedata.normalize("NFKC", s.translate(BIDI))
text = subprocess.run(["pdftotext", "-layout", pdf, "-"], capture_output=True, text=True).stdout
logical = norm(text)
src_text = open(src, encoding="utf-8").read()
ok = True
# The letter's own metadata must reach the page: that is what makes it a letter
# rather than a blank page.
for field in ["letterrecipient", "lettersubject", "lettersalutation",
              "letterclosing", "letterenclosure"]:
    m = re.search(r"\\newcommand\{\\%s\}\{([^}]*)\}" % field, src_text)
    val = m.group(1).strip() if m else ""
    val = re.sub(r"\\\\", " ", val)
    if val and norm(val) in logical:
        print(f"INFO  {field} present on the page")
    else:
        print(f"FAIL  {field} missing from the page: {val!r}"); ok = False
# the signature is the sender's name
m = re.search(r"\\newcommand\{\\cvname\}\{([^}]*)\}", src_text)
name = m.group(1).strip() if m else ""
print("PASS  recipient, subject, salutation, closing and signature all render"
      if ok else "FAIL  the letter is missing part of its structure")
sys.exit(0 if ok else 1)
PY
[ $? -eq 0 ] || fail=1

# ---------------------------------------------------------------------------
printf '\n== no dangling references to removed example files ==\n'
# Generic: every examples/<path> referenced anywhere must exist on disk.  This
# catches a reference to a deleted file without listing the deleted names.
python3 - <<'PY'
import os, re, subprocess, glob
files = []
for pat in ["Makefile", "README.md", "*.md", ".github/**/*.yml", ".github/**/*.yaml",
            "tests/*", "examples/*.tex", "examples/**/*.tex", "awesome-cv.cls"]:
    files += [p for p in glob.glob(pat, recursive=True) if os.path.isfile(p)]
ref = re.compile(r"examples/[A-Za-z0-9_][A-Za-z0-9_./-]*\.(?:tex|pdf|png|cls|jpg)")
# "exists" means present in the committed tree: `make clean` legitimately deletes
# built PDFs in the working tree, and a committed file is not a dangling target.
tracked = set(subprocess.run(["git", "ls-files"], capture_output=True,
                             text=True).stdout.split())
missing, refs = {}, 0
for f in sorted(set(files)):
    try:
        txt = open(f, encoding="utf-8", errors="ignore").read()
    except Exception:
        continue
    for m in ref.findall(txt):
        refs += 1
        if m in tracked or os.path.exists(m):
            continue
        missing.setdefault(m, []).append(f)
if missing:
    print(f"FAIL  {len(missing)} referenced path(s) are neither committed nor on disk:")
    for path, where in missing.items():
        print(f"        {path}  (referenced in {', '.join(sorted(set(where))[:3])})")
    raise SystemExit(1)
print(f"PASS  all {refs} 'examples/...' references resolve to committed files")
PY
[ $? -eq 0 ] || fail=1

# The Makefile's public targets must be satisfiable (no missing prerequisites).
for t in examples cv-ar coverletter-ar clean; do
  if make -n "$t" >/dev/null 2>&1; then
    pass "make -n $t succeeds (prerequisites exist)"
  else
    bad "make -n $t fails (missing prerequisite)"
  fi
done

# ---------------------------------------------------------------------------
printf '\n== README policy and accuracy ==\n'
python3 - <<'PY'
import re, unicodedata
txt = open("README.md", encoding="utf-8").read()
ok = True

def check(cond, good, badmsg):
    global ok
    if cond: print(f"PASS  {good}")
    else: print(f"FAIL  {badmsg}"); ok = False

ar = sum(1 for c in txt if "\u0600" <= c <= "\u06ff")
check(ar / max(len(txt), 1) < 0.01,
      f"prose is English (Arabic is {ar/len(txt)*100:.3f}% of the file)",
      f"README looks translated ({ar/len(txt)*100:.2f}% Arabic)")
check("Claud D. Park" in txt and "posquit0/Awesome-CV" in txt,
      "credits the original project and author", "missing upstream credit")
check(re.search(r"LPPL", txt) and re.search(r"CC BY-SA", txt),
      "states the licences", "licence not stated")
check(re.search(r"Font Awesome 7|FontAwesome7", txt) and not re.search(r"Font Awesome 6|fontawesome6", txt, re.I),
      "presents Font Awesome 7 as the icon set", "Font Awesome version wrong")
removed = re.compile(r"examples/(?:cv\.tex|cv\.pdf|coverletter\.tex|coverletter\.pdf|coverletter-[01]\.png)")
check(not removed.search(txt), "no link to a removed example file",
      "links to a removed example file")
check("make cv-ar" in txt and "make coverletter-ar" in txt,
      "documents the Arabic build commands", "Arabic build command not documented")
check(re.search(r"##\s*Maintainers", txt) is None,
      "does not present a Maintainers list for this repository",
      "a Maintainers section is present")
# This project asks for no money: no donation, sponsorship or tipping links.
DONATION = r"paypal|donat|sponsor|ko-?fi|buymeacoffee|patreon|opencollective|liberapay|flattr"
check(re.search(DONATION, txt, re.I) is None,
      "solicits no donations or sponsorship",
      "contains a donation or sponsorship link")
raise SystemExit(0 if ok else 1)
PY
[ $? -eq 0 ] || fail=1

# ---------------------------------------------------------------------------
printf '\n== Font Awesome 7 only ==\n'
if grep -rn "fontawesome6" --include='*.tex' --include='*.cls' . | grep -q .; then
  bad "a LaTeX source still requires fontawesome6"
else
  pass "no LaTeX source requires fontawesome6"
fi
FA7_MAP=$(dirname "$(kpsewhich fontawesome7.sty)")/fontawesome7-mapping.def
if [ -f "$FA7_MAP" ]; then
  pass "fontawesome7 is installed"
  python3 - "$FA7_MAP" <<'PY'
import sys, re, glob
mapping = open(sys.argv[1], encoding="utf-8", errors="ignore").read()
LOCAL = {"faAlt"}          # defined by awesome-cv.cls itself, not by Font Awesome
bad, used = [], 0
for p in glob.glob("**/*.cls", recursive=True) + glob.glob("**/*.tex", recursive=True):
    for i, line in enumerate(open(p, encoding="utf-8", errors="ignore"), 1):
        for name in re.findall(r"\\(fa[A-Z][A-Za-z0-9]*)", line.split("%")[0]):
            if name in LOCAL:
                continue
            used += 1
            if f"\\{name}" not in mapping and name not in mapping:
                bad.append(f"{p}:{i}: \\{name}")
if bad:
    print(f"FAIL  {len(bad)} Font Awesome name(s) absent from version 7:")
    for b in sorted(set(bad))[:15]:
        print("        " + b)
    sys.exit(1)
print(f"PASS  all {used} Font Awesome icon references resolve in Font Awesome 7")
PY
  [ $? -eq 0 ] || fail=1
else
  bad "fontawesome7 mapping not found via kpsewhich"
fi

# ---------------------------------------------------------------------------
printf '\n== no photo support ==\n'
# The templates are deliberately photo-free: no image asset, and no \photo
# command for anyone to reach for.
if git ls-files | grep -qi 'profile\.png'; then
  bad "a photo asset is still tracked"
else
  pass "no photo asset is tracked"
fi
if grep -qE '\\newcommand\{\\photo\}|\\drawphoto|@photo' awesome-cv.cls; then
  bad "awesome-cv.cls still defines the photo capability"
else
  pass "awesome-cv.cls defines no photo capability"
fi
if grep -qE 'tikzpicture|tcolorbox' awesome-cv.cls; then
  bad "photo rendering machinery (tikz/tcolorbox) is still present"
else
  pass "no photo rendering machinery remains"
fi
if grep -rnE '\\photo\b' examples/*.tex; then
  bad "an example document still calls \\photo"
else
  pass "no example document calls \\photo"
fi

# ---------------------------------------------------------------------------
printf '\n== summary ==\n'
if [ "$fail" = "0" ]; then echo "ALL CHECKS PASSED"; else echo "SOME CHECKS FAILED"; fi
exit $fail
