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
</div>

<br />


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


## Requirements

A full TeX distribution is assumed, with **XeLaTeX** and the
**polyglossia** package. [TeX Live](https://tug.org/texlive/) is recommended.

The Arabic examples additionally need:

* **Font Awesome 7** — the CTAN package
  [`fontawesome7`](https://ctan.org/pkg/fontawesome7), which provides the
  [Font Awesome 7](https://fontawesome.com/v7/icons) icon set
* an **Arabic font** — the examples use **Tajawal**, referenced by family name
* a **Latin font** — the examples use **Roboto**, referenced by family name

No font files are bundled with this repository, so the fonts are referenced by
family name and your system has to provide them:

* **Roboto** is packaged on most distributions: `sudo apt install fonts-roboto`.
* **Tajawal** is *not* in the usual distribution repositories. Download it from
  [Google Fonts](https://fonts.google.com/specimen/Tajawal), install the TTFs
  into `~/.local/share/fonts` and run `fc-cache -f`. Alternatively, change the
  family name in the preamble of the two documents to an Arabic font you already
  have — **Amiri** (`fonts-hosny-amiri`) and **Noto Naskh Arabic**
  (`fonts-noto-core`) are both packaged.


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


## No photo

These templates are deliberately **photo-free**: the header carries your name,
title, location and contact details only. There is no `\photo` command and no
image file to supply, which keeps the layout stable and avoids the print-versus-online
photo conventions that differ between countries.


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


## Credit

[**LaTeX**](https://www.latex-project.org) is a fantastic typesetting program that a lot of people use these days, especially the math and computer science people in academia.

[**Awesome CV**](https://github.com/posquit0/Awesome-CV) is the original project this repository is derived from, created by [Claud D. Park](https://github.com/posquit0) with contributions from its community.

[**FontAwesome7 LaTeX Package**](https://ctan.org/pkg/fontawesome7) is a LaTeX package that provides access to the [Font Awesome 7](https://fontawesome.com/v7/icons) icon set.

[**Tajawal**](https://github.com/googlefonts/tajawal) is the Arabic typeface used by the Arabic examples.

[**Roboto**](https://github.com/google/roboto) is the default font on Android and ChromeOS, and the recommended font for Google’s visual language, Material Design.

[**Source Sans Pro**](https://github.com/adobe-fonts/source-sans-pro) is a set of OpenType fonts that have been designed to work well in user interface (UI) environments.


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
* removes photo support: there is no `\photo` command and no image asset;
* uses Font Awesome 7 in place of Font Awesome 6;
* fetches the Arabic font (Tajawal, SIL OFL 1.1) at build time rather than
  bundling any font file.


## Upstream policy

The upstream author asks that his own résumé not be reused:

> You are free to take my `.tex` file and modify it to create your own resume.
> Please don't use my resume for anything else without my permission, though!

This repository respects that request. The upstream author's personal content —
his name, photograph, address, contact details and résumé content — is not part
of the Arabic examples, which describe a fictional placeholder person instead.

The attribution comments naming the original author in the source-file headers
are kept deliberately, as the licence requires the notices to be preserved.


## A note on maintenance

This repository is a derived work and is **not** maintained by the authors or
maintainers of upstream [Awesome CV](https://github.com/posquit0/Awesome-CV).
Please direct questions about *this* repository here; questions about the
original class belong upstream.


## See Also

* [Awesome Identity](https://github.com/posquit0/hugo-awesome-identity) - A single-page Hugo theme to introduce yourself.
