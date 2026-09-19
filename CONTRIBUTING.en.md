# Contributing to سيرتي

Thanks for looking. This is a small project, and contributions are welcome: a bug
report, a fix, a documentation improvement, a better right-to-left layout.

**Language:** write in English or Arabic, whichever is easier for you.

[العربية](CONTRIBUTING.md)


## Before you write anything

1. Search the open and closed issues; someone may have raised it already.
2. If not, open one issue describing the problem or the proposal. Say which system
   you are on (distribution, or macOS/Windows), what `xelatex --version` prints, the
   exact command you ran, and what came out. For anything large, wait for a reply
   before starting — that saves your time.
3. One issue, one change. Do not mix a fix with a reformat.


## The steps

```bash
# 1. Fork the repository with the Fork button, then
git clone https://github.com/<you>/sirati && cd sirati
git remote add upstream https://github.com/nouaim/sirati

# 2. Branch off main
git checkout -b fix/paper-tint-contrast

# 3. Set up the toolchain (either one)
./install.sh          # Linux (the macOS branch is untested)
make docker           # anywhere with Docker

# 4. Make your change, then run the tests - they must all pass
tests/check-arabic-examples.sh

# 5. Update the documentation (below), then
git commit -m "..."
git push origin fix/paper-tint-contrast
```

Then open a pull request against `main`. In the description say what changed and
why, what you actually verified (the commands and their output), and reference the
issue with `Closes #<number>`.


## Project rules

* **Arabic first.** `README.md` is the Arabic document and `README.en.md` is its
  English sibling, so a change to one needs the matching change in the other. Do not
  mix two languages inside one file.
* **The documentation is tested.** Every command in the docs has been run. If you add
  one, run it in a clean container (`docker run --rm -it ubuntu:latest`) before you
  write it down.
* **No photos.** The templates do not support them; do not add an image asset.
* **No publisher names**, in any file, and not in commit messages either.
* The sheet is white by default, and the chamois tint stays commented out.
* Do not bundle font files, and do not use `tikz` or `tcolorbox` — the tests forbid
  both.
* The licence is CC BY-SA 4.0: by contributing you agree to publish your work under
  it, with the attribution notices to upstream left in place.


## What the tests check

`tests/check-arabic-examples.sh` builds both documents with XeLaTeX and verifies that
each is one page, with no errors, no missing glyphs and no bidi warnings; that the
committed PDFs and previews match the sources; that the documentation follows the
project policies (licence and credit); and that the documented installation
paths really work. Run it before every pull request.


## Licence

By contributing you agree that your contribution is published under
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/), and that the
attribution notices to [Awesome CV](https://github.com/posquit0/Awesome-CV) stay in
place.
