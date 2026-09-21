#!/bin/sh
# سيرتي — install what the documents need, on Linux or macOS.
#
#   ./install.sh          # after cloning, from inside the repository
#   curl -fsSL https://raw.githubusercontent.com/nouaim/sirati/main/install.sh | sh
#
# Written in POSIX sh on purpose: it behaves the same whether you run it with sh,
# bash or zsh.  It installs a TeX distribution with XeLaTeX, polyglossia and the
# metrics hyperref loads, poppler-utils for `make previews`, the Arabic font
# (Tajawal), the Latin font (Roboto) and both icon fonts the documents can draw
# with (Font Awesome 7, which no distribution packages for TeX, and Material
# Icons).  Re-running it is safe: every step checks first, and nothing already in
# place is touched.
set -eu

APT_PACKAGES="texlive-xetex texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended texlive-lang-arabic fonts-roboto fontconfig poppler-utils make git python3 curl unzip"
TAJAWAL_URL="https://raw.githubusercontent.com/google/fonts/main/ofl/tajawal"
FONTAWESOME7_URL="https://mirrors.ctan.org/fonts/fontawesome7.zip"
MATERIALICONS_URL="https://raw.githubusercontent.com/google/material-design-icons/master/font"

step() { printf '\n== %s\n' "$*"; }
info() { printf '   %s\n' "$*"; }
die()  { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

if [ "$(id -u)" -eq 0 ]; then
  as_root() { "$@"; }
elif command -v sudo >/dev/null 2>&1; then
  as_root() { sudo "$@"; }
else
  as_root() { die "need root for $*: re-run as root or install sudo"; }
fi

OS=$(uname -s)

# ---------------------------------------------------------------------------
if [ "$OS" = "Darwin" ]; then
  step "macOS: checking Homebrew"
  command -v brew >/dev/null 2>&1 || die "Homebrew is required: https://brew.sh"
  info "brew found"

  if ! command -v xelatex >/dev/null 2>&1; then
    step "installing MacTeX (about 5 GB, this takes a while)"
    brew install --cask mactex-no-gui
  else
    info "xelatex already present"
  fi
  command -v make >/dev/null 2>&1 || as_root xcode-select --install >/dev/null 2>&1 || true
  FONT_DIR="$HOME/Library/Fonts"
  command -v fc-match >/dev/null 2>&1 || info "no fontconfig: macOS finds fonts in ~/Library/Fonts itself"
elif [ "$OS" = "Linux" ]; then
  step "Linux: checking for apt"
  command -v apt-get >/dev/null 2>&1 || die "this script only covers Debian and Ubuntu. On other distributions, install the same packages by hand: $APT_PACKAGES"
  step "installing build packages (one apt transaction)"
  info "$APT_PACKAGES"
  as_root apt-get update -qq
  # Why each of these, including the ones that are easy to leave out:
  #   texlive-xetex              the XeLaTeX engine the documents are built with
  #   texlive-lang-arabic        bidi, which polyglossia needs for right-to-left
  #   texlive-latex-extra        enumitem
  #   texlive-fonts-recommended  the pzdr metrics hyperref loads under XeLaTeX;
  #                              without it the build stops at
  #                              "Font \XeTeXLink@font=pzdr ... not loadable"
  #   fontconfig                 fc-cache and fc-match, without which the Arabic
  #                              font downloaded below never registers
  #   poppler-utils              pdftoppm, pdfinfo and pdftotext, for
  #                              `make previews` and for the test suite
  #   fonts-roboto               the Latin family the documents reference
  #   make git python3 curl unzip   the build, the suite, and this script
  #
  # The names are passed as arguments rather than through a variable: zsh does not
  # split unquoted expansions, and this script has to behave the same in any shell
  # the reader happens to use.
  as_root apt-get install -y \
    texlive-xetex texlive-latex-recommended texlive-latex-extra \
    texlive-fonts-recommended texlive-lang-arabic \
    fonts-roboto fontconfig poppler-utils \
    make git python3 curl unzip
  FONT_DIR="$HOME/.local/share/fonts"
else
  die "unsupported system: $OS"
fi

refresh_fonts() {
  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f >/dev/null 2>&1
  fi
}

# ---------------------------------------------------------------------------
step "Arabic font: Tajawal"
if command -v fc-match >/dev/null 2>&1 && fc-match Tajawal 2>/dev/null | grep -qi tajawal; then
  info "already registered: $(fc-match Tajawal)"
else
  mkdir -p "$FONT_DIR/tajawal"
  for weight in Regular Bold Medium; do
    if [ -s "$FONT_DIR/tajawal/Tajawal-$weight.ttf" ]; then
      info "already downloaded: Tajawal-$weight.ttf"
    else
      info "downloading Tajawal-$weight.ttf"
      curl -fsSL -o "$FONT_DIR/tajawal/Tajawal-$weight.ttf" "$TAJAWAL_URL/Tajawal-$weight.ttf"
    fi
  done
  refresh_fonts
  if command -v fc-match >/dev/null 2>&1; then
    fc-match Tajawal | grep -qi tajawal || die "Tajawal did not register; check $FONT_DIR/tajawal"
    info "registered: $(fc-match Tajawal)"
  fi
fi

# ---------------------------------------------------------------------------
step "Icon font: Font Awesome 7"
# Debian and Ubuntu package Font Awesome 4 and 5 only, and tlmgr refuses to
# install a 2026 package over their 2025 TeX Live, so it comes from CTAN.
if kpsewhich fontawesome7.sty >/dev/null 2>&1; then
  info "already available: $(kpsewhich fontawesome7.sty)"
else
  info "downloading the CTAN package"
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/fontawesome7.zip" "$FONTAWESOME7_URL"
  unzip -q -o "$tmp/fontawesome7.zip" -d "$tmp/src"
  mkdir -p "$HOME/texmf/tex/latex/fontawesome7"
  cp "$tmp"/src/fontawesome7/tex/* "$HOME/texmf/tex/latex/fontawesome7/"
  for d in opentype type1 tfm enc map; do
    mkdir -p "$HOME/texmf/fonts/$d/fontawesome7"
    cp "$tmp"/src/fontawesome7/"$d"/* "$HOME/texmf/fonts/$d/fontawesome7/"
  done
  rm -rf "$tmp"
  mktexlsr "$HOME/texmf" >/dev/null 2>&1 || true
  kpsewhich fontawesome7.sty >/dev/null 2>&1 || die "fontawesome7 still not found after installing into $HOME/texmf"
  info "installed: $(kpsewhich fontawesome7.sty)"
fi

# ---------------------------------------------------------------------------
step "Icon font: Material Icons"
# The other icon set the documents can draw with: `make icons-cv ICONS=material`
# needs it, and it ships one family per style, of which the documents pick one, so
# all five are installed here and any style can be built afterwards.  Google
# publishes it for the web, so like Tajawal it is fetched rather than packaged.
missing=""
if command -v fc-match >/dev/null 2>&1; then
  for family in "Material Icons" "Material Icons Outlined" "Material Icons Round" "Material Icons Sharp" "Material Icons Two Tone"; do
    fc-match "$family" 2>/dev/null | grep -qi "$family" || missing=1
  done
else
  # No fontconfig: install the files and let the system find them itself.
  missing=1
fi
if [ -z "$missing" ]; then
  info "already registered: Material Icons, in all five styles"
else
  mkdir -p "$FONT_DIR/materialicons"
  for f in MaterialIcons-Regular.ttf MaterialIconsOutlined-Regular.otf \
           MaterialIconsRound-Regular.otf MaterialIconsSharp-Regular.otf \
           MaterialIconsTwoTone-Regular.otf; do
    if [ -s "$FONT_DIR/materialicons/$f" ]; then
      info "already downloaded: $f"
    else
      info "downloading $f"
      curl -fsSL -o "$FONT_DIR/materialicons/$f" "$MATERIALICONS_URL/$f"
    fi
  done
  refresh_fonts
  if command -v fc-match >/dev/null 2>&1; then
    for family in "Material Icons" "Material Icons Outlined" "Material Icons Round" "Material Icons Sharp" "Material Icons Two Tone"; do
      fc-match "$family" | grep -qi "$family" || die "$family did not register; check $FONT_DIR/materialicons"
    done
    info "registered: Material Icons, in all five styles"
  fi
fi

# ---------------------------------------------------------------------------
step "verifying"
missing=""
# The packages the documents load, plus the ones polyglossia pulls in for RTL.
# Listed literally: a variable here would rely on word splitting, which zsh does
# not do.
for f in fontspec polyglossia bidi enumitem setspace geometry hyperref xcolor fontawesome7; do
  kpsewhich "$f.sty" >/dev/null 2>&1 || missing="$missing $f"
done
[ -z "$missing" ] || die "these LaTeX packages are still missing:$missing"
command -v xelatex >/dev/null 2>&1 || die "xelatex is missing"
command -v pdftoppm >/dev/null 2>&1 || info "note: pdftoppm is absent, so 'make previews' and the test suite cannot run"
info "xelatex:       $(command -v xelatex)"
info "LaTeX packages: all present"
if command -v fc-match >/dev/null 2>&1; then
  info "Arabic font:   $(fc-match Tajawal)"
  info "Latin font:    $(fc-match Roboto)"
  info "Icons font:    $(fc-match "Material Icons") and its four other styles"
fi

printf '\nDone. Now build the documents:\n\n    make\n\n'
