<h1 align="center">
  <a href="https://github.com/nouaim/sirati" title="سيرتي">
    <img alt="سيرتي" src="icon.png" width="200px" height="200px" />
  </a>
  <br />
  سيرتي
</h1>

<p align="center">
  An Arabic-first, right-to-left CV and cover-letter template for LaTeX
</p>

<div align="center">
  <a href="https://github.com/posquit0/Awesome-CV">
    <img alt="Upstream" src="https://img.shields.io/badge/upstream-Awesome--CV-blue.svg" />
  </a>
  <a href="https://creativecommons.org/licenses/by-sa/4.0/">
    <img alt="License: CC BY-SA 4.0" src="https://img.shields.io/badge/license-CC%20BY--SA%204.0-blue.svg" />
  </a>
  <a href="https://github.com/nouaim/sirati/actions/workflows/main.yml">
    <img alt="Compile PDFs" src="https://github.com/nouaim/sirati/actions/workflows/main.yml/badge.svg" />
  </a>
  <a href="https://raw.githubusercontent.com/nouaim/sirati/main/examples/cv-ar.pdf">
    <img alt="Download the CV" src="https://img.shields.io/badge/CV-PDF-blue.svg" />
  </a>
  <a href="https://raw.githubusercontent.com/nouaim/sirati/main/examples/coverletter-ar.pdf">
    <img alt="Download the cover letter" src="https://img.shields.io/badge/Cover%20Letter-PDF-blue.svg" />
  </a>
</div>

<br />

<p align="center">
  <a href="README.md">العربية</a> · <strong>English</strong>
</p>


## What is this?

**سيرتي** is an Arabic-first take on
[Awesome CV](https://github.com/posquit0/Awesome-CV), the LaTeX template by
[Claud D. Park](https://github.com/posquit0).

The Arabic examples are **self-contained XeLaTeX documents** written for
right-to-left typesetting with [polyglossia](https://ctan.org/pkg/polyglossia).
This repository does not carry upstream's class file: its layout is built around
left-to-right tables, and the RTL layout here comes from the language setting
instead. The documents therefore compile on their own, with no class to install.

If you want the original English template and its class, use
[upstream Awesome CV](https://github.com/posquit0/Awesome-CV) — it remains the
authoritative source, and this repository is derived from it.


## Preview

* [Arabic CV (PDF)](examples/cv-ar.pdf)
* [Arabic cover letter (PDF)](examples/coverletter-ar.pdf)

| Arabic CV | Arabic cover letter |
|:---:|:---:|
| [![Arabic CV](examples/cv-ar.png)](examples/cv-ar.pdf) | [![Arabic cover letter](examples/coverletter-ar.png)](examples/coverletter-ar.pdf) |

Both documents are one page. The previews are rendered from the built PDFs and
regenerated with `make previews`.


## Requirements

Two ways to get a working toolchain: install the pieces on your system, or use the
Docker image this repository ships. Both are exercised by the test suite, and the
Docker path works on any operating system.

No font files are bundled: the documents reference their families by name, so the
system has to provide them.

### 1. Install on your system (Linux and macOS)

The repository ships an installer that does everything in this section for you:

```bash
./install.sh
```

Or, before cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/nouaim/sirati/main/install.sh | sh
```

It is **POSIX sh**, so it behaves the same whether you run it with `sh`, `bash` or
`zsh`, and re-running it is safe — every step checks before it changes anything.
On macOS it uses Homebrew and MacTeX; on Debian and Ubuntu it uses `apt`. The
macOS branch has not been run on a real Mac yet — if it fails for you, the manual
steps below work there too. Read it before piping it into a shell: the installer
is short and does nothing beyond the manual steps below.

```bash
sudo apt install -y texlive-xetex texlive-latex-recommended texlive-latex-extra \
    texlive-fonts-recommended texlive-lang-arabic \
    fonts-roboto fontconfig poppler-utils make git python3 curl unzip
```

Each piece earns its place. `texlive-xetex` brings the **XeLaTeX** engine;
`texlive-lang-arabic` brings `bidi`, which **polyglossia** needs for
right-to-left text; `texlive-latex-extra` brings `enumitem`;
`texlive-fonts-recommended` brings the `pzdr` metrics that `hyperref` loads under
XeLaTeX — without it the build stops at `Font \XeTeXLink@font=pzdr ... not
loadable`; `poppler-utils` brings `pdftoppm`, `pdfinfo` and `pdftotext`, which
`make previews` and the test suite need; and `fontconfig` brings `fc-cache` and
`fc-match`.

Two things no distribution packages, so add them by hand.

**The Arabic font (Tajawal).**

```bash
mkdir -p ~/.local/share/fonts/tajawal && cd ~/.local/share/fonts/tajawal
for f in Regular Bold Medium; do
  curl -fsSLO "https://raw.githubusercontent.com/google/fonts/main/ofl/tajawal/Tajawal-$f.ttf"
done
fc-cache -f
fc-match Tajawal     # must name Tajawal: a fallback name means it did not register
```

**The icon font (Font Awesome 7).** Debian and Ubuntu package Font Awesome 4 and 5
but not 7, so take it from CTAN into your own TeX tree:

```bash
curl -fsSL -o /tmp/fontawesome7.zip https://mirrors.ctan.org/fonts/fontawesome7.zip
unzip -q -o /tmp/fontawesome7.zip -d /tmp/fontawesome7
cd /tmp/fontawesome7/fontawesome7
mkdir -p ~/texmf/tex/latex/fontawesome7
cp tex/* ~/texmf/tex/latex/fontawesome7/
for d in opentype type1 tfm enc map; do
  mkdir -p ~/texmf/fonts/$d/fontawesome7 && cp $d/* ~/texmf/fonts/$d/fontawesome7/
done
mktexlsr ~/texmf
kpsewhich fontawesome7.sty    # must print the path under ~/texmf
```

If you would rather keep everything under TeX Live's own package manager, install
[TeX Live from upstream](https://tug.org/texlive/) and run
`tlmgr install fontawesome7` instead of that CTAN block.

Any Arabic font works in place of Tajawal — **Amiri** (`fonts-hosny-amiri`) and
**Noto Naskh Arabic** (`fonts-noto-core`) are both packaged; change the family
names in the preamble of the two documents.

### 2. Install with Docker (any operating system)

The repository carries a `Dockerfile` based on the official `texlive/texlive`
image with `poppler-utils` and the Arabic font added, so nothing is installed on
your system. Three targets cover everything:

```bash
make docker            # build the image, then compile both documents inside it
make docker-previews   # regenerate the preview images
make docker-test       # run the test suite
```

They are thin wrappers around these two commands, if you would rather see them:

```bash
docker build -t sirati .
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/doc -w /doc sirati make
```

Swap `make` for `make cv-ar`, `make coverletter-ar` or
`tests/check-arabic-examples.sh` to run something else inside the image.
`--user "$(id -u):$(id -g)"` matters: without it the generated PDFs belong to root.

Upstream's shorter recipe — `docker run … texlive/texlive:latest make` — is *not*
enough here. That image has every LaTeX package these documents use, but neither
Tajawal nor `poppler-utils`, so `make` fails on the Arabic font and `make previews`
cannot run at all. The image is large (its TeX Live base is about 9 GB) and is
pulled once.


## Usage

Build the Arabic CV:

```bash
make cv-ar
```

Build the Arabic cover letter:

```bash
make coverletter-ar
```

In either case this produces `examples/cv-ar.pdf` or
`examples/coverletter-ar.pdf`. You can also compile directly:

```bash
cd examples && xelatex cv-ar.tex
```

`make` on its own builds both documents.


## Customising

Both Arabic documents keep the person's details in one clearly marked block near
the top of the file, and the cover letter keeps its prose in a separate file
(`examples/coverletter-ar/body.tex`) so the wording can be changed without
touching the layout:

* `examples/cv-ar.tex` — CV layout and details
* `examples/cv-ar/*.tex` — CV sections
* `examples/coverletter-ar.tex` — letter layout and details
* `examples/coverletter-ar/body.tex` — letter prose

The examples currently describe a **fictional person** using the reserved domain
`example.com`. Replace those values with your own.


### Paper

The sheet is **white by default**, and nothing has to be done to keep it that
way. An optional tint is shipped with the documents: **ورق شامواه** (chamois),
the cream book paper that Arabic books are commonly printed on.

To switch the tint on, uncomment two lines in the preamble of each document —
the `\pagecolor` line, and the warm section rule just above it:

```latex
\definecolor{sectiondivider}{HTML}{B9A87F}   % warm rule: a grey rule vanishes on the tint
\pagecolor{shamwa}                           % the chamois tint itself
```

`\pagecolor` belongs to `xcolor`, which both documents already load, so no extra
package is needed; XeLaTeX draws the tint through the `background` special of the
xdvipdfmx graphics driver. The value of `shamwa` (`#F7F0DC`) is a definecolor, so
the tone can be changed to taste. Because the tint covers the whole sheet edge to
edge, a printer has to be set to print background colours for it to come out on
paper.


## Credit

[**LaTeX**](https://www.latex-project.org) is a fantastic typesetting program that a lot of people use these days, especially the math and computer science people in academia.

[**Awesome CV**](https://github.com/posquit0/Awesome-CV) is the original project this repository is derived from, created by [Claud D. Park](https://github.com/posquit0) with contributions from its community.

[**FontAwesome7 LaTeX Package**](https://ctan.org/pkg/fontawesome7) is a LaTeX package that provides access to the [Font Awesome 7](https://fontawesome.com/v7/icons) icon set.

[**Tajawal**](https://github.com/googlefonts/tajawal) is the Arabic typeface used by the Arabic examples.

[**Roboto**](https://github.com/google/roboto) is the default font on Android and ChromeOS, and the recommended font for Google’s visual language, Material Design.

[**Source Sans Pro**](https://github.com/adobe-fonts/source-sans-pro) is a set of OpenType fonts that have been designed to work well in user interface (UI) environments.


## Contributing

Contributions are welcome, and what we need most right now is somebody running the
installer on macOS or Windows. The whole flow — from opening an issue to a pull
request — is in the [contributing guide](CONTRIBUTING.en.md).


## Licence

Everything in this repository — the Arabic CV and cover letter, their section
files, and the build files — is published under the
[Creative Commons Attribution-ShareAlike 4.0 International licence](https://creativecommons.org/licenses/by-sa/4.0/)
(CC BY-SA 4.0). The full legal code is in [LICENSE](LICENSE).

No file under the LaTeX Project Public License is distributed here. Upstream's
`awesome-cv.cls` is deliberately **not** included: its layout is built around
left-to-right tables, the Arabic documents do not use it, and leaving the class
out means there is no LPPL component to comply with. Fetch it from
[upstream](https://github.com/posquit0/Awesome-CV) if you want it.


## Changes from upstream

Relative to [Awesome CV](https://github.com/posquit0/Awesome-CV), this
repository:

* rewrites the CV and the cover letter as standalone right-to-left XeLaTeX
  documents using [polyglossia](https://ctan.org/pkg/polyglossia), instead of
  building on the class and its left-to-right layout;
* drops the class file `awesome-cv.cls` altogether;
* replaces the English example documents with the Arabic pair, so the repository
  ships one CV and one cover letter rather than several examples;
* uses Font Awesome 7 in place of Font Awesome 6;
* keeps the sheet white but ships an optional ورق شامواه (chamois) paper tint,
  two commented lines away in each document;
* fetches the Arabic font (Tajawal, SIL OFL 1.1) at build time rather than
  bundling any font file.


## Upstream policy

The upstream author asks that his own résumé not be reused:

> You are free to take my `.tex` file and modify it to create your own resume.
> Please don't use my resume for anything else without my permission, though!

This repository respects that request. The upstream author's personal content —
his name, address, contact details and résumé content — is not part
of the Arabic examples, which describe a fictional placeholder person instead.

The attribution comments naming the original author in the source-file headers
are kept deliberately, as the licence requires the notices to be preserved.
