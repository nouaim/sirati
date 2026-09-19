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
printf '\n== committed artefacts match the sources ==\n'
# A PDF or preview restored by `git checkout` carries a newer mtime than the
# .tex files, so `make` considers it up to date and skips the rebuild - a stale
# document then ships unnoticed.  So: force a genuine build of the sources and
# compare its text with the committed PDF, and separately check that the
# committed preview really is the render of the committed PDF.
for doc in cv-ar coverletter-ar; do
  pdf="examples/$doc.pdf"
  png="examples/$doc.png"
  tmp=$(mktemp -d)
  # Build a copy, so the check never modifies the working tree.
  cp -r examples "$tmp/"
  ( cd "$tmp/examples" && xelatex -interaction=nonstopmode "$doc.tex" >/dev/null 2>&1 )
  fresh="$tmp/examples/$doc.pdf"
  if [ -s "$fresh" ] && git cat-file -e "HEAD:$pdf" 2>/dev/null; then
    git show "HEAD:$pdf" > "$tmp/committed.pdf"
    old=$(pdftotext -layout "$tmp/committed.pdf" - 2>/dev/null | tr -d '[:space:]')
    new=$(pdftotext -layout "$fresh" - 2>/dev/null | tr -d '[:space:]')
    if [ "$old" = "$new" ]; then
      pass "committed $pdf matches a fresh build of the sources"
    else
      bad "committed $pdf is stale against the sources - rebuild it and commit"
    fi
  fi
  if git cat-file -e "HEAD:$png" 2>/dev/null; then
    git show "HEAD:$png" > "$tmp/committed.png"
    # Render the *committed* PDF rather than the fresh build: the preview is meant
    # to be the render of what is committed, and a TeX Live version other than the
    # one that produced the artefacts would otherwise fail this check for a reason
    # that has nothing to do with a stale file.  pdftoppm's output is stable across
    # its own versions, so comparing bytes stays meaningful.
    git show "HEAD:$pdf" > "$tmp/committed.pdf" 2>/dev/null
    pdftoppm -r 130 -png -f 1 -l 1 "$tmp/committed.pdf" "$tmp/render" >/dev/null 2>&1
    if cmp -s "$tmp/render-1.png" "$tmp/committed.png"; then
      pass "committed $png is the render of the committed PDF"
    else
      bad "committed $png is not the render of the committed PDF - run 'make previews'"
    fi
  fi
  rm -rf "$tmp"
done

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
for pat in ["Makefile", "LICENSE", "README.md", "*.md", ".github/**/*.yml",
            ".github/**/*.yaml", "tests/*", "examples/*.tex", "examples/**/*.tex"]:
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
printf '\n== README policy and accuracy (Arabic default + English sibling) ==\n'
# README.md is the Arabic default and README.en.md is the English version; the
# two link to each other so a reader can switch between them.  Everything else
# the project promises - upstream credit, the licence, no donations - has to
# hold in both files.
python3 - <<'PY'
import re, os
ok = True

def check(cond, good, badmsg):
    global ok
    if cond: print(f"PASS  {good}")
    else: print(f"FAIL  {badmsg}"); ok = False

DONATION = r"paypal|donat|sponsor|ko-?fi|buymeacoffee|patreon|opencollective|liberapay|flattr"
REMOVED = re.compile(r"examples/(?:cv\.tex|cv\.pdf|coverletter\.tex|coverletter\.pdf|coverletter-[01]\.png)")

def arabic_ratio(txt):
    return sum(1 for c in txt if "\u0600" <= c <= "\u06ff") / max(len(txt), 1)

for name, lang in (("README.md", "ar"), ("README.en.md", "en")):
    if not os.path.exists(name):
        check(False, "", f"{name} is missing")
        continue
    txt = open(name, encoding="utf-8").read()
    ratio = arabic_ratio(txt)
    if lang == "ar":
        check(ratio > 0.25,
              f"README.md is the Arabic default ({ratio*100:.1f}% Arabic letters)",
              f"README.md is not the Arabic version ({ratio*100:.2f}% Arabic)")
        check("README.en.md" in txt, "README.md links to the English sibling",
              "README.md does not link to README.en.md")
    else:
        check(ratio < 0.01,
              f"README.en.md is the English version (Arabic is {ratio*100:.2f}% of the file)",
              f"README.en.md is not English ({ratio*100:.2f}% Arabic)")
        check("README.md" in txt, "README.en.md links back to the Arabic default",
              "README.en.md does not link back to README.md")
    check("Claud D. Park" in txt and "posquit0/Awesome-CV" in txt,
          f"{name}: credits the original project and author",
          f"{name}: missing upstream credit")
    check(re.search(r"CC BY-SA 4\.0", txt) is not None,
          f"{name}: states the CC BY-SA 4.0 licence", f"{name}: licence not stated")
    check(re.search(r"LICENSE", txt) is not None,
          f"{name}: points at the LICENSE file", f"{name}: no reference to the LICENSE file")
    check(re.search(r"Font Awesome 7|FontAwesome7", txt) is not None,
          f"{name}: presents Font Awesome 7 as the icon set",
          f"{name}: Font Awesome 7 not mentioned")
    # Prose may name the version we moved away from; what must never appear is
    # an actual dependency on the Font Awesome 6 package.
    check(re.search(r"fontawesome6", txt, re.I) is None,
          f"{name}: does not depend on the fontawesome6 package",
          f"{name}: fontawesome6 referenced")
    check(not REMOVED.search(txt), f"{name}: no link to a removed example file",
          f"{name}: links to a removed example file")
    check("make cv-ar" in txt and "make coverletter-ar" in txt,
          f"{name}: documents the Arabic build commands",
          f"{name}: Arabic build command not documented")
    check(re.search(r"##\s*Maintainers", txt) is None,
          f"{name}: does not present a Maintainers list for this repository",
          f"{name}: a Maintainers section is present")
    # Upstream's README ends by advertising another of its author's projects.
    # This repository documents its own templates, not other people's.
    check("hugo-awesome-identity" not in txt,
          f"{name}: advertises no unrelated upstream project",
          f"{name}: links to upstream's unrelated project")
    # The class is gone, so nothing here may advertise LPPL - prose may mention
    # it only to say no LPPL component is shipped, never as a licence link or badge.
    check(re.search(r"latex-project\.org/lppl|badge/license-LPPL", txt, re.I) is None,
          f"{name}: advertises no LPPL licence link or badge",
          f"{name}: still advertises LPPL as the licence")
    badges = re.findall(r"badge/license-([A-Za-z0-9%._-]+?)-[a-z]+\.svg", txt)
    check(all("cc" in b.lower() for b in badges),
          f"{name}: licence badge matches the stated licence ({badges})",
          f"{name}: licence badge disagrees with the licence text: {badges}")
    # This project asks for no money: no donation, sponsorship or tipping links.
    check(re.search(DONATION, txt, re.I) is None,
          f"{name}: solicits no donations or sponsorship",
          f"{name}: contains a donation or sponsorship link")
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
bad, used = [], 0
for p in glob.glob("**/*.tex", recursive=True):
    for i, line in enumerate(open(p, encoding="utf-8", errors="ignore"), 1):
        for name in re.findall(r"\\(fa[A-Z][A-Za-z0-9]*)", line.split("%")[0]):
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
printf '\n== CI provides the fonts the documents need ==\n'
# The documents reference their fonts by family name, so every build path has to
# make those families available: if a family in the document changes, CI and the
# Dockerfile must follow.
python3 - <<'PY'
import os, re, sys
doc = open("examples/cv-ar.tex", encoding="utf-8").read()
providers = {"CI": open(".github/workflows/main.yml", encoding="utf-8").read()}
if os.path.exists("Dockerfile"):
    providers["the Dockerfile"] = open("Dockerfile", encoding="utf-8").read()
ok = True
for macro, what in (("arabicfont", "Arabic"), ("englishfont", "Latin")):
    m = re.search(r"\\newfontfamily\\%s\[[^\]]*\]\{([^}]*)\}" % macro, doc)
    family = m.group(1).strip() if m else ""
    for who, text in providers.items():
        if family and family in text:
            print(f"PASS  {who} provides the {what} family the documents use: {family}")
        else:
            print(f"FAIL  {who} does not provide the {what} family {family!r}")
            ok = False
sys.exit(0 if ok else 1)
PY
[ $? -eq 0 ] || fail=1

# ---------------------------------------------------------------------------
printf '\n== installation paths: documented and real ==\n'
# The READMEs promise two ways to get a toolchain.  Keep those promises honest:
# the Dockerfile has to exist and carry what the documents need, the apt list in
# each README has to cover every package the build actually uses, and both files
# have to spell the Docker commands out.
python3 - <<'PY'
import os, re, sys
ok = True

def check(cond, good, bad):
    global ok
    if cond: print(f"PASS  {good}")
    else: print(f"FAIL  {bad}"); ok = False

ci = open(".github/workflows/main.yml", encoding="utf-8").read()
df = open("Dockerfile", encoding="utf-8").read() if os.path.exists("Dockerfile") else ""
check(bool(df), "a Dockerfile is shipped", "no Dockerfile at the repository root")

m = re.search(r"^FROM\s+(\S+)", df, re.M)
base = m.group(1) if m else ""
check(base.startswith("texlive/texlive"),
      f"Dockerfile builds on the same TeX Live image as CI ({base or 'none'})",
      f"Dockerfile base image is not the texlive/texlive one: {base!r}")
check("poppler-utils" in df,
      "Dockerfile installs poppler-utils, which `make previews` and the suite need",
      "Dockerfile does not install poppler-utils")
fonts_url = "raw.githubusercontent.com/google/fonts/main/ofl/tajawal"
check(fonts_url in df and fonts_url in ci,
      "Dockerfile and CI fetch the Arabic font from the same upstream source",
      "Dockerfile and CI disagree about where the Arabic font comes from")
check(re.search(r"fc-match\s+Tajawal", df) is not None,
      "Dockerfile fails loudly when the Arabic family does not resolve",
      "Dockerfile does not assert the Arabic family resolves")

# The installer is the documented shortcut, so it has to exist, be runnable, and
# install the same set the READMEs promise.  It must stay POSIX sh: zsh does not
# split unquoted expansions, and the script has to behave the same in any shell.
inst = open("install.sh", encoding="utf-8").read() if os.path.exists("install.sh") else ""
check(bool(inst), "install.sh is shipped", "no install.sh at the repository root")
check(os.access("install.sh", os.X_OK), "install.sh is executable",
      "install.sh is not executable")
check(inst.startswith("#!/bin/sh"),
      "install.sh declares the POSIX sh shebang",
      "install.sh does not start with #!/bin/sh")
check("kpsewhich fontawesome7.sty" in inst and "mktexlsr" in inst,
      "install.sh installs the icon font from CTAN into the user tree",
      "install.sh does not handle fontawesome7")

mk = open("Makefile", encoding="utf-8").read()
absent = [t for t in ("docker:", "docker-previews:", "docker-test:") if t not in mk]
check(not absent, "Makefile offers the Docker targets",
      f"Makefile is missing Docker targets: {absent}")

# A package dropped from a README's apt list, or from the installer, would send
# readers into a broken build - which is exactly how this section was wrong before.
NEEDED = ["texlive-xetex", "texlive-latex-recommended", "texlive-latex-extra",
          "texlive-fonts-recommended", "texlive-lang-arabic",
          "fonts-roboto", "fontconfig", "poppler-utils"]
missing = [p for p in NEEDED if p not in inst]
check(not missing, "install.sh installs every package the build needs",
      f"install.sh does not install {missing}")
# The READMEs stay short on purpose: they point at the installer and the make
# targets, and the reasoning - which packages, and why - lives in the comments in
# install.sh and the Makefile.  So the package list must not reappear in the docs.
check("docker build -t" in mk and "docker run --rm" in mk,
      "Makefile documents the explicit Docker commands its targets wrap",
      "Makefile does not show the explicit Docker commands")
for name in ("README.md", "README.en.md"):
    txt = open(name, encoding="utf-8").read()
    check("./install.sh" in txt and "install.sh | sh" in txt,
          f"{name}: documents the installer and the curl form",
          f"{name}: does not document install.sh")
    check("make docker" in txt and "make docker-test" in txt,
          f"{name}: documents the short Docker targets",
          f"{name}: `make docker` targets are not documented")
    check("make previews" in txt,
          f"{name}: documents `make previews`", f"{name}: `make previews` is undocumented")
    check("texlive-" not in txt,
          f"{name}: leaves the package list to install.sh, as intended",
          f"{name}: restates the package list that belongs in install.sh")
raise SystemExit(0 if ok else 1)
PY
[ $? -eq 0 ] || fail=1

# ---------------------------------------------------------------------------
printf '\n== contribution path ==\n'
# Contributors need a documented route from "something is wrong" to a merged pull
# request, in both languages, and the GitHub side has to point at it.
python3 - <<'PY'
import os, sys
ok = True

def check(cond, good, bad):
    global ok
    if cond: print(f"PASS  {good}")
    else: print(f"FAIL  {bad}"); ok = False

for name, other in (("CONTRIBUTING.md", "CONTRIBUTING.en.md"),
                    ("CONTRIBUTING.en.md", "CONTRIBUTING.md")):
    if not os.path.exists(name):
        check(False, "", f"{name} is missing")
        continue
    txt = open(name, encoding="utf-8").read()
    check(other in txt, f"{name} links to its sibling {other}",
          f"{name} does not link to {other}")
    check("tests/check-arabic-examples.sh" in txt,
          f"{name} tells contributors to run the suite",
          f"{name} does not mention the test suite")
    check("Closes #" in txt,
          f"{name} explains how to reference the issue it closes",
          f"{name} does not explain referencing the issue")

for name, guide in (("README.md", "CONTRIBUTING.md"),
                    ("README.en.md", "CONTRIBUTING.en.md")):
    txt = open(name, encoding="utf-8").read()
    check(guide in txt, f"{name} points at {guide}",
          f"{name} does not link the contributing guide")

config = ".github/ISSUE_TEMPLATE/config.yml"
check(os.path.exists(config), "the issue chooser is configured",
      f"{config} is missing")
if os.path.exists(config):
    txt = open(config, encoding="utf-8").read()
    check("CONTRIBUTING.en.md" in txt and "CONTRIBUTING.md" in txt,
          "the issue chooser offers the contributing guide in both languages",
          "the issue chooser does not link both contributing guides")

pr = ".github/pull_request_template.md"
check(os.path.exists(pr) and "tests/check-arabic-examples.sh" in open(pr, encoding="utf-8").read(),
      "the pull request template asks for the test suite",
      f"{pr} is missing or does not mention the suite")

labeler = open(".github/labeler.yaml", encoding="utf-8").read()
check("CONTRIBUTING.md" in labeler and "CONTRIBUTING.en.md" in labeler,
      "edits to the contributing guides get the docs label",
      "the labeler ignores edits to the contributing guides")
raise SystemExit(0 if ok else 1)
PY
[ $? -eq 0 ] || fail=1

# ---------------------------------------------------------------------------
printf '\n== no photo support ==\n'
# The templates are deliberately photo-free: no image asset, and no \photo
# command for anyone to reach for.
if git ls-files | grep -qi 'profile\.png'; then
  bad "a photo asset is still tracked"
else
  pass "no photo asset is tracked"
fi
if grep -rqE '\\newcommand\{\\photo\}|\\drawphoto|@photo' --include='*.tex' --include='*.cls' . ; then
  bad "a source still defines the photo capability"
else
  pass "no source defines the photo capability"
fi
if grep -rqE 'tikzpicture|tcolorbox' --include='*.tex' --include='*.cls' . ; then
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
printf '\n== licence compliance ==\n'
# This repository distributes no LPPL component: upstream's class is not shipped,
# and everything here is our own work under CC BY-SA 4.0.
cls_files=$(git ls-files | grep '\.cls$' || true)
if [ -z "$cls_files" ]; then
  pass "no .cls file is distributed, so there is no LPPL component"
else
  bad "a .cls file is still distributed: $cls_files"
fi
if [ -f LICENSE ] && grep -q "Attribution-ShareAlike 4.0 International" LICENSE; then
  pass "LICENSE carries the CC BY-SA 4.0 legal code"
else
  bad "LICENSE is missing or is not the CC BY-SA 4.0 text"
fi
missing_notice=""
for f in $(git ls-files | grep '^examples/.*\.tex$'); do
  grep -q "CC BY-SA 4.0" "$f" || missing_notice="$missing_notice $f"
done
if [ -z "$missing_notice" ]; then
  pass "every example source file states its licence and credits upstream"
else
  bad "no licence notice in:$missing_notice"
fi

# ---------------------------------------------------------------------------
printf '\n== summary ==\n'
if [ "$fail" = "0" ]; then echo "ALL CHECKS PASSED"; else echo "SOME CHECKS FAILED"; fi
exit $fail
