#!/bin/sh
# Regenerate the colour previews in examples/colours/ from the sources.
#
#   ./scripts/make-colours.sh      # or: make colours
#
# For each accent it copies examples/ into a temporary directory, changes the one
# line that defines the accent in examples/colours.tex, builds the CV and renders
# the first page.  Nothing in the repository is touched except examples/colours/.
# Add or remove an accent in the list at the bottom.
#
# Written in POSIX sh: the list is read line by line rather than split from a
# variable, so the script behaves the same under sh, bash and zsh.
set -eu

[ -f examples/cv-ar.tex ] || { echo "run this from the repository root" >&2; exit 1; }
command -v xelatex  >/dev/null 2>&1 || { echo "xelatex is missing; see the README" >&2; exit 1; }
command -v pdftoppm >/dev/null 2>&1 || { echo "pdftoppm is missing; install poppler-utils" >&2; exit 1; }

BASE_ACCENT="0395DE"          # the accent as it stands in examples/colours.tex
OUT="examples/colours"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM
mkdir -p "$OUT"

while read -r name hex; do
  [ -n "${name:-}" ] || continue
  build="$work/$name"
  rm -rf "$build"
  cp -r examples "$build"
  sed -i "s/\\\\definecolor{awesome}{HTML}{$BASE_ACCENT}/\\\\definecolor{awesome}{HTML}{$hex}/" "$build/colours.tex"
  grep -q "definecolor{awesome}{HTML}{$hex}" "$build/colours.tex" || {
    echo "could not set the accent for $name (base accent still $BASE_ACCENT?)" >&2; exit 1; }

  (cd "$build" && xelatex -interaction=nonstopmode cv-ar.tex > /dev/null 2>&1) || true
  # `grep -c` prints 0 and exits 1 when nothing matches, so swallow its status
  # rather than appending a second 0 to the count.
  errors=$(grep -c '^!' "$build/cv-ar.log" 2>/dev/null || true)
  if [ "${errors:-0}" != "0" ]; then
    echo "$name: the build reported $errors error(s); see $build/cv-ar.log" >&2
    exit 1
  fi

  # 200 dpi, matching `make previews`: the README shows a preview up to 820px
  # wide, so the file has to carry 1640px to stay sharp on a 2x display.
  pdftoppm -r 200 -png -f 1 -l 1 "$build/cv-ar.pdf" "$build/preview"
  cp "$build/cv-ar.pdf" "$OUT/cv-$name.pdf"
  cp "$build/preview-1.png" "$OUT/cv-$name.png"
  printf '  %-9s #%s  %s page, no errors\n' "$name" "$hex" \
    "$(pdfinfo "$build/cv-ar.pdf" | awk '/^Pages/{print $2}')"
done <<'EOF'
emerald 1B7F5A
navy 283593
violet 6A4C93
rose B03060
burgundy 8C2F39
bronze 9A6B2F
graphite 37474F
teal 0F6E6E
EOF

printf 'wrote %s/cv-*.{pdf,png}\n' "$OUT"
